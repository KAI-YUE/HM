extern highp number fx_mask;
extern highp number fx_mask_dir;
extern highp number fx_mask_seed;
extern highp number time;
extern highp vec4 _tex_details;
extern highp vec2 image_details;
extern highp vec4 wipe_rect;

extern bool shadow;
extern highp vec3 generic;
extern highp vec4 poly_p01;
extern highp vec4 poly_p23;
extern highp vec4 poly_p45;
extern highp vec4 poly_p67;
extern highp number point_count;
extern highp number feather_px;

number GameID = generic.z;

#pragma HM_INCLUDE "_0_lib/_1_masks/_-1_page_wipe.inc"

highp vec2 poly_point(int idx)
{
    if (idx == 0) return poly_p01.xy;
    if (idx == 1) return poly_p01.zw;
    if (idx == 2) return poly_p23.xy;
    if (idx == 3) return poly_p23.zw;
    if (idx == 4) return poly_p45.xy;
    if (idx == 5) return poly_p45.zw;
    if (idx == 6) return poly_p67.xy;
    return poly_p67.zw;
}

highp number seg_dist(highp vec2 p, highp vec2 a, highp vec2 b)
{
    highp vec2 ab = b - a;
    highp number denom = max(dot(ab, ab), 0.0001);
    highp number t = clamp(dot(p - a, ab) / denom, 0.0, 1.0);
    return length(p - (a + ab * t));
}

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc)
{
    vec4 base = Texel(tex, tc) * color;

    int count = int(clamp(floor(point_count + 0.5), 3.0, 8.0));
    highp number dist = 100000.0;

    for (int i = 0; i < 8; i++)
    {
        if (i < count)
        {
            int j = i + 1;
            if (j >= count) j = 0;
            dist = min(dist, seg_dist(sc, poly_point(i), poly_point(j)));
        }
    }

    highp number feather = max(feather_px, 0.001);
    highp number aa = max(fwidth(dist) * 1.5, 0.75);
    base.a *= smoothstep(0.0, feather + aa, dist);

    if (fx_mask > 0.001)
    {
        highp vec2 uv = (sc - wipe_rect.xy) / max(wipe_rect.zw, vec2(1.0));
        return apply_fx_mask(base, clamp(uv, vec2(0.0), vec2(1.0)));
    }

    return base;
}
