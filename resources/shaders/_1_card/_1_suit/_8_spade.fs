extern highp vec3 _8_spade;
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
const highp number contrast = 1.2;

number GameID = _8_spade.z;

#pragma HM_INCLUDE "_0_lib/_1_masks/_0_dir_sweep.inc"

vec4 effect( vec4 color, Image _tex, vec2 _tex_coords, vec2 screen_coords )
{
    vec4 tex = Texel(_tex, _tex_coords);
    vec2 mask_uv = ((_tex_coords * image_details) - _tex_details.xy) / _tex_details.ba;
    vec2 uv = (((_tex_coords)*(image_details)) + (300)*_tex_details.rg)/_tex_details.ba;
    if (shadow) {
        return apply_fx_mask(tex, mask_uv);
    }

    if (tex.a <= 0.0001) {
        return apply_fx_mask(tex, mask_uv);
    }
    vec2 adjusted_uv = uv - vec2(0., 2.);

    number low   = min(tex.r, min(tex.g, tex.b));
    number high  = max(tex.r, max(tex.g, tex.b));
	number delta = min(high, max(0.5, 1. - low));

    number tit = _8_spade.r;
    number t   = _8_spade.g;
    
    if (hovering > 0.0) { t *= 2; tit *= 2; }
	else { t *= 0.5; }
    if (position_shader_mode >= 0.5 && hovering <= 0.0) { t *= 0.5; }

    number adjusted_len = length(adjusted_uv);
    number len20 = 20.0 * adjusted_len;
    number len70 = 70.0 * adjusted_len;
    number len100 = 100.0 * adjusted_len;
    number tit2 = tit * 2.0;
    number tit3 = tit * 3.121;
    number tit_wave = tit * 1.65 + 0.2 * t;

    number fac   = max(min( 1.5 *sin( (len70 + tit2) + 2.*(1.+0.8*cos(len100 - tit3)) ) - 1. - max(5.-len20, 0.), 1.), 0.);
    vec2 rotater = vec2(cos(tit*0.1221), sin(tit*0.3512));
    number angle = dot(rotater, adjusted_uv)/max(length(rotater)*max(adjusted_len, 0.0001), 0.0001);
    number fac2  = max(min(5.*cos(t*0.3 + angle*3.14*(2.2+0.9*sin(tit_wave))) - 4. - max(2.-len20, 0.), 1.), 0.);
    number fac3  = 0.3*max(min(2.*sin(tit*15. + uv.x*3. + 3.*(1.+0.5*cos(tit*7.))) - 1., 1.), -1.);
    number fac4  = 0.3*max(min(2.*sin(tit*16.66 + uv.y*3.8 + 3.*(1.+0.5*cos(tit*3.414))) - 1., 1.), -1.);

    number maxfac = max(max(fac, max(fac2, max(fac3, max(fac4, 0.0)))) + 2.2*(fac+fac2+fac3+fac4), 0.);
    tex.rgb = tex.rgb + delta*maxfac*0.3;

    vec3 old_tint = vec3(1.00, 0.95, 0.84);	/* pale warm paper */
    number old_strength = 0.40;				/* 0.05~0.15 good */
    tex.rgb = mix(tex.rgb, tex.rgb * old_tint, old_strength * tex.a);

    // tex.a = min(tex.a, 0.4*tex.a + 0.2*min(0.4, maxfac*0.2));
    tex.rgb = (tex.rgb - 0.5) * contrast + 0.5;
	tex.rgb = clamp(tex.rgb, 0.0, 1.0);

    return apply_fx_mask(tex, mask_uv);
}

#ifdef VERTEX
#pragma HM_INCLUDE "_0_lib/_0_position/_0_card_position.inc"
#endif
