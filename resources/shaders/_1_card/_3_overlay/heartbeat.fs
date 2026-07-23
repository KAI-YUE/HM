extern highp number time;
extern highp number fx_mask;

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

extern highp vec3 heartbeat;	

/* Material tuning knobs */
// extern highp number inner_edge_strength;		
const highp number inner_edge_strength = 0.5;
extern highp vec4 light_tint;				

number GameID = heartbeat.z;

vec2 get_local_uv(vec2 _tex_coords)
{
	return ((_tex_coords * image_details) - _tex_details.xy) / _tex_details.zw;
}

#pragma HM_INCLUDE "_0_lib/_1_masks/_0_dir_sweep.inc"

vec4 effect(vec4 vcolor, Image tex0, vec2 tc, vec2 sc)
{
	vec2 uv01 = ((tc * image_details) - _tex_details.xy) / _tex_details.ba;

	float t = heartbeat.y;
	float tit = t;

	if (hovering > 0.0) {
		t *= 2.0;
		tit *= 2.0;
	} else {
		t *= 0.5;
	}

	float duration = 0.7;
	float maxAlpha = 0.5;
	float maxScale = 1.8;

	float progress = mod(t, duration) / duration;
	float currentAlpha = maxAlpha * (1.0 - progress);
	float currentScale = 1.0 + (maxScale - 1.0) * progress;

	vec2 scaledUv = 0.5 + (uv01 - 0.5) / currentScale;
	scaledUv = clamp(scaledUv, 0.0, 1.0);

	vec2 scaledTc = (_tex_details.xy + scaledUv * _tex_details.ba) / image_details;

	vec4 origin = Texel(tex0, tc);
	vec4 weakMask = Texel(tex0, scaledTc);

	float ring = max(weakMask.a - origin.a, 0.0) * currentAlpha;

	vec4 outc = origin;
	outc.rgb += weakMask.rgb * ring;
	outc.a = max(origin.a, ring);

	return apply_fx_mask(outc, uv01);
}

#ifdef VERTEX
#pragma HM_INCLUDE "_0_lib/_0_position/_0_card_position.inc"
#endif
