extern highp vec3 toon_focus;

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

number GameID = toon_focus.z;

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

// --- Helper: blur_rise
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

// --- Helper: blur_cycle
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

	number t = toon_focus.y * speed_factor / 6.28318530718;
	number phase = fract(t);
	number radius = blur_radius > 0.0 ? blur_radius : blur_severity * max(res.y, 1.0);
	number amount = blur_cycle(phase);
	number size = amount * radius / max(res.y, 1.0);

	if (size <= 0.00001) {
		return apply_fx_mask(base * color, mask_uv);
	}

	vec3 rgb = splats(tex, uv01, 0, size, res).rgb;
	rgb = 1.75 * rgb / (1.0 + rgb);

	number edge_dist = min(min(mask_uv.x, 1.0 - mask_uv.x), min(mask_uv.y, 1.0 - mask_uv.y));
	number edge_fade = smoothstep(0.0, max(size * 2.0, 0.002), edge_dist);
	number mix_amount = amount * edge_fade;
	rgb = mix(base.rgb, rgb, mix_amount);

	vec4 outc = vec4(rgb, base.a) * color;
	return apply_fx_mask(outc, mask_uv);
}


#ifdef VERTEX
#pragma HM_INCLUDE "_0_lib/_0_position/_0_card_position.inc"
#endif
