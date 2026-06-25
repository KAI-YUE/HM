extern highp vec3	_1_sparks;			// x = tilt_var (mouseX-ish), y = time, z = GameID
extern highp vec4	_tex_details;	// xy = viewport offset (px), ba = viewport size (px)
extern highp vec2	image_details;	// full atlas size (px)

extern highp number	fx_mask;
extern bool			shadow;
extern highp vec4 c1;
extern highp vec4 c2;

extern highp vec2 mouse_screen_pos;
extern highp float hovering;
extern highp float hover_tilt;
extern highp float screen_scale;
extern highp float position_shader_mode;
extern highp number time;

number GameID = _1_sparks.z;

#pragma HM_INCLUDE "_0_lib/_1_masks/_0_dir_sweep.inc"

#define PI 3.1415927
#define TWO_PI 6.283185

#define ANIMATION_SPEED 1.5
#define MOVEMENT_SPEED 1.0

#define PARTICLE_SIZE 0.021

#define PARTICLE_SCALE (vec2(0.5, 1.6))
#define PARTICLE_SCALE_VAR (vec2(0.25, 0.2))

#define PARTICLE_BLOOM_SCALE (vec2(0.5, 0.8))
#define PARTICLE_BLOOM_SCALE_VAR (vec2(0.3, 0.1))

#define SPARK_COLOR vec3(1.0, 0.4, 0.05) * 1.65
#define BLOOM_COLOR vec3(1.0, 0.4, 0.05) * 0.95
#define SMOKE_COLOR vec3(1.0, 0.43, 0.1) * 0.68

#define SIZE_MOD 1.05
#define ALPHA_MOD 0.1
#define LAYERS_COUNT 12

#define LAB_MAX_NOISE_LAYERS 6
#define LAB_MAX_PARTICLE_LAYERS 16

vec2 lab_uv01_to_tc(vec2 uv01)
{
	uv01 = clamp(uv01, 0.0, 1.0);
	vec2 px = uv01 * _tex_details.ba + _tex_details.xy;
	return px / image_details;
}

// ---- hash / noise Helpers (replacing hash2_2 / noise1_2 / noise2_2 / hash1_2) ----
float hash1_2(vec2 p)
{
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

vec2 hash2_2(vec2 p)
{
	vec2 q = vec2(
		dot(p, vec2(127.1, 311.7)),
		dot(p, vec2(269.5, 183.3))
	);
	return fract(sin(q) * 43758.5453123);
}

float noise1_2(vec2 p)
{
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);

	float a = hash1_2(i + vec2(0.0, 0.0));
	float b = hash1_2(i + vec2(1.0, 0.0));
	float c = hash1_2(i + vec2(0.0, 1.0));
	float d = hash1_2(i + vec2(1.0, 1.0));

	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

vec2 noise2_2(vec2 p)
{
	// decorrelate the 2 channels
	return vec2(
		noise1_2(p),
		noise1_2(p + vec2(37.2, 17.7))
	);
}

// Rotates point around 0,0 (keeps the original snippet’s matrix style)
vec2 rotate(in vec2 point, in float deg)
{
	float s = sin(deg);
	float c = cos(deg);
	return mat2(s, c, -c, s) * point;
}

// Cell center from point on the grid
vec2 voronoiPointFromRoot(in vec2 root, in float deg)
{
	vec2 point = hash2_2(root) - 0.5;
	float s = sin(deg);
	float c = cos(deg);
	point = mat2(s, c, -c, s) * point * 0.66;
	point += root + 0.5;
	return point;
}

// Voronoi cell point rotation degrees
float degFromRootUV(in vec2 uv, float t)
{
	return t * ANIMATION_SPEED * (hash1_2(uv) - 0.5) * 2.0;
}

vec2 randomAround2_2(in vec2 point, in vec2 range, in vec2 uv)
{
	return point + (hash2_2(uv) - 0.5) * range;
}

vec2 sparks_movement_direction(float gameId)
{
	float angle_jitter = (fract(sin(gameId * 73.217) * 43758.5453123) - 0.5) * 2.5;
	float stretch = 0.85 + 0.35 * fract(sin((gameId + 11.0) * 31.913) * 24634.6345);
	return normalize(vec2(0.3 + angle_jitter, -1.8 * stretch));
}

vec2 sparks_particle_scale(float gameId)
{
	float sx = 0.88 + 0.28 * fract(sin((gameId + 3.0) * 41.271) * 15317.7312);
	float sy = 0.84 + 0.32 * fract(sin((gameId + 19.0) * 67.913) * 31837.1246);
	return PARTICLE_SCALE * vec2(sx, sy);
}

float layeredNoise1_2(in vec2 uv, in float sizeMod, in float alphaMod, in int layers, in float animation, in vec2 movement_direction, float t)
{
	float n = 0.0;
	float alpha = 1.0;
	float size = 1.0;
	vec2 offset = vec2(0.0);
	vec2 motion = t * animation * 8.0 * movement_direction * MOVEMENT_SPEED;

	for (int i = 0; i < LAB_MAX_NOISE_LAYERS; i++)
	{
		if (i >= layers)
			break;

		offset += hash2_2(vec2(alpha, size)) * 10.0;

		n += noise1_2(
			uv * size
			+ motion
			+ offset
		) * alpha;

		alpha *= alphaMod;
		size *= sizeMod;
	}

	// normalize like original
	n *= (1.0 - alphaMod) / (1.0 - pow(alphaMod, float(layers)));
	return n;
}

vec3 fireParticles(in vec2 uv, in vec2 originalUV, vec2 particle_scale, float t, float pixelAA)
{
	vec3 particles = vec3(0.0);
	vec2 rootUV = floor(uv);

	float deg = degFromRootUV(rootUV, t);
	vec2 pointUV = voronoiPointFromRoot(rootUV, deg);

	// UV manipulation for faster particle movement
	vec2 tempUV = uv + (noise2_2(uv * 2.0) - 0.5) * 0.1;
	tempUV += -(noise2_2(uv * 3.0 + t) - 0.5) * 0.07;
	vec2 rotated_delta = rotate(tempUV - pointUV, 0.7);
	vec2 bloom_scale = PARTICLE_BLOOM_SCALE * (particle_scale / PARTICLE_SCALE);

	// Sparks sdf
	float dist = length(rotated_delta * randomAround2_2(particle_scale, PARTICLE_SCALE_VAR, rootUV));

	// Bloom sdf
	float distBloom = length(rotated_delta * randomAround2_2(bloom_scale, PARTICLE_BLOOM_SCALE_VAR, rootUV));
	float sparkAA = max(pixelAA, PARTICLE_SIZE * 0.35);
	float bloomAA = max(pixelAA * 1.8, PARTICLE_SIZE * 0.75);

	particles += (1.0 - smoothstep(PARTICLE_SIZE * 0.6 - sparkAA, PARTICLE_SIZE * 0.6 + sparkAA, dist)) * SPARK_COLOR;
	particles += pow((1.0 - smoothstep(PARTICLE_SIZE * 2.2 - bloomAA, PARTICLE_SIZE * 2.2 + bloomAA, distBloom)), 3.0) * BLOOM_COLOR;

	// Upper disappear curve randomization
	float border = (hash1_2(rootUV) - 0.5) * 2.0;
	float disappear = 1.0 - smoothstep(border, border + 0.5, originalUV.y);

	// Lower appear curve randomization
	border = (hash1_2(rootUV + 0.214) - 1.8) * 0.7;
	float appear = smoothstep(border, border + 0.4, originalUV.y);

	return particles * disappear * appear;
}

// Layering particles to imitate 3D view
vec3 layeredParticles(in vec2 uv, in float sizeMod, in float alphaMod, in int layers, in float smoke, in vec2 movement_direction, in vec2 particle_scale, float t, float pixelAA)
{
	vec3 particles = vec3(0.0);
	float size = 1.0;
	float alpha = 1.0;
	vec2 offset = vec2(0.0);
	vec2 motion = t * movement_direction * MOVEMENT_SPEED;

	for (int i = 0; i < LAB_MAX_PARTICLE_LAYERS; i++)
	{
		if (i >= layers)
			break;

		vec2 noiseOffset = (noise2_2(uv * size * 2.0 + 0.5) - 0.5) * 0.15;

		vec2 bokehUV = (uv * size + motion) + offset + noiseOffset;

		particles += fireParticles(bokehUV, uv, particle_scale, t, pixelAA * size) * alpha * (1.0 - smoothstep(0.0, 1.0, smoke) * (float(i) / float(layers)));

		offset += hash2_2(vec2(alpha, alpha)) * 10.0;

		alpha *= alphaMod;
		size *= sizeMod;
	}

	return particles;
}

vec3 deployedParticles(in vec2 uv, in float smoke, in vec2 movement_direction, in vec2 particle_scale, float t, float pixelAA)
{
	vec3 particles = layeredParticles(uv, SIZE_MOD, ALPHA_MOD, LAYERS_COUNT, smoke, movement_direction, particle_scale, t, pixelAA);

	vec2 center_anchor = vec2(0.6, -0.6);
	vec2 top_anchor = vec2(0.0, 1);
	vec2 bottom_anchor = vec2(0.0, 1.32);
	vec2 focal_scale = particle_scale * vec2(0.62, 0.62);
	number deploy_radius = 0.8;
	number deploy_softness = 0.3;
	number deploy_gain = 0.8;

	number center_mask = 1.0 - smoothstep(deploy_radius - deploy_softness, deploy_radius + deploy_softness, distance(uv, center_anchor));
	number top_mask = 1.0 - smoothstep(deploy_radius - deploy_softness, deploy_radius + deploy_softness, distance(uv, top_anchor));
	number bottom_mask = 1.0 - smoothstep(deploy_radius - deploy_softness, deploy_radius + deploy_softness, distance(uv, bottom_anchor));

	particles += layeredParticles(uv - center_anchor, SIZE_MOD, ALPHA_MOD, LAYERS_COUNT, smoke, sparks_movement_direction(GameID+1), focal_scale, t, pixelAA) * (deploy_gain * center_mask);
	particles += layeredParticles(uv - top_anchor, SIZE_MOD, ALPHA_MOD, LAYERS_COUNT, smoke, sparks_movement_direction(GameID+2), focal_scale, t, pixelAA) * (deploy_gain * top_mask);
	particles += layeredParticles(uv - bottom_anchor, SIZE_MOD, ALPHA_MOD, LAYERS_COUNT, smoke, sparks_movement_direction(GameID+3), focal_scale, t, pixelAA) * (deploy_gain * bottom_mask);

	return particles;
}

vec4 lab_fire_sparks_smoke(vec2 fragCoord, vec2 iResolution, vec2 movement_direction, vec2 particle_scale, float t)
{
	vec2 uv = (2.0 * fragCoord - iResolution) / max(iResolution.x, 1.0);

	float vignette = 1.0 - smoothstep(0.4, 1.4, length(uv + vec2(0.0, 0.3)));
	if (vignette <= 0.001) {
		return vec4(0.0);
	}

	uv *= 1.8;
	float pixelAA = 3.6 / max(iResolution.x, 1.0);
	vec2 motion = t * movement_direction * MOVEMENT_SPEED;

	float smokeIntensity = layeredNoise1_2(
		uv * 10.0 + motion * 4.0,
		1.7, 0.7, 6, 0.2, movement_direction, t
	);

	smokeIntensity *= pow(1.0 - smoothstep(-1.0, 1.6, uv.y), 2.0);

	vec3 smoke = smokeIntensity * SMOKE_COLOR * 0.7 * vignette;

	// Cutting holes in smoke
	smoke *= pow(layeredNoise1_2(
		uv * 4.0 + motion * 0.5,
		1.8, 0.5, 3, 0.2, movement_direction, t
	), 2.0) * 1.5;

	vec3 particles = deployedParticles(uv, smokeIntensity, movement_direction, particle_scale, t, pixelAA);

	vec3 col = particles + smoke + SMOKE_COLOR * 0.02;
	col *= vignette;

	col = smoothstep(-0.08, 1.0, col);

    float intensity = max(max(col.r, col.g), col.b);
	float alpha = smoothstep(0.03, 0.20, intensity);

	return vec4(col, alpha);
}

/* main */
vec4 effect(vec4 color, Image tex0, vec2 tc, vec2 sc)
{
	vec4 base = Texel(tex0, tc);
	vec2 uv01 = 1. - ((tc * image_details) - _tex_details.xy) / _tex_details.ba;
	vec2 mask_uv = uv01;
	if (shadow) {
		return apply_fx_mask(base * color, mask_uv);
	}

	vec2 fx_uv = uv01;
	fx_uv.x = 1.0 - fx_uv.x;
	fx_uv.y = abs(fx_uv.y - 0.5) * 1.55;
	fx_uv += vec2(0.1, 0.3);

	vec2 res = max(_tex_details.ba, vec2(1.0, 1.0));
	vec2 fragCoord = fx_uv * res;

	float t = _1_sparks.y;
	if (hovering > 0.0) { t *= 1.5; }
	else { t *= 0.3; }
    if (position_shader_mode >= 0.5 && hovering <= 0.0) { t *= 0.5; }

	number id_phase = fract(sin(GameID * 91.731) * 43758.5453123);
	vec2 movement_direction = sparks_movement_direction(GameID);
	vec2 particle_scale = sparks_particle_scale(GameID);
	number axis_offset = 0.10;
	number gate_softness = 0.1;
	number phase_blend = 0.3;
	number phase_period = 1.0 + 0.08 * (id_phase - 0.5);
	number cycle_pos = t / phase_period;
	number phase_index = mod(floor(cycle_pos), 3.0);
	number phase_frac = fract(cycle_pos);
	number gate = 1.0;
	number axis_band_halfwidth = 0.05;
	number axis_band_softness = 0.025;
	number gate_phase_1 = smoothstep(0.5 - axis_offset - gate_softness, 0.5 - axis_offset + gate_softness, uv01.y);
	number gate_phase_2 = 1.0 - smoothstep(0.5 + axis_offset - gate_softness, 0.5 + axis_offset + gate_softness, uv01.y);
	number gate_phase_3 = 0.3;
	number axis_dist = abs(uv01.y - 0.5);
	number axis_protect = smoothstep(axis_band_halfwidth - axis_band_softness, axis_band_halfwidth + axis_band_softness, axis_dist);

	if (phase_index < 0.5) {
		gate = gate_phase_1;
		if (phase_frac > 1.0 - phase_blend) {
			number mix_t = smoothstep(1.0 - phase_blend, 1.0, phase_frac);
			gate = mix(gate_phase_1, gate_phase_2, mix_t);
		}
	} else if (phase_index < 1.5) {
		gate = gate_phase_2;
		if (phase_frac > 1.0 - phase_blend) {
			number mix_t = smoothstep(1.0 - phase_blend, 1.0, phase_frac);
			gate = mix(gate_phase_2, gate_phase_3, mix_t);
		}
	} else {
		gate = gate_phase_3;
		if (phase_frac > 1.0 - phase_blend) {
			number mix_t = smoothstep(1.0 - phase_blend, 1.0, phase_frac);
			gate = mix(gate_phase_3, gate_phase_1, mix_t);
		}
	}

	gate *= axis_protect;

	if (gate <= 0.001) {
		return apply_fx_mask(vec4(base.rgb, base.a) * color, mask_uv);
	}

	vec4 lab = lab_fire_sparks_smoke(fragCoord, res, movement_direction, particle_scale, t);
	vec3 blended_rgb = clamp(base.rgb + lab.rgb * lab.a * gate, 0.0, 1.0);
	vec4 outc = vec4(blended_rgb, base.a) * color;

	return apply_fx_mask(outc, mask_uv);
}

#ifdef VERTEX
#pragma HM_INCLUDE "_0_lib/_0_position/_0_card_position.inc"
#endif
