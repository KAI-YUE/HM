extern highp vec3 toon_fog;

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
extern highp number blur_severity;
extern highp number blur_radius;
extern highp number speed_factor;
extern highp number blur_clean_stage;
extern highp number blur_turning_point;
extern highp number blur_peak_point;
extern highp number blur_clean_amount;
extern highp number blur_increase_speed;
extern highp number blur_fall_slowdown;
extern highp number fog_alpha;
extern highp vec4 fog_color;
extern highp number fog_perspective;
extern highp number fog_vanish_x;
extern highp number fog_far_scale;
extern highp number fog_near_scale;
extern highp number fog_depth_curve;
extern highp number fog_far_alpha;
extern highp number fog_volume_alpha;
extern highp number fog_volume_depth;
extern highp number fog_volume_scale;
extern highp number fog_volume_light;
extern highp number fog_volume_shadow;

number GameID = toon_fog.z;

#pragma HM_INCLUDE "_0_lib/_1_masks/_0_dir_sweep.inc"

vec2 uv01_to_tc(vec2 uv01) {
	uv01 = clamp(uv01, vec2(0.001), vec2(0.999));
	return (uv01 * _tex_details.ba + _tex_details.xy) / image_details;
}

vec4 sample_sprite_clamp(Image tex, vec2 uv01) {
	vec4 s = Texel(tex, uv01_to_tc(uv01));
	if (s.a > 0.0001) {
		s.rgb = clamp(s.rgb / s.a, 0.0, 1.0);
	}
	return s;
}

vec4 splats(Image tex, vec2 p, int type, number size, vec2 res) {
	vec4 outc = vec4(number(type * 2 - 1));
	vec2 aspect = vec2(res.y / max(res.x, 0.0001), 1.0);
	vec2 px = vec2(size, 0.0) * aspect;
	vec2 py = vec2(0.0, size);
	vec2 dg = vec2(0.70710678) * size * aspect;

	if (type == 0) {
		outc = max(outc, sample_sprite_clamp(tex, p));
		outc = max(outc, sample_sprite_clamp(tex, p + px));
		outc = max(outc, sample_sprite_clamp(tex, p - px));
		outc = max(outc, sample_sprite_clamp(tex, p + py));
		outc = max(outc, sample_sprite_clamp(tex, p - py));
		outc = max(outc, sample_sprite_clamp(tex, p + dg));
		outc = max(outc, sample_sprite_clamp(tex, p - dg));
		outc = max(outc, sample_sprite_clamp(tex, p + vec2(dg.x, -dg.y)));
		outc = max(outc, sample_sprite_clamp(tex, p + vec2(-dg.x, dg.y)));
	} else {
		outc = min(outc, sample_sprite_clamp(tex, p));
		outc = min(outc, sample_sprite_clamp(tex, p + px));
		outc = min(outc, sample_sprite_clamp(tex, p - px));
		outc = min(outc, sample_sprite_clamp(tex, p + py));
		outc = min(outc, sample_sprite_clamp(tex, p - py));
		outc = min(outc, sample_sprite_clamp(tex, p + dg));
		outc = min(outc, sample_sprite_clamp(tex, p - dg));
		outc = min(outc, sample_sprite_clamp(tex, p + vec2(dg.x, -dg.y)));
		outc = min(outc, sample_sprite_clamp(tex, p + vec2(-dg.x, dg.y)));
	}

	return outc;
}

// -------------------------------------------------
// Fog helpers
// -------------------------------------------------
float st_hash(vec2 p)
{
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float st_noise(vec2 p)
{
	vec2 i = floor(p);
	vec2 f = fract(p);

	f = f * f * (3.0 - 2.0 * f);

	float a = st_hash(i);
	float b = st_hash(i + vec2(1.0, 0.0));
	float c = st_hash(i + vec2(0.0, 1.0));
	float d = st_hash(i + vec2(1.0, 1.0));

	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float st_fbm(vec2 p)
{
	float v = 0.0;
	float a = 0.5;

	mat2 m = mat2(
		1.60,  1.20,
	   -1.20,  1.60
	);

	for (int i = 0; i < 6; i++) {
		v += a * st_noise(p);
		p = m * p + vec2(17.13, 9.27);
		a *= 0.5;
	}

	return v;
}

float st_cloud_shape(vec2 p, float t)
{
	// Big soft body
	float q = st_fbm(p * 1.15 + vec2(-0.055 * t, 0.018 * t));

	// Smaller internal turbulence
	float r = st_fbm(
		p * 2.45
		+ vec2(q * 1.7, q * 1.2)
		+ vec2(-0.120 * t, 0.035 * t)
	);

	// Wispy detail
	float w = st_fbm(
		p * 5.20
		+ vec2(r * 2.2, q * 1.4)
		+ vec2(-0.230 * t, 0.060 * t)
	);

	return q * 0.58 + r * 0.34 + w * 0.18;
}

// -------------------------------------------------
// Volumetric fog helpers
// -------------------------------------------------
const int FOG_VOL_STEPS = 7;

mat3 fog_vol_m = mat3(
	0.00, 0.80, 0.60,
	-0.80, 0.36, -0.48,
	-0.60, -0.48, 0.64
);

float fog_vol_hash11(float p)
{
	p = fract(p * 0.1031);
	p *= p + 33.33;
	p *= p + p;
	return fract(p);
}

float fog_vol_noise(vec3 x)
{
	vec3 p = floor(x);
	vec3 f = fract(x);

	f = f * f * (3.0 - 2.0 * f);

	float n = p.x + p.y * 57.0 + 113.0 * p.z;

	return mix(
		mix(
			mix(fog_vol_hash11(n + 0.0), fog_vol_hash11(n + 1.0), f.x),
			mix(fog_vol_hash11(n + 57.0), fog_vol_hash11(n + 58.0), f.x),
			f.y
		),
		mix(
			mix(fog_vol_hash11(n + 113.0), fog_vol_hash11(n + 114.0), f.x),
			mix(fog_vol_hash11(n + 170.0), fog_vol_hash11(n + 171.0), f.x),
			f.y
		),
		f.z
	);
}

float fog_vol_fbm(vec3 p)
{
	float frequency = 1.9;
	float amp = 0.5;
	float v = 0.0;

	for (int i = 0; i < 5; i++) {
		v += amp * fog_vol_noise(p);
		amp *= 0.5;
		p = frequency * fog_vol_m * p + vec3(9.7, 3.1, 6.4);
	}

	return v;
}

float fog_vol_density(vec3 p, float t)
{
	vec3 wind = vec3(-0.075 * t, 0.024 * t, 0.045 * t);
	float broad = fog_vol_fbm(p * 1.05 + wind);
	float detail = fog_vol_fbm(p * 2.35 + vec3(broad * 1.4, broad * 0.8, broad * 1.1) + wind * 1.85);
	float wisps = fog_vol_fbm(p * 4.80 + vec3(detail * 1.8, broad * 1.2, detail * 1.3) + wind * 3.20);

	return broad * 0.56 + detail * 0.32 + wisps * 0.16;
}

vec2 fog_vol_ray_shift(vec2 plane_uv, float z, float near01)
{
	float depthAmt = fog_volume_depth > 0.0 ? fog_volume_depth : 0.42;
	float nearPush = mix(0.32, 1.0, near01);
	vec2 viewLean = vec2(fog_vanish_x * 0.35, -0.38);
	return (plane_uv * 0.16 + viewLean) * z * depthAmt * nearPush;
}

vec2 fog_vol_sample_uv(vec2 flat_uv, vec2 plane_uv, float z, float near01, float t)
{
	vec2 layer_uv = mix(flat_uv, plane_uv, 0.72);
	layer_uv += fog_vol_ray_shift(plane_uv, z, near01);
	layer_uv += vec2(-0.018 * t, 0.007 * t) * mix(0.55, 1.12, near01);
	return layer_uv;
}

vec3 fog_vol_march(vec2 flat_uv, vec2 plane_uv, float near01, float t)
{
	float scale = fog_volume_scale > 0.0 ? fog_volume_scale : 2.15;
	float alphaScale = fog_volume_alpha > 0.0 ? fog_volume_alpha : 0.72;
	float lightScale = fog_volume_light > 0.0 ? fog_volume_light : 0.62;
	float transmittance = 1.0;
	float densitySum = 0.0;
	float lightSum = 0.0;

	for (int i = 0; i < FOG_VOL_STEPS; i++) {
		float fi = (float(i) + 0.5) / float(FOG_VOL_STEPS);
		float z = mix(-1.0, 1.0, fi);
		vec2 suv = fog_vol_sample_uv(flat_uv, plane_uv, z, near01, t);
		vec3 p = vec3(suv * scale, z * 1.25 + near01 * 0.55);

		float raw = fog_vol_density(p, t);
		float density = smoothstep(0.36, 0.78, raw);
		float sideLight = fog_vol_density(p + normalize(vec3(-0.55, 0.35, 0.72)) * 0.22, t);
		float light = mix(0.58, 1.0, smoothstep(0.30, 0.74, sideLight));
		float stepAlpha = density * alphaScale * 0.165;

		densitySum += transmittance * stepAlpha;
		lightSum += transmittance * stepAlpha * light;
		transmittance *= (1.0 - clamp(stepAlpha, 0.0, 0.86));
	}

	float lit = densitySum > 0.0001 ? lightSum / densitySum : 0.0;
	return vec3(clamp(densitySum, 0.0, 1.0), clamp(lit * lightScale, 0.0, 1.0), transmittance);
}

// -------------------------------------------------
// Fog plane helpers
// -------------------------------------------------
vec2 fog_plane_uv(vec2 uv01, vec2 res)
{
	float aspect = res.x / max(res.y, 0.0001);
	float near01 = smoothstep(0.0, 1.0, uv01.y);
	float persp = clamp(fog_perspective > 0.0 ? fog_perspective : 0.72, 0.0, 1.0);
	float farScale = fog_far_scale > 0.0 ? fog_far_scale : 0.72;
	float nearScale = fog_near_scale > 0.0 ? fog_near_scale : 1.55;
	float scale = mix(farScale, nearScale, near01);
	float curve = fog_depth_curve > 0.0 ? fog_depth_curve : 1.45;
	float depth = pow(near01, curve);
	vec2 uv = uv01 - 0.5;

	uv.x *= aspect;
	uv.x -= fog_vanish_x * aspect * (1.0 - near01) * persp;

	return vec2(uv.x / scale, (depth - 0.5) / scale);
}

vec2 fog_cloud_uv(vec2 uv01, vec2 res)
{
	vec2 uv = uv01 - 0.5;
	uv.x *= res.x / max(res.y, 0.0001);
	return uv;
}

// -------------------------------------------------
// Volumetric region helpers
// -------------------------------------------------
float fog_volume_far_mask(float far01, float right01)
{
	float farTop = smoothstep(0.34, 0.90, far01);
	float rightSide = smoothstep(0.28, 1.0, right01);
	float diagonal = smoothstep(0.16, 0.58, far01 * right01);
	return farTop * rightSide * diagonal;
}

vec4 apply_title_fog(vec4 base, vec2 uv01, vec2 res)
{
	float t = toon_fog.y;

	// Hover makes the clouds feel more alive
	if (hovering > 0.0) {
		t *= 1.75;
	} else {
		t *= 0.85;
	}

	// Keep cloud bodies natural while borrowing perspective from the wallpaper plane.
	vec2 flat_uv = fog_cloud_uv(uv01, res);
	vec2 plane_uv = fog_plane_uv(uv01, res);
	float near01 = smoothstep(0.0, 1.0, uv01.y);
	float persp = clamp(fog_perspective > 0.0 ? fog_perspective : 0.72, 0.0, 1.0);
	float far01 = 1.0 - near01;
	float right01 = smoothstep(0.42, 0.98, uv01.x);
	float farRight3d = smoothstep(0.08, 0.66, far01 * right01);

	// Top-right fog exposes twisted 2d UVs fastest, so let that region stay more screen-natural.
	float bodyPersp = persp * mix(0.32, 0.14, farRight3d);
	float streakPersp = persp * mix(0.62, 0.22, farRight3d);
	vec2 uv = mix(flat_uv, plane_uv, bodyPersp);
	vec2 streak_uv = mix(flat_uv, plane_uv, streakPersp);

	// Diagonal map-like drifting direction
	vec2 p = uv;
	p += vec2(-0.035 * t, 0.012 * t) * mix(0.62, 1.18, near01);

	// Main cloud density
	float rawCloud = st_cloud_shape(p * 2.05, t);

	// Make the cloud obvious for testing
	float cloudCore = smoothstep(0.47, 0.78, rawCloud);
	float cloudSoft = smoothstep(0.32, 0.72, rawCloud);

	// Extra long streaks so it feels like smoke/clouds flying by
	float streak = st_noise(vec2(
		streak_uv.x * 7.5 - t * 0.18,
		streak_uv.y * 1.8 + t * 0.035
	));

	streak = smoothstep(0.42, 0.82, streak);
	float cloud = clamp(cloudCore * 0.52 + cloudSoft * 0.18 + streak * 0.12, 0.0, 1.0);
	cloud *= mix(1.0, 0.42, farRight3d);

	float volCloud = 0.0;
	float volLight = 0.5;
	float volMask = fog_volume_far_mask(far01, right01);
	if (volMask > 0.001) {
		// Layered volume borrowed from vcloud-style 3D noise and front-to-back accumulation.
		vec2 vol_plane_uv = mix(plane_uv, plane_uv * 1.10 + vec2(-0.035, -0.075), farRight3d);
		vec3 vol = fog_vol_march(flat_uv, vol_plane_uv, near01, t);
		volCloud = vol.x * mix(1.0, 1.38, farRight3d) * volMask;
		volLight = clamp(vol.y + farRight3d * 0.16, 0.0, 1.0);
	}

	// Keep fog away from harsh sprite edges
	float edge_x = smoothstep(0.0, 0.10, uv01.x) * (1.0 - smoothstep(0.90, 1.0, uv01.x));
	float edge_y = smoothstep(0.0, 0.12, uv01.y) * (1.0 - smoothstep(0.88, 1.0, uv01.y));
	float edge_fade = edge_x * edge_y;
	float far_alpha = fog_far_alpha > 0.0 ? fog_far_alpha : 0.58;
	float depth_fade = mix(clamp(far_alpha, 0.0, 1.0), 1.0, near01);

	float alpha = (cloud + volCloud * 1.18) * edge_fade * depth_fade * max(fog_alpha, 0.0);

	alpha = clamp(alpha * 0.88, 0.0, 0.78);

	vec3 cloudCol = dot(fog_color.rgb, vec3(1.0)) > 0.0 ? fog_color.rgb : vec3(0.90, 0.96, 1.0);

	// Tiny shadow underneath the cloud so it does not disappear on bright maps
	float shadowAmount = fog_volume_shadow > 0.0 ? fog_volume_shadow : 0.28;
	float shadow = (cloudSoft * 0.55 + volCloud * (1.0 - volLight) * 1.15) * edge_fade * depth_fade * max(fog_alpha, 0.0);
	vec3 shadedBase = base.rgb * (1.0 - shadow * shadowAmount);

	vec3 litCloudCol = cloudCol * mix(0.78, 1.18, volLight);
	vec3 outRgb = mix(shadedBase, litCloudCol, alpha);

	return vec4(outRgb, base.a);
}


// -------------------------------------------------
// Blur helpers
// -------------------------------------------------
number blur_rise(number p, number clean_stage, number turning, number peak, number clean_amount, number increase_speed) {
	p = clamp(p, 0.0, peak);

	if (p < clean_stage) {
		number q = smoothstep(0.0, clean_stage, p);
		q = pow(q, 3.0 / increase_speed);
		return clean_amount * q;
	}

	if (p < turning) {
		number q = smoothstep(clean_stage, turning, p);
		q = pow(q, 2.0 / increase_speed);
		return mix(clean_amount, 0.24, q);
	}

	number q = smoothstep(turning, peak, p);
	return mix(0.24, 1.0, q);
}

number blur_cycle(number p) {
	number clean_stage = blur_clean_stage > 0.0 ? blur_clean_stage : 0.62;
	number turning = blur_turning_point > clean_stage ? blur_turning_point : 0.84;
	number peak = blur_peak_point > turning ? blur_peak_point : 0.91;
	number clean_amount = blur_clean_amount > 0.0 ? blur_clean_amount : 0.035;
	number increase_speed = max(blur_increase_speed, 1.0);
	number fall_slowdown = max(blur_fall_slowdown, 1.0);

	turning = min(turning, 0.94);
	clean_stage = min(clean_stage, turning - 0.001);
	peak = clamp(peak, turning + 0.001, 0.985);

	if (p < peak) {
		return blur_rise(p, clean_stage, turning, peak, clean_amount, increase_speed);
	}

	number q = smoothstep(peak, 1.0, p);
	number reverse_p = peak * (1.0 - pow(q, fall_slowdown));
	return blur_rise(reverse_p, clean_stage, turning, peak, clean_amount, increase_speed);
}

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
	vec2 uv01 = ((tc * image_details) - _tex_details.xy) / _tex_details.ba;
	vec2 mask_uv = clamp(uv01, vec2(0.0), vec2(1.0));
	vec2 res = _tex_details.ba;
	vec4 base = sample_sprite_clamp(tex, uv01);

	number t = toon_fog.y * speed_factor / 6.28318530718;
	number phase = fract(t);
	number radius = blur_radius > 0.0 ? blur_radius : blur_severity * max(res.y, 1.0);
	number amount = blur_cycle(phase);
	number size = amount * radius / max(res.y, 1.0);
	vec4 outc = base;

	if (size > 0.00001) {
		vec3 rgb = splats(tex, uv01, 0, size, res).rgb;
		rgb = 1.75 * rgb / (1.0 + rgb);

		number edge_dist = min(min(mask_uv.x, 1.0 - mask_uv.x), min(mask_uv.y, 1.0 - mask_uv.y));
		number edge_fade = smoothstep(0.0, max(size * 2.0, 0.002), edge_dist);
		number mix_amount = amount * edge_fade;
		outc.rgb = mix(base.rgb, rgb, mix_amount);
	}

	outc = apply_title_fog(outc, mask_uv, res) * color;
	return apply_fx_mask(outc, mask_uv);
}
