extern highp vec3 vcloud;
extern highp number fx_mask;
extern highp number time;
extern highp vec4 _tex_details;
extern highp vec2 image_details;
extern bool shadow;
extern highp vec4 c1;
extern highp vec4 c2;

extern highp vec2 mouse_screen_pos;
extern highp float hovering;
extern highp float hover_tilt;
extern highp float screen_scale;
extern highp float position_shader_mode;

number GameID = vcloud.z;

#pragma HM_INCLUDE "_0_lib/_1_masks/_0_dir_sweep.inc"

const int VMAX_STEPS = 20;
const int VMAX_STEPS_LIGHTS = 6;
const float VPI = 3.14159265359;
const float ABSORPTION_COEFFICIENT = 0.25;
const float SCATTERING_ANISO = 0.2;
const float OG_MARCH_SIZE = 0.7;

mat3 vol_m = mat3(
	0.00, 0.80, 0.60,
	-0.80, 0.36, -0.48,
	-0.60, -0.48, 0.64
);

vec3 rotateAlongAxis(vec3 v, vec3 axis, float angle)
{
	axis = normalize(axis);
	float s = sin(angle);
	float c = cos(angle);
	return v * c + cross(axis, v) * s + axis * dot(axis, v) * (1.0 - c);
}

float sdSphere(vec3 p, float radius)
{
	return length(p) - radius;
}

float smin(float a, float b, float k)
{
	float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
	return mix(b, a, h) - k * h * (1.0 - h);
}

float HenyeyGreenstein(float g, float mu)
{
	float gg = g * g;
	return (1.0 / (4.0 * VPI)) * ((1.0 - gg) / pow(1.0 + gg - 2.0 * g * mu, 1.5));
}

float BeersLaw(float dist, float absorption)
{
	return exp(-dist * absorption);
}

float vol_hash11(float p)
{
	p = fract(p * 0.1031);
	p *= p + 33.33;
	p *= p + p;
	return fract(p);
}

float vcloud_rand(float seed)
{
	return fract(sin(seed) * 43758.5453123);
}

float noise(vec3 x)
{
	vec3 p = floor(x);
	vec3 f = fract(x);

	f = f * f * (3.0 - 2.0 * f);

	float n = p.x + p.y * 57.0 + 113.0 * p.z;

	float res = mix(
		mix(
			mix(vol_hash11(n + 0.0), vol_hash11(n + 1.0), f.x),
			mix(vol_hash11(n + 57.0), vol_hash11(n + 58.0), f.x),
			f.y
		),
		mix(
			mix(vol_hash11(n + 113.0), vol_hash11(n + 114.0), f.x),
			mix(vol_hash11(n + 170.0), vol_hash11(n + 171.0), f.x),
			f.y
		),
		f.z
	);

	return res;
}

float fbm(vec3 p, bool lowRes)
{
	float frequency = 1.9;
	float s = 0.5;
	float a = 0.0;
	float b = 1.0;

	if (lowRes) {
		for (int i = 0; i < 3; i++) {
			float n = noise(p);
			a += b * n;
			b *= s;
			p = frequency * vol_m * p;
		}
	} else {
		for (int i = 0; i < 5; i++) {
			float n = noise(p);
			a += b * n;
			b *= s;
			p = frequency * vol_m * p;
		}
	}

	return a;
}

float scene(vec3 p, bool lowRes, vec3 timeOffset, vec2 sphereOffset, vec2 sphereRadii, float cloudBlend, vec3 noiseOffset)
{
	float s1 = sdSphere(p + vec3(1.0 + sphereOffset.x, sphereOffset.y, 0.0), sphereRadii.x);
	float s2 = sdSphere(p + vec3(-1.0 + sphereOffset.x, sphereOffset.y, 0.0), sphereRadii.y);

	float d = smin(s1, s2, cloudBlend);

	return -d + fbm(p + timeOffset + noiseOffset, lowRes);
}

float lightmarch(vec3 position, vec3 lightDirection, vec3 timeOffset, vec2 sphereOffset, vec2 sphereRadii, float cloudBlend, vec3 noiseOffset)
{
	float totalDensity = 0.0;
	float marchSize = 0.20;
	vec3 lightStep = lightDirection * marchSize;
	float stepScale = 0.0;

	for (int step = 0; step < VMAX_STEPS_LIGHTS; step++) {
		float lightSample = scene(position, true, timeOffset, sphereOffset, sphereRadii, cloudBlend, noiseOffset);
		totalDensity += lightSample;
		stepScale += 1.0;
		position += lightStep * stepScale;
	}

	return BeersLaw(totalDensity, ABSORPTION_COEFFICIENT);
}

float raymarch(vec3 rayOrigin, vec3 rayDirection, vec3 lightPosition, float offset, float time, vec2 sphereOffset, vec2 sphereRadii, float cloudBlend, vec3 noiseOffset)
{
	float marchSize = OG_MARCH_SIZE;

	float depth = 0.0;
	depth += marchSize * offset;

	vec3 lightDirection = normalize(lightPosition);

	float totalTransmittance = 1.0;
	float lightEnergy = 0.0;

	float mu = dot(rayDirection, lightDirection);
	float phase = mix(
		HenyeyGreenstein(-1.0 * SCATTERING_ANISO, mu),
		HenyeyGreenstein(SCATTERING_ANISO, mu),
		0.75
	);

	vec3 timeOffset = vec3(time * 0.31666667, time * 0.03333333, time * 0.13333333);
	vec3 rayStep = rayDirection * marchSize;
	vec3 p = rayOrigin + depth * rayDirection;

	for (int i = 0; i < VMAX_STEPS; i++) {
		float density = scene(p, false, timeOffset, sphereOffset, sphereRadii, cloudBlend, noiseOffset);

		if (density > 0.0) {
			float transmittance = BeersLaw(density * marchSize, ABSORPTION_COEFFICIENT);
			float lightTransmittance = lightmarch(p, lightDirection, timeOffset, sphereOffset, sphereRadii, cloudBlend, noiseOffset);
			float luminance = density * lightTransmittance * phase;

			totalTransmittance *= transmittance;
			lightEnergy += totalTransmittance * luminance;

			if (totalTransmittance < 0.001) {
				break;
			}
		}

		p += rayStep;
	}

	return clamp(lightEnergy, 0.0, 1.0);
}

vec4 effect(vec4 vcolor, Image tex0, vec2 tc, vec2 sc)
{
	vec2 uv01 = ((tc * image_details) - _tex_details.xy) / _tex_details.ba;
	vec2 res = _tex_details.ba;
	vec2 fragCoord = uv01 * res;

	fragCoord.y = res.y - fragCoord.y;

	vec4 base = Texel(tex0, tc);

	float t = vcloud.y;
    // float t = 50*time;

	float gid0 = vcloud_rand(GameID * 17.13 + 0.7);
	float gid1 = vcloud_rand(GameID * 29.71 + 3.1);
	float gid2 = vcloud_rand(GameID * 41.37 + 7.9);
	float gid3 = vcloud_rand(GameID * 53.91 + 11.4);
	float gid4 = vcloud_rand(GameID * 67.27 + 19.6);
	vec2 sphereOffset = vec2((gid0 - 0.5) * 0.36, (gid1 - 0.5) * 0.28);
	vec2 sphereRadii = vec2(0.42 + 0.18 * gid2, 0.24 + 0.14 * gid3);
	float cloudBlend = 1.9 + 0.8 * gid4;
	vec3 noiseOffset = vec3(
		(gid1 - 0.5) * 1.4,
		(gid2 - 0.5) * 1.1,
		(gid3 - 0.5) * 1.4
	);
	float sunAngleOffset = (gid0 - 0.5) * 1.4;
	float sunTintMix = 0.12 + 0.32 * gid2;

	if (hovering > 0.0) {
		t *= 0.45;
	} else {
		t *= 2;
	}

	float timeSpeed = 0.10 + 0.10 * vcloud_rand(GameID * 79.13 + 5.7);
	float timePhase = 6.28318530718 * vcloud_rand(GameID * 91.47 + 2.3);
	number c_time = t * timeSpeed + timePhase;

	vec2 uv = fragCoord / res;
	uv -= 0.5;
	uv.x *= res.x / res.y;

	vec3 color = vec3(0.0);

	vec3 lightPosition  = vec3(0.0, 0.8, 0.8);
	vec3 sunRotationAxis = normalize(vec3(1.0, 1.0, 1.0));

	vec3 brightSunColor = vec3(1.0, 0.97, 0.95);
	vec3 darkSunColor   = vec3(1.0, 0., 0.3);

	float sunAngle = mod(c_time + sunAngleOffset, 2.*VPI);
	vec3 movingSun = rotateAlongAxis(lightPosition, sunRotationAxis, sunAngle);
	vec3 sunColor  = mix(brightSunColor, darkSunColor, clamp(1.0 - sin(sunAngle), 0.0, 1.0));
	sunColor = mix(sunColor, vec3(1.0, 0.92, 0.72), sunTintMix);

	vec3 ro = vec3(0.0, 0.0, 5.0);
	vec3 rd = normalize(vec3(uv, -1.0));

	float offset = 0.0;

	float resMarch = raymarch(ro, rd, movingSun, offset, c_time, sphereOffset, sphereRadii, cloudBlend, noiseOffset);

	color = base.rgb;
	color += sunColor * (1.15 * resMarch);

	color = smoothstep(0.06, 0.96, color);
	float cloudAlpha = smoothstep(0.02, 0.30, resMarch);
	float edge_x = smoothstep(0.0, 0.24, uv01.x) * (1.0 - smoothstep(0.76, 1.0, uv01.x));
	float edge_y = smoothstep(0.0, 0.28, uv01.y) * (1.0 - smoothstep(0.72, 1.0, uv01.y));
	float edge_fade = edge_x * edge_y;
	cloudAlpha *= edge_fade * vcolor.a * 0.8;

	vec4 outc = vec4(color, cloudAlpha);
	return apply_fx_mask(outc, uv01);
}


#ifdef VERTEX
#pragma HM_INCLUDE "_0_lib/_0_position/_0_card_position.inc"
#endif
