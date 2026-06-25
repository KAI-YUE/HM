extern highp vec3 _3_moon;
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
const highp number contrast = 1.1;
const vec3 moonlight_soft = vec3(0.94, 0.89, 0.70);
const vec3 moonlight_glow = vec3(1.00, 0.95, 0.78);

number GameID = _3_moon.z;

#pragma HM_INCLUDE "_0_lib/_1_masks/_0_dir_sweep.inc"

vec4 sample_repeat_sprite(Image tex0, vec2 uv01)
{
	vec2 wrapped = fract(uv01);
	vec2 tc2 = (wrapped * _tex_details.ba + _tex_details.xy) / image_details;
	return Texel(tex0, tc2);
}

vec4 effect(vec4 color, Image tex0, vec2 tc, vec2 sc)
{
	vec4 base = Texel(tex0, tc);
	vec2 uv01 = ((tc * image_details) - _tex_details.xy) / _tex_details.ba;
	if (shadow) {
		return apply_fx_mask(vec4(base.rgb, base.a), uv01);
	}

	vec2 res = _tex_details.ba;
	vec2 fragCoord = uv01 * res;

	number tit = _3_moon.x;
	number t = _3_moon.y;

    number on_time  = mix(0.80, 1.20, hash11(GameID + 101.3));
	number off_time = mix(0.24, 0.48, hash11(GameID + 149.7));

    number edge_in = 0.22;
	number edge_out = 0.24;

	if (hovering > 0.0) {
		t *= 0.7;
		tit *= 2.0;
        off_time = 0; edge_out = 0; edge_in = 0;
	} else {
		t *= 0.25;
	}
    if (position_shader_mode >= 0.5 && hovering <= 0.0) { t *= 0.5; }

	number id_phase = hash11(GameID);
	number orbit_phase = id_phase * 6.28318530718;
	number time_scale = mix(0.88, 1.18, hash11(GameID + 13.7));
	number shape_phase = 6.28318530718 * hash11(GameID + 37.1);
	number glow_phase = 6.28318530718 * hash11(GameID + 71.9);
	number t_phase = t * time_scale + orbit_phase;
	

	number period = on_time + off_time;
	number p = fract((t_phase + glow_phase) / period);
	number duty = on_time / period;
	
	number gate_in = smoothstep(0.0, edge_in, p);
	number gate_out = 1.0 - smoothstep(duty - edge_out, duty, p);
	number gate = gate_in * gate_out;
	if (gate <= 0.001 || base.a <= 0.0001) {
		return apply_fx_mask(vec4(base.rgb, base.a), uv01);
	}

	vec2 uv = (fragCoord - 0.5 * res) / max(res.y, 1.0);
	uv *= 2.0;
	uv += vec2(
		0.08 * tit + 0.05 * cos(orbit_phase),
		-0.03 * tit + 0.05 * sin(orbit_phase)
	);

	number factor = 0.0;
	number f2 = 0.0;
	number radius = 0.54;
	number sin_shape = sin(t_phase + shape_phase) * 0.05;
	vec2 rep_uv0 = uv * 0.5 + 0.5;
	number sprite_repeat_x = sample_repeat_sprite(tex0, rep_uv0).x;

	for (int i = 0; i < 10; i++) {
		number fi = number(i);
		number ang = 2.0 * 3.14159 * fi / 20.0 + orbit_phase;

		number offset = sin(ang + t_phase * 0.4 + shape_phase);
		number orbit_y = sin(t_phase + ang + glow_phase);
		number base_d = length(uv - vec2(offset, orbit_y)) + radius;

		number s0 = smoothstep(-0.16, 0.92, 1.0 - base_d);
		factor += s0;
		factor += 0.12 * smoothstep(-0.20, 0.88, 1.0 - base_d - sin_shape);
		f2 += s0;
	}
	factor += 0.1 * factor * sprite_repeat_x;

	number moon_phase = sin(t_phase * 0.5 - 0.4 + glow_phase) * 0.5 + 0.5;
	vec3 moon_tint = mix(moonlight_soft, moonlight_glow, moon_phase);
	vec3 color_out = moon_tint * factor * 0.52
		+ vec3(0.08, 0.07, 0.03);

	vec2 rep_uv1 = uv * 0.35 + vec2(0.37, 0.21);
	number sprite_glow = length(sample_repeat_sprite(tex0, rep_uv1).xyz);
	color_out += moonlight_soft * (0.10 * uv.y * factor)
		+ moonlight_glow * (0.38 * f2 * sprite_glow);
	color_out *= gate;

	number fx_mask_amt = smoothstep(0.12, 0.75, clamp(factor, 0.0, 1.2)) * gate;
	vec3 layered = base.rgb + color_out * (0.35 + 0.45 * fx_mask_amt);
	vec3 final_rgb = mix(base.rgb, layered, fx_mask_amt * base.a);

	vec4 outc = vec4(final_rgb, base.a);
	return apply_fx_mask(outc, uv01);
}


#ifdef VERTEX
#pragma HM_INCLUDE "_0_lib/_0_position/_0_card_position.inc"
#endif
