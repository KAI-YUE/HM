extern highp vec3 dr_sway;
extern highp number speed;

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

number GameID = dr_sway.z;

const number wrap_base_scale = 0.92;
const number wrap_strength = 0.01;
const number brightness_change_strength = 0.5;

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

number sample_sprite_alpha(Image tex, vec2 uv01) {
	return Texel(tex, uv01_to_tc(uv01)).a;
}

vec2 scale_uv(vec2 uv, number scale, vec2 center) {
	return (uv - center) / scale + center;
}

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
	vec2 uv01 = ((tc * image_details) - _tex_details.xy) / _tex_details.ba;
	vec4 base = Texel(tex, tc);

	number t = 0.5*dr_sway.y*speed;
	number idPhase0 = 6.28318530718 * hash11(GameID + 11.3);
	number idPhase1 = 6.28318530718 * hash11(GameID + 29.7);
	number idPhase2 = 6.28318530718 * hash11(GameID + 47.1);
	number idPhase3 = 6.28318530718 * hash11(GameID + 61.9);
	number idPulsePhase = 6.28318530718 * hash11(GameID + 79.3);
	number idTimeScale = mix(0.92, 1.08, hash11(GameID + 97.1));
	t *= idTimeScale;

	vec2 center = vec2(
		sin(t * 1.25 + 75.0 + idPhase0 + uv01.y * 0.5) + sin(t * 2.75 - 18.0 + idPhase1 - uv01.x * 0.25),
		sin(t * 1.75 - 125.0 + idPhase2 + uv01.x * 0.25) + sin(t * 2.25 + 4.0 + idPhase3 - uv01.y * 0.5)
	) * 0.25 + 0.5;

	vec2 mouse = clamp(vec2(0.5) + dr_sway.xy * 0.25, 0.0, 1.0);

	number z;
	if (hovering > 0.0) {
		z = 1.0 - distance(mouse, vec2(0.5));
	} else {
		z = sin((t + 234.5) * 3.0 + idPulsePhase) * wrap_strength + wrap_base_scale;
	}

	vec2 uv2 = scale_uv(uv01, z, center);
	number edge_dist = min(
		min(uv2.x, 1.0 - uv2.x),
		min(uv2.y, 1.0 - uv2.y)
	);
	number edge_fade = smoothstep(0.0, 0.1, edge_dist);
	if (shadow) {
		number warped_a = sample_sprite_alpha(tex, uv2);
		return apply_fx_mask(vec4(0.0, 0.0, 0.0, warped_a * base.a * edge_fade) * color, uv01);
	}

	vec4 warped = sample_sprite_clamp(tex, uv2);

	number vignette = 1.0 - distance(uv01, vec2(0.5));
	number vig_mix = sin(t + 80.023 + idPulsePhase) * brightness_change_strength;

	vec3 rgb = mix(warped.rgb, warped.rgb * vignette, vig_mix);
	vec4 outc = vec4(rgb, warped.a * base.a * edge_fade) * color;

	return apply_fx_mask(outc, uv01);
}

#ifdef VERTEX
#pragma HM_INCLUDE "_0_lib/_0_position/_0_card_position.inc"
#endif
