#define SPEED 1.0
#define PI 3.14159265359
// #define STROKE_ROWS 20
// #define STROKE_COLUMNS 4
#define STROKE_ROWS 5
#define STROKE_COLUMNS 4
#define STROKE_COUNT (STROKE_ROWS * STROKE_COLUMNS)
#define FBM_OCTAVES 3

extern highp vec2 texel_size;
extern highp float time;
extern highp float progress;
extern highp vec4 tunnel_tone_light;
extern highp vec4 tunnel_tone_mid;
extern highp vec4 tunnel_tone_accent;
extern highp float quick_pass;
extern highp vec3 phases;
extern highp float transition_id;
extern highp float brush_wobble;
extern highp float brush_bleed;
extern highp float brush_stroke_width;
extern highp float brush_cover_start;
extern highp float brush_cover_end;
extern highp float cover_wipe_pass;

extern highp number fx_mask;
extern highp number fx_mask_dir;
extern highp number fx_mask_seed;
extern highp vec4 _tex_details;
extern highp vec2 image_details;
extern highp vec4 wipe_rect;
extern bool shadow;
extern highp vec4 c1;
extern highp vec4 c2;
extern highp vec3 generic;

number GameID = generic.z;

// Page-wipe include replaced by directional brush wipe for cover_wipe_pass.
#pragma HM_INCLUDE "_0_lib/_1_masks/_-1_page_wipe.inc"

// --- Helper: saturate
float saturate(float v) { return clamp(v, 0.0, 1.0); }

// --- Helper: ease_out_cubic
float ease_out_cubic(float v)
{
	float t = saturate(v);
	return 1.0 - pow(1.0 - t, 3.0);
}

// --- Helper: r11
number r11(number p)
{
	p = fract(p * 0.1031);
	p *= p + 33.33;
	p *= p + p;
	return fract(p);
}

// --- Helper: r12
vec2 r12(number p)
{
	vec3 p3 = fract(vec3(p) * vec3(0.1031, 0.1030, 0.0973));
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.xx + p3.yz) * p3.zy);
}

// --- Helper: brush_game_seed
number brush_game_seed(number id_seed)
{
	return id_seed + GameID * 97.31 + r11(GameID + 19.7) * 41.0;
}

// --- Helper: scribble_hash21
number scribble_hash21(vec2 p)
{
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

// --- Helper: value_noise
number value_noise(vec2 p)
{
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);

	number a = scribble_hash21(i);
	number b = scribble_hash21(i + vec2(1.0, 0.0));
	number c = scribble_hash21(i + vec2(0.0, 1.0));
	number d = scribble_hash21(i + vec2(1.0, 1.0));

	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// --- Helper: fbm
number fbm(vec2 p)
{
	number v = 0.0;
	number a = 0.5;
	mat2 m = mat2(1.6, 1.2, -1.2, 1.6);

	for (int i = 0; i < FBM_OCTAVES; i++) {
		v += a * value_noise(p);
		p = m * p + 17.31;
		a *= 0.5;
	}

	return v;
}

// --- Helper: watercolor
number watercolor(vec2 p)
{
	p *= 5.0;

	vec2 q = vec2(0.0);
	q.x = fbm(p);
	q.y = fbm(p + vec2(1.0));

	vec2 r = vec2(0.0);
	r.x = fbm(p + q + vec2(1.7, 9.2));
	r.y = fbm(p + q + vec2(8.3, 2.8));

	return saturate(fbm(p + r));
}

// --- Helper: rot2
vec2 rot2(vec2 p, number a)
{
	number c = cos(a);
	number s = sin(a);
	return mat2(c, -s, s, c) * p;
}

// --- Helper: n_i_1
number n_i_1(number t, number i)
{
	return step(i, t) * step(t, i + 1.0);
}

// --- Helper: n_i_2
number n_i_2(number t, number i)
{
	return
		n_i_1(t, i) * (t - i) +
		n_i_1(t, i + 1.0) * (i + 2.0 - t);
}

// --- Helper: n_i_3
number n_i_3(number t, number i)
{
	return
		n_i_2(t, i) * (t - i) * 0.5 +
		n_i_2(t, i + 1.0) * (i + 3.0 - t) * 0.5;
}

// --- Helper: brush_tuning
vec3 brush_tuning()
{
	return vec3(
		clamp(brush_wobble, 0.0, 3.0),
		clamp(brush_bleed, 0.0, 3.0),
		clamp(brush_stroke_width, 0.05, 3.0)
	);
}

// --- Helper: spline_y
number spline_y(number x, vec2 guv, number stroke_seed, number wobble_scale)
{
	number t = x * 5.0 + 1.0;

	number n1 = value_noise(vec2(t * 4.0 + stroke_seed, 0.0));
	number n2 = value_noise(vec2(t * 19.0 + stroke_seed, 7.0));

	number amp = 0.055 + (n1 * 0.10 - n2 * 0.025);
	amp *= wobble_scale;

	t += n1 * 0.45 * wobble_scale;

	number res = 0.0;

	for (int i = 0; i < 5; i++) {
		number fi = number(i);
		number cp = (r11(fi + stroke_seed) * 2.0 - 1.0) * amp;
		res += cp * n_i_3(t, fi);
	}

	res -= smoothstep(0.0, 1.0, guv.x * 0.42 + 0.10) * 0.45;
	res += smoothstep(0.0, 1.0, -guv.x * 0.30) * 0.35;

	return res;
}

// --- Helper: bspline_dist
number bspline_dist(vec2 coords, vec2 guv, number stroke_seed, number draw_progress, number wobble_scale)
{
	vec2 roll = r12(stroke_seed * 0.013);
	coords = rot2(coords, -PI * roll.x * 0.12);

	number y = spline_y(coords.x, guv, stroke_seed, wobble_scale);

	number eps = 0.003;
	number y1 = spline_y(coords.x - eps, guv, stroke_seed, wobble_scale);
	number y2 = spline_y(coords.x + eps, guv, stroke_seed, wobble_scale);
	number slope = (y2 - y1) / max(2.0 * eps, 0.0001);

	number d = abs(y - coords.y) / length(vec2(slope, -1.0));

	number start_x = -0.80;
	number end_x = mix(start_x, 1.10, draw_progress);

	d = max(d, start_x - coords.x);
	d = max(d, coords.x - end_x);

	return d;
}

// --- Helper: large_brush_mask
number large_brush_mask(vec2 p, vec2 guv, number stroke_seed, number draw_progress, number width)
{
	vec3 tuning = brush_tuning();
	number wobble_scale = tuning.x;
	number bleed_scale = tuning.y;
	width *= tuning.z;

	number d = bspline_dist(p, guv, stroke_seed, draw_progress, wobble_scale);
	vec2 n = p * 12.0 + vec2(stroke_seed * 0.071, -stroke_seed * 0.039);
	number broad = fbm(n);
	number fine = fbm(n * 2.2 + vec2(4.7, 2.1));
	number edge_wobble = ((broad - 0.48) * 0.62 + (fine - 0.5) * 0.18) * width * 1.65 * wobble_scale;
	d += clamp(edge_wobble, -width * 0.95 * bleed_scale, width * 0.95 * bleed_scale);

	number aa = max(fwidth(d) * mix(0.9, 2.7, bleed_scale / 3.0), 0.001);
	number body = 1.0 - smoothstep(width, width + aa, d);

	number dry = value_noise(p * 38.0 + stroke_seed * 0.017);
	number wash = mix(broad, fine, 0.45);
	number texture_cut = smoothstep(0.08, mix(0.98, 0.78, bleed_scale / 3.0), dry + wash * 0.48);
	number edge = 1.0 - smoothstep(width * mix(0.48, 0.24, bleed_scale / 3.0), width + aa, d);

	body *= mix(0.68, 1.0, texture_cut);
	body = max(body, edge * mix(0.12, 0.42, bleed_scale / 3.0) * wash);
	return saturate(body);
}

// --- Helper: blend_scribble
vec3 blend_scribble(vec3 base_rgb, vec3 ink_rgb, number mask)
{
	vec3 darkened = mix(base_rgb, min(base_rgb, ink_rgb), mask);
	vec3 replaced = mix(base_rgb, ink_rgb, mask * 0.85);
	return mix(darkened, replaced, 0.65);
}

// --- Helper: scribble_transition
vec4 scribble_transition(vec4 snap, vec2 uv, number draw_progress, number id_seed)
{
	number mask_total = 0.0;
	vec3 col = snap.rgb;

	for (int i = 0; i < STROKE_COUNT; i++) {
		number fi = number(i);
		number row = floor(fi / number(STROKE_COLUMNS));
		number side = mod(fi, number(STROKE_COLUMNS));
		number stroke_seed = r11(fi * 31.17 + id_seed * 13.19 + 9.73) * 2000.0 + id_seed * 17.0 + 17.0;

		vec2 offset = vec2(
			mix(-0.18, 0.18, r11(stroke_seed + 2.0)),
			mix(-0.82, 0.82, (row + 0.5) / number(STROKE_ROWS)) + mix(-0.08, 0.08, r11(stroke_seed + 5.0))
		);
		offset.x += side < 0.5 ? -0.42 : 0.42;

		vec2 scale = vec2(
			mix(1.05, 1.45, r11(stroke_seed + 3.0)),
			mix(0.95, 1.35, r11(stroke_seed + 7.0))
		);

		vec2 p = uv + offset;
		p /= scale;

		number stagger = fi / number(STROKE_COUNT) * 0.36;
		number local_progress = ease_out_cubic(saturate((draw_progress - stagger) / 0.64));
		number width = mix(0.040, 0.082, r11(stroke_seed + 11.0));
		number mask = large_brush_mask(p, uv, stroke_seed, local_progress, width);
		number pigment = mix(0.84, 1.06, fbm(p * 7.5 + stroke_seed * 0.011));

		number white_turn = step(0.5, fract(fi * 0.5));
		vec3 ink = mix(tunnel_tone_accent.rgb, tunnel_tone_light.rgb, white_turn);
		ink = mix(ink, tunnel_tone_mid.rgb, 0.18);
		ink *= pigment;

		col = blend_scribble(col, ink, mask);
		mask_total = max(mask_total, mask);
	}

	return vec4(col, mask_total);
}

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc)
{
	if (cover_wipe_pass > 0.5) {
		vec4 base = Texel(tex, tc) * color;
		vec2 wipe_uv = (sc - wipe_rect.xy) / max(wipe_rect.zw, vec2(1.0));
		return apply_fx_mask(base, clamp(wipe_uv, vec2(0.0), vec2(1.0)));
	}

	if (quick_pass > 0.5) return vec4(0.0);

	vec2 resolution = 1.0 / texel_size;
	vec2 uv = (tc - vec2(0.5)) * vec2(resolution.x / max(resolution.y, 1.0), 1.0);
	number id_seed = max(transition_id, 1.0);
	number direction_seed = brush_game_seed(id_seed);
	number direction = mix(-PI, PI, r11(direction_seed * 0.137 + 4.1));
	uv = rot2(uv, direction);
	if (r11(direction_seed * 0.211 + 8.7) > 0.5) uv.x = -uv.x;

	float p = saturate(progress);
	float fade_in_end = phases.x;
	float fade_out_start = saturate(phases.x + phases.y);
	float fade_alpha = 1.0 - smoothstep(fade_out_start, min(1.0, fade_out_start + phases.z), p);
	float fade_in_p = ease_out_cubic(saturate(p / max(fade_in_end, 0.01)));

	vec4 snap = Texel(tex, tc);
	vec4 scribble = scribble_transition(snap, uv, fade_in_p, id_seed);

	vec3 base_rgb = snap.rgb;
	vec3 rgb = mix(base_rgb, scribble.rgb, scribble.a);
	float alpha = scribble.a * fade_in_p * fade_alpha;

	return vec4(rgb, alpha) * color;
}
