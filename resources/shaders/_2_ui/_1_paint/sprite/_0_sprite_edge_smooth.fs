extern highp number fx_mask;
extern highp number time;
extern highp vec4 _tex_details;
extern highp vec2 image_details;
extern bool shadow;
extern highp vec3 generic;

extern highp number sprite_smooth_radius;
extern highp number sprite_smooth_strength;
extern highp number sprite_smooth_threshold;

number GameID = generic.z;

#pragma HM_INCLUDE "_0_lib/_1_masks/_-2_stroke_wipe.inc"

// ----------------------------------------
// helper: sprite local uv
// ----------------------------------------
highp vec2 sprite_local_uv(highp vec2 tex_coords)
{
    return ((tex_coords * image_details) - _tex_details.xy) / max(_tex_details.zw, vec2(0.0001));
}

// ----------------------------------------
// helper: atlas sample uv
// ----------------------------------------
highp vec2 atlas_sample_uv(highp vec2 tex_coords, highp vec2 offset_px)
{
    highp vec2 atlas_px = tex_coords * image_details + offset_px;
    highp vec2 min_px = _tex_details.xy + vec2(0.5);
    highp vec2 max_px = _tex_details.xy + _tex_details.zw - vec2(0.5);
    return clamp(atlas_px, min_px, max_px) / image_details;
}

// ----------------------------------------
// helper: edge smoothed sample
// ----------------------------------------
vec4 edge_smoothed_sample(Image tex, highp vec2 tex_coords)
{
    highp number radius = max(sprite_smooth_radius, 0.0);
    highp number strength = clamp(sprite_smooth_strength, 0.0, 1.0);
    highp number threshold = clamp(sprite_smooth_threshold, 0.001, 0.999);

    vec4 center = Texel(tex, tex_coords);
    if (radius <= 0.001 || strength <= 0.001) return center;

    highp vec2 ox = vec2(radius, 0.0);
    highp vec2 oy = vec2(0.0, radius);

    vec4 s0 = center;
    vec4 s1 = Texel(tex, atlas_sample_uv(tex_coords,  ox));
    vec4 s2 = Texel(tex, atlas_sample_uv(tex_coords, -ox));
    vec4 s3 = Texel(tex, atlas_sample_uv(tex_coords,  oy));
    vec4 s4 = Texel(tex, atlas_sample_uv(tex_coords, -oy));
    vec4 s5 = Texel(tex, atlas_sample_uv(tex_coords,  ox + oy));
    vec4 s6 = Texel(tex, atlas_sample_uv(tex_coords,  ox - oy));
    vec4 s7 = Texel(tex, atlas_sample_uv(tex_coords, -ox + oy));
    vec4 s8 = Texel(tex, atlas_sample_uv(tex_coords, -ox - oy));

    highp number alpha_sum = s0.a * 4.0 + s1.a + s2.a + s3.a + s4.a + (s5.a + s6.a + s7.a + s8.a) * 0.7071;
    highp number weight_sum = 4.0 + 4.0 + 4.0 * 0.7071;
    highp number coverage = alpha_sum / weight_sum;

    highp number edge_min = min(min(min(s1.a, s2.a), min(s3.a, s4.a)), min(min(s5.a, s6.a), min(s7.a, s8.a)));
    highp number edge_max = max(max(max(s1.a, s2.a), max(s3.a, s4.a)), max(max(s5.a, s6.a), max(s7.a, s8.a)));
    highp number is_edge = smoothstep(0.001, 0.25, edge_max - edge_min);

    vec3 weighted_rgb =
        s0.rgb * s0.a * 4.0 +
        (s1.rgb * s1.a + s2.rgb * s2.a + s3.rgb * s3.a + s4.rgb * s4.a) +
        (s5.rgb * s5.a + s6.rgb * s6.a + s7.rgb * s7.a + s8.rgb * s8.a) * 0.7071;
    highp number rgb_weight = max(alpha_sum, 0.0001);
    vec3 smoothed_rgb = weighted_rgb / rgb_weight;

    highp number soft_alpha = smoothstep(threshold - 0.5, threshold + 0.5, coverage);
    highp number mix_amt = strength * is_edge;

    return vec4(mix(center.rgb, smoothed_rgb, mix_amt), mix(center.a, soft_alpha, mix_amt));
}

vec4 effect(vec4 color, Image tex, vec2 tex_coords, vec2 screen_coords)
{
    vec4 base = edge_smoothed_sample(tex, tex_coords) * color;
    vec2 mask_uv = sprite_local_uv(tex_coords);
    return apply_fx_mask(base, clamp(mask_uv, vec2(0.0), vec2(1.0)));
}
