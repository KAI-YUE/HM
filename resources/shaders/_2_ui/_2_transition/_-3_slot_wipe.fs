extern highp number fx_mask;
extern highp number fx_mask_dir;
extern highp number light_sweep;
extern highp number light_sweep_brightness;
extern highp number time;

extern highp vec4 _tex_details;
extern highp vec2 image_details;
extern highp vec4 wipe_rect;

extern bool shadow;
extern highp vec4 c1;
extern highp vec4 c2;

extern highp vec3 generic;
number GameID = generic.z;

#pragma HM_INCLUDE "_0_lib/_1_masks/_2_bup_wipe.inc"

vec4 effect(vec4 color, Image tex, vec2 tex_coords, vec2 screen_coords)
{
    vec4 base = Texel(tex, tex_coords) * color;
    vec2 uv = (screen_coords - wipe_rect.xy) / max(wipe_rect.zw, vec2(1.0));
    uv = clamp(uv, vec2(0.0), vec2(1.0));
    highp number angle_jitter = (bup_hash11(GameID + 19.7) - 0.5) * 0.32;
    highp number axis = (uv.y * (1.0 - angle_jitter) + uv.x * (3.0 + angle_jitter)) * 0.25;
    highp number center = mix(-0.18, 1.18, light_sweep);
    highp number sweep_dist = abs(axis - center);
    highp number col = (1.0 - smoothstep(0.035, 0.16, sweep_dist)) * light_sweep_brightness;
    col *= smoothstep(0.0, 0.08, light_sweep) * (1.0 - smoothstep(0.92, 1.0, light_sweep));
    return apply_fx_mask(vec4(base.rgb + vec3(col), base.a), uv);
}
