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

extern highp vec3 plain;
number GameID = plain.z;

vec2 get_local_uv(vec2 tex_coords)
{
    return ((tex_coords * image_details) - _tex_details.xy) / _tex_details.zw;
}

#pragma HM_INCLUDE "_0_lib/_1_masks/_0_dir_sweep.inc"

vec4 effect(vec4 color, Image tex, vec2 tex_coords, vec2 screen_coords)
{
    vec4 base = Texel(tex, tex_coords) * color;
    vec2 uv = get_local_uv(tex_coords);
    return apply_fx_mask(base, uv);
}
