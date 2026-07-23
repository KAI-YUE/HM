extern highp vec3 _5_yellow_flash;
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

number GameID = _5_yellow_flash.z;

#pragma HM_INCLUDE "_0_lib/_1_masks/_0_dir_sweep.inc"

/* main */
vec4 effect( vec4 color, Image _tex, vec2 _tex_coords, vec2 screen_coords )
{
    vec4 tex = Texel(_tex, _tex_coords);
    vec2 uv = (((_tex_coords)*(image_details)) - _tex_details.rg)/_tex_details.ba;
    if (shadow) {
        return apply_fx_mask(tex, uv);
    }

    if (tex.a <= 0.0001) {
        return apply_fx_mask(tex, uv);
    }

    number t = time + _5_yellow_flash.r*3.1;
    number on_time  = 0.2;
    number off_time = 0.65;
    
    if (hovering > 0.0) { t *= 0.5; on_time = 0.25;  }
	else { t *= 0.25; on_time = 0.08; }
    if (position_shader_mode >= 0.5 && hovering <= 0.0) { t *= 0.5; }

    number period = on_time + off_time;
    number p = fract(t / period);
    number duty = on_time / period;

    number edge = 0.06;
    number gate_in  = smoothstep(0.0, edge, p);
    number gate_out = 1.0 - smoothstep(duty - edge, duty, p);
    number gate = gate_in * gate_out;
    if (gate <= 0.001) {
        return apply_fx_mask(tex, uv);
    }

    vec2 adjusted_uv = uv - vec2(1., 1);
    number adjusted_len = length(adjusted_uv);
    number len20 = 20.0 * adjusted_len;
    number len170 = 170.0 * adjusted_len;
    number len200 = 200.0 * adjusted_len;
    number yr = _5_yellow_flash.r;
    number yg = _5_yellow_flash.g;
    number yr2 = yr * 2.0;
    number yr3 = yr * 3.121;

    number low   = min(tex.r, min(tex.g, tex.b));
    number high  = max(tex.r, max(tex.g, tex.b));
	number delta = min(high, max(0.5, 1. - low));

    number fac   = max(min( 1.2 *sin( (len170 + yr2) + 2.*(1.+0.8*cos(len200 - yr3)) ) - 1. - max(5.-len20, 0.), 1.), 0.);
    vec2 rotater = vec2(cos(yr*0.1221), sin(yr*0.3512));
    number angle = dot(rotater, adjusted_uv)/max(length(rotater)*max(adjusted_len, 0.0001), 0.0001);
    number fac2  = max(min(5.*cos(yg*300.0 + angle*3.14*(2.2+0.9*sin(yr*1.65 + 0.2*yg))) - 4. - max(2.-len20, 0.), 1.), 0.);
    number fac3  = 0.3*max(min(2.*sin(yr*445. + uv.x*3. + 3.*(1.+0.5*cos(yr*337.))) - 1., 1.), -1.);
    number fac4  = 0.3*max(min(2.*sin(yr*656.66 + uv.y*3.8 + 3.*(1.+0.5*cos(yr*443.414))) - 1., 1.), -1.);

    number maxfac = max(max(fac, max(fac2, max(fac3, max(fac4, 0.0)))) + 2.2*(fac+fac2+fac3+fac4), 0.);
    maxfac *= gate;
    
    tex.rg = tex.rg + delta*maxfac*0.2;
    tex.b = tex.b - delta*maxfac*0.6;

    vec3 old_tint = vec3(1.00, 0.95, 0.84);	/* pale warm paper */
    number old_strength = 0.40;				/* 0.05~0.15 good */
    tex.rgb = mix(tex.rgb, tex.rgb * old_tint, old_strength * tex.a);

    // tex.a = min(tex.a, 0.4*tex.a + 0.2*min(0.4, maxfac*0.2));
    tex.rgb = (tex.rgb - 0.5) * contrast + 0.5;
	tex.rgb = clamp(tex.rgb, 0.0, 1.0);

    return apply_fx_mask(tex,  uv);
}

#ifdef VERTEX
#pragma HM_INCLUDE "_0_lib/_0_position/_0_card_position.inc"
#endif
