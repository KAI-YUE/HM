extern highp vec3 grass_sway;
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

number GameID = grass_sway.z;

#pragma HM_INCLUDE "_0_lib/_1_masks/_0_dir_sweep.inc"

vec2 uv01_to_tc(vec2 uv01) {
	uv01 = clamp(uv01, vec2(0.001), vec2(0.999));
	return (uv01 * _tex_details.ba + _tex_details.xy) / image_details;
}

vec4 sample_sprite(Image tex, vec2 uv01) {
	return Texel(tex, uv01_to_tc(uv01));
}

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
	vec2 uv01 = ((tc * image_details) - _tex_details.xy) / _tex_details.ba;
	vec4 base = Texel(tex, tc);

	float time = grass_sway.y*speed;
	float idPhase1 = 6.28318530718 * hash11(GameID + 11.3);
	float idPhase2 = 6.28318530718 * hash11(GameID + 29.7);
	float idTimeScale = mix(0.92, 1.08, hash11(GameID + 47.1));
	time *= idTimeScale;

	vec2 warped_uv = uv01;

	number sway_strength = 0.1;
	number sway_freq = 4.;

	warped_uv.y += cos(uv01.x * sway_freq + time + idPhase1) * sway_strength;
	warped_uv.y += 0.25 * sway_strength * sin(uv01.x * (sway_freq * 1.8) - time * 0.7 + idPhase2);

	vec4 surfaceColor = sample_sprite(tex, warped_uv);
	float edge_dist = min(
		min(warped_uv.x, 1.0 - warped_uv.x),
		min(warped_uv.y, 1.0 - warped_uv.y)
	);
	float edge_fade = smoothstep(0.0, 0.12, edge_dist);
	if (shadow) {
		return apply_fx_mask(vec4(0.0, 0.0, 0.0, surfaceColor.a * base.a * edge_fade) * color, uv01);
	}

	vec4 outc = vec4(surfaceColor.rgb, surfaceColor.a * base.a * edge_fade) * color;

	return apply_fx_mask(outc, uv01);
}


#ifdef VERTEX
#pragma HM_INCLUDE "_0_lib/_0_position/_0_card_position.inc"
#endif
