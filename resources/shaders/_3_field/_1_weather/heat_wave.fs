extern highp vec3 heat_wave;

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

number GameID = heat_wave.z;

#pragma HM_INCLUDE "_0_lib/_1_masks/_0_dir_sweep.inc"

vec2 uv01_to_tc(vec2 uv01)
{
	uv01 = clamp(uv01, vec2(0.001), vec2(0.999));
	return (uv01 * _tex_details.ba + _tex_details.xy) / image_details;
}

vec4 sample_sprite(Image tex, vec2 uv01)
{
	return Texel(tex, uv01_to_tc(uv01));
}

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc)
{
	vec2 uv01 = ((tc * image_details) - _tex_details.xy) / _tex_details.ba;
	vec2 res = _tex_details.ba;
	vec2 fragCoord = uv01 * res;
	vec4 base = Texel(tex, tc);

	number speed = 3.0;
	number intensity = 0.04;
	number frequency = 4.3;
	number time = heat_wave.y;

	vec2 uv = uv01;

	uv.y *= 1.0 - intensity * 2.0;
	uv.y += intensity;

	uv.y += sin(
		fragCoord.y * frequency / res.y
		+ time * speed
	) * intensity;

	vec4 warped = sample_sprite(tex, uv);
	vec4 outc = vec4(warped.rgb, warped.a * base.a) * color;

	return apply_fx_mask(outc, uv01);
}


#ifdef VERTEX
#pragma HM_INCLUDE "_0_lib/_0_position/_0_card_position.inc"
#endif
