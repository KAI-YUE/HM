
extern highp vec3 fog;

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

number GameID = fog.z;

#pragma HM_INCLUDE "_0_lib/_1_masks/_0_dir_sweep.inc"

vec2 cloud_hash2(vec2 p)
{
	p = vec2(
		dot(p, vec2(127.1, 311.7)),
		dot(p, vec2(269.5, 183.3))
	);
	return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float cloud_noise2(vec2 p)
{
	const float K1 = 0.366025404;
	const float K2 = 0.211324865;

	vec2 i = floor(p + (p.x + p.y) * K1);
	vec2 a = p - i + (i.x + i.y) * K2;
	float m = step(a.y, a.x);
	vec2 o = vec2(m, 1.0 - m);
	vec2 b = a - o + K2;
	vec2 c = a - 1.0 + 2.0 * K2;

	vec3 h = max(0.5 - vec3(dot(a, a), dot(b, b), dot(c, c)), 0.0);
	vec3 n = h * h * h * h * vec3(
		dot(a, cloud_hash2(i + 0.0)),
		dot(b, cloud_hash2(i + o)),
		dot(c, cloud_hash2(i + 1.0))
	);

	return dot(n, vec3(70.0));
}

const mat2 cloud_m2 = mat2(1.6, 1.2, -1.2, 1.6);

float cloud_fbm4(vec2 p)
{
	float amp = 0.5;
	float h = 0.0;

	for (int i = 0; i < 4; i++) {
		float n = cloud_noise2(p);
		h += amp * n;
		amp *= 0.5;
		p = cloud_m2 * p;
	}

	return 0.5 + 0.5 * h;
}

vec4 effect(vec4 vcolor, Image tex0, vec2 tc, vec2 sc)
{
	vec2 uv01 = ((tc * image_details) - _tex_details.xy) / _tex_details.ba;
	vec2 res = _tex_details.ba;
	vec2 fragCoord = uv01 * res;

	fragCoord.y = res.y - fragCoord.y;

	vec4 base = Texel(tex0, tc);

	float fog_time = fog.y;
	float tit = fog_time;

	if (hovering > 0.0) {
		fog_time *= 2.0;
		tit *= 2.0;
	} else {
		fog_time *= 0.5;
	}

	float tilt01 = fog.x;
	if (tilt01 < 0.0 || tilt01 > 1.0) {
		tilt01 = tilt01 * 0.5 + 0.5;
	}
	tilt01 = clamp(tilt01, 0.0, 1.0);

	vec2 uv = fragCoord / res;
	uv -= 0.5;
	uv.x *= res.x / res.y;

	vec2 mo = vec2(tilt01 - 0.5) * 10.0;

	vec3 cloudCol = vec3(0.92, 0.96, 1.0);
	vec3 col = mix(base.rgb, cloudCol, 0.18);

	float v = 0.001;

	uv += mo;

	vec2 scale = uv * 2.0;
	vec2 turbulence = 0.008 * vec2(
		cloud_noise2(vec2(uv.x * 10.0, uv.y * 10.0)),
		cloud_noise2(vec2(uv.x * 10.0, uv.y * 10.0))
	);
	scale += turbulence;

	float n1 = cloud_fbm4(vec2(
		scale.x - 20.0 * sin(fog_time * v * 2.0),
		scale.y - 50.0 * sin(tit * v)
	));

	col = mix(col, cloudCol, smoothstep(0.38, 0.78, n1) * 0.72);

	scale = uv * 0.5;
	turbulence = 0.05 * vec2(
		cloud_noise2(vec2(uv.x * 2.0, uv.y * 2.1)),
		cloud_noise2(vec2(uv.x * 1.5, uv.y * 1.2))
	);
	scale += turbulence;

	float n2 = cloud_fbm4(scale + 20.0 * sin(fog_time * v));
	col = mix(col, cloudCol, smoothstep(0.12, 0.78, n2) * 0.82);
	col = min(col, vec3(1.0));

	float a1 = smoothstep(0.38, 0.78, n1);
	float a2 = smoothstep(0.12, 0.78, n2);
	float cloudAlpha = clamp(max(a1, a2) * 0.58 + 0.10, 0.0, 0.72) * vcolor.a;
	float edge_x = smoothstep(0.0, 0.12, uv01.x) * (1.0 - smoothstep(0.88, 1.0, uv01.x));
	float edge_y = smoothstep(0.0, 0.16, uv01.y) * (1.0 - smoothstep(0.84, 1.0, uv01.y));
	float edge_fade = edge_x * edge_y;
	cloudAlpha *= edge_fade;
	vec4 outc = vec4(col, cloudAlpha);
	return apply_fx_mask(outc, uv01);
}
