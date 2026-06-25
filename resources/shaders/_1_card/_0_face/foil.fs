extern highp vec3 foil;

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

number GameID = foil.z;

#pragma HM_INCLUDE "_0_lib/_1_masks/_0_dir_sweep.inc"

/* main */
vec4 effect( vec4 color, Image _tex, vec2 _tex_coords, vec2 screen_coords )
{
    vec4 tex = Texel(_tex, _tex_coords);
    vec2 uv = (((_tex_coords)*(image_details)) - _tex_details.xy)/_tex_details.ba;
    number tit = foil.r;
    number t   = foil.g;
    if (hovering > 0.0) { t *= 2; tit *= 2; }
    else { t *= 0.5; }
    vec2 adjusted_uv = uv - vec2(0.5, 0.5);
    adjusted_uv.x = adjusted_uv.x*_tex_details.b/_tex_details.a;

    number low   = min(tex.r, min(tex.g, tex.b));
    number high  = max(tex.r, max(tex.g, tex.b));
	number delta = min(high, max(0.5, 1. - low));

    number fac   = max(min(2.*sin((length(90.*adjusted_uv) + tit*2.) + 3.*(1.+0.8*cos(length(113.1121*adjusted_uv) - tit*3.121))) - 1. - max(5.-length(90.*adjusted_uv), 0.), 1.), 0.);
    vec2 rotater = vec2(cos(tit*0.1221), sin(tit*0.3512));
    number angle = dot(rotater, adjusted_uv)/(length(rotater)*length(adjusted_uv));
    number fac2  = max(min(5.*cos(t*0.3 + angle*3.14*(2.2+0.9*sin(tit*1.65 + 0.2*t))) - 4. - max(2.-length(20.*adjusted_uv), 0.), 1.), 0.);
    number fac3  = 0.3*max(min(2.*sin(tit*5. + uv.x*3. + 3.*(1.+0.5*cos(tit*7.))) - 1., 1.), -1.);
    number fac4  = 0.3*max(min(2.*sin(tit*6.66 + uv.y*3.8 + 3.*(1.+0.5*cos(tit*3.414))) - 1., 1.), -1.);

    number maxfac = max(max(fac, max(fac2, max(fac3, max(fac4, 0.0)))) + 2.2*(fac+fac2+fac3+fac4), 0.);
    if (shadow) {
        tex.a = min(tex.a, 0.3*tex.a + 0.9*min(0.5, maxfac*0.1));
        return apply_fx_mask(tex, uv);
    }

    tex.r = tex.r - delta + delta*maxfac*0.3;
    tex.g = tex.g - delta + delta*maxfac*0.3;
    tex.b = tex.b + delta*maxfac*1.9;
    tex.a = min(tex.a, 0.3*tex.a + 0.9*min(0.5, maxfac*0.1));

    return apply_fx_mask(tex,  uv);
}

#ifdef VERTEX
#pragma HM_INCLUDE "_0_lib/_0_position/_0_card_position.inc"
#endif
