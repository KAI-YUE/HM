extern highp vec4 rect;
extern highp vec2 x_axis;
extern highp vec2 y_axis;
extern highp number feather_px;

extern highp number fx_mask;
extern highp number time;
extern highp vec4 _tex_details;
extern highp vec2 image_details;
extern bool shadow;
extern highp vec3 generic;
number GameID = generic.z;

#pragma HM_INCLUDE "_0_lib/_1_masks/_-2_stroke_wipe.inc"

highp vec2 bg_local_pos(highp vec2 screen_pos)
{
    highp vec2 p = screen_pos - rect.xy;
    highp number det = x_axis.x * y_axis.y - y_axis.x * x_axis.y;
    if (abs(det) < 0.00001) return p;
    return vec2(
        ( y_axis.y * p.x - y_axis.x * p.y) / det,
        (-x_axis.y * p.x + x_axis.x * p.y) / det
    );
}

vec4 effect(vec4 color, Image tex, vec2 tex_coords, vec2 screen_coords)
{
    highp vec2 lp = bg_local_pos(screen_coords);
    highp vec2 half_size = max(rect.zw * 0.5, vec2(0.0001));
    highp vec2 inner = half_size - abs(lp);
    highp number dist = min(inner.x, inner.y);

    highp number aa = max(fwidth(dist) * 1.5, 0.001);
    highp number feather = max(feather_px, aa);
    highp number alpha = smoothstep(-feather, feather, dist);

    vec4 base = Texel(tex, tex_coords) * color;
    base.a *= alpha;

    vec2 mask_uv = lp / max(rect.zw, vec2(0.0001)) + vec2(0.5);
    return apply_fx_mask(base, clamp(mask_uv, vec2(0.0), vec2(1.0)));
}
