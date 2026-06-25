extern highp number time;

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

extern highp vec2 seam_point;
extern highp vec2 seam_normal;
extern highp number seam_side;
extern highp number feather_px;

number GameID = generic.z;

#pragma HM_INCLUDE "_0_lib/_1_masks/_-1_page_wipe.inc"

const number wobble_px = 2.5;
const number overstep_px = 0.;

highp number seam_hash21(highp vec2 p)
{
	p = fract(p * vec2(123.34, 345.45));
	p += dot(p, p + 34.345);
	return fract(p.x * p.y);
}

highp number seam_vnoise(highp vec2 p)
{
	highp vec2 i = floor(p);
	highp vec2 f = fract(p);

	highp number a = seam_hash21(i);
	highp number b = seam_hash21(i + vec2(1.0, 0.0));
	highp number c = seam_hash21(i + vec2(0.0, 1.0));
	highp number d = seam_hash21(i + vec2(1.0, 1.0));

	highp vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

highp number paint_seam_wave(highp number x, highp number y)
{
	highp vec2 p = vec2(x / 90.0, y / 38.0);

	highp number coarse = seam_vnoise(p + vec2(13.7, 4.2));
	highp number fine = seam_vnoise(p * 2.15 + vec2(-5.3, 19.1));
	highp number breakup = (coarse * 0.72 + fine * 0.28) * 2.0 - 1.0;

	highp number flow = sin(x / 54.0 + sin(y / 48.0) * 1.2) * 0.25;
	highp number drift = sin(x / 140.0 + time * 0.45) * 0.10;

	return breakup * 0.75 + flow + drift;
}

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc)
{
	vec4 base = Texel(tex, tc) * color;

	highp vec2 n = normalize(seam_normal);
	highp vec2 tangent = vec2(-n.y, n.x);

	highp vec2 p = sc - seam_point;

	highp number d = dot(p, n) * seam_side;
	highp number along = dot(p, tangent);

	highp number wave = paint_seam_wave(along, d);
	highp number warped_d = d + wave * wobble_px;

	highp number feather = max(feather_px, 0.001);
	highp number overstep = max(overstep_px, 0.0);
	highp number aa = 1.25;

	highp number mask = smoothstep(-overstep - aa, feather + aa, warped_d);

	base.a *= mask;

	if (fx_mask > 0.001)
	{
		highp vec2 uv = (sc - wipe_rect.xy) / max(wipe_rect.zw, vec2(1.0));
		return apply_fx_mask(base, clamp(uv, vec2(0.0), vec2(1.0)));
	}

	return base;
}
