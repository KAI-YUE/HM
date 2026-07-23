extern highp vec3 twisted;	
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

/* Material tuning knobs */
	
const highp number inner_edge_strength = 0.5;
extern highp vec4 light_tint;				

vec2 get_local_uv(vec2 _tex_coords)
{
	return ((_tex_coords * image_details) - _tex_details.xy) / _tex_details.zw;
}

number GameID = twisted.z;

#pragma HM_INCLUDE "_0_lib/_1_masks/_0_dir_sweep.inc"

/* Main */
vec4 effect(vec4 color, Image _tex, vec2 _tex_coords, vec2 screen_coords)
{
	vec4 tex = Texel(_tex, _tex_coords) * color;
	vec2 uv = get_local_uv(_tex_coords);
    number tit = twisted.r;
    number t   = twisted.g;
    if (hovering > 0.0) { t *= 2; tit *= 2; }
    else { t *= 0.5; }


    number ori_a = tex.a;

	if (!shadow) {
		/* Center controlled from Lua */
        vec2 fx_center = vec2(1, 0.5);
        fx_center += vec2( 0.015 * sin(tit * 1.7 + t * 0.11), 0.010 * cos(tit * 1.1 - t * 0.09));
        vec2 adjusted_uv = uv - fx_center;

        number low   = min(tex.r, min(tex.g, tex.b));
        number high  = max(tex.r, max(tex.g, tex.b));
        number delta = min(high, max(0.5, 1. - low));

        vec2 rotater = vec2(cos(tit*0.1221), sin(tit*0.3512));
        number angle = dot(rotater, adjusted_uv)/(length(rotater)*length(adjusted_uv));
        number fac  = 0.3*max(min(2.*sin(tit*0.1 + uv.x*3. + 3.*(1.+0.5*cos(tit*0.1))) - 1., 1.), -1.);

        number maxfac = max(2.2*fac, 0.);

        /* Inner edge darkening (inset + alpha-safe) */
        number edge_dist = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));

        /* Tunable values */
        number edge_gap = 0.001;			/* gap from edge before darkening starts */
        number edge_band_w = 0.001;		    /* width of dark band */
        number edge_soft = 0.4;			/* softness at band start */

        /* Shift distance inward so 0 starts at the inset line */
        number d_in = edge_dist - edge_gap;

        /* Build a soft band only AFTER the gap */
        number band_in = smoothstep(0.0, edge_soft, d_in);
        number band_out = 1.0 - smoothstep(0.0, edge_band_w, d_in);
        number inner_edge = max(0.0, band_in * band_out);

        number edge_mask = max(0.0, band_in * band_out) * smoothstep(0.80, 0.98, tex.a);

        /* Avoid darkening the antialiased edge fringe */
        vec3 _rgb = vec3(0.9, 0.9, 0.9);
        _rgb.r = _rgb.r + 0.1*maxfac*_rgb.r;
        _rgb.b = _rgb.b - 0.1*maxfac*_rgb.b;
        tex.rgb = mix(tex.rgb, _rgb, edge_mask);
        
	}

	return apply_fx_mask(tex, uv);
}


#ifdef VERTEX
#pragma HM_INCLUDE "_0_lib/_0_position/_0_card_position.inc"
#endif
