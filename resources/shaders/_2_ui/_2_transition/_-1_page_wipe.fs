extern highp number fx_mask;
extern highp number fx_mask_dir;
extern highp number fx_mask_seed;
extern highp number time;

extern highp vec4 _tex_details;
extern highp vec2 image_details;
extern highp vec4 wipe_rect;

extern bool shadow;
extern highp vec4 c1;
extern highp vec4 c2;

extern highp vec3 generic;
number GameID = generic.z;

#pragma HM_INCLUDE "_0_lib/_1_masks/_-1_page_wipe.inc"

vec4 effect(vec4 color, Image tex, vec2 tex_coords, vec2 screen_coords)
{
    vec4 base = Texel(tex, tex_coords) * color;
    vec2 uv = (screen_coords - wipe_rect.xy) / max(wipe_rect.zw, vec2(1.0));
    return apply_fx_mask(base, clamp(uv, vec2(0.0), vec2(1.0)));
}
