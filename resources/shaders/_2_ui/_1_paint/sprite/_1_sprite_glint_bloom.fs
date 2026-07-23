extern highp number fx_mask;
extern highp number time;
extern highp vec4 _tex_details;
extern highp vec2 image_details;
extern bool shadow;
extern highp vec3 generic;

extern highp number speed;
extern highp number speed_factor;
extern highp number wobble;
extern highp number bleed;

number GameID = generic.z;

#pragma HM_INCLUDE "_0_lib/_1_masks/_-2_stroke_wipe.inc"

highp vec2 sprite_local_uv(highp vec2 tex_coords)
{
    return ((tex_coords * image_details) - _tex_details.xy) / max(_tex_details.zw, vec2(0.0001));
}

highp vec2 atlas_sample_uv(highp vec2 tex_coords, highp vec2 offset_px)
{
    highp vec2 atlas_px = tex_coords * image_details + offset_px;
    highp vec2 min_px = _tex_details.xy + vec2(0.5);
    highp vec2 max_px = _tex_details.xy + _tex_details.zw - vec2(0.5);
    return clamp(atlas_px, min_px, max_px) / image_details;
}

highp number sigmoid_contrast(highp number v, highp number contrast, highp number mid)
{
    highp number scale_l = v / max(mid, 0.001);
    highp number scale_h = (1.0 - v) / max(1.0 - mid, 0.001);
    highp number lower = mid * scale_l * scale_l;
    highp number upper = 1.0 - (1.0 - mid) * scale_h * scale_h;
    return mix(v, v < mid ? lower : upper, contrast - 1.0);
}

highp vec3 sigmoid_contrast(highp vec3 c, highp number contrast, highp number mid)
{
    return vec3(sigmoid_contrast(c.r, contrast, mid), sigmoid_contrast(c.g, contrast, mid), sigmoid_contrast(c.b, contrast, mid));
}

vec4 soft_bloom_sample(Image tex, highp vec2 tex_coords)
{
    highp vec2 px = vec2(1.25 + bleed * 5.0);
    vec4 color = Texel(tex, tex_coords);

    for (float i = 1.0; i <= 6.0; i += 1.0)
    {
        highp number inv = 1.0 / i;
        color += Texel(tex, atlas_sample_uv(tex_coords,  vec2( px.x,  px.y) * inv));
        color += Texel(tex, atlas_sample_uv(tex_coords,  vec2(-px.x,  px.y) * inv));
        color += Texel(tex, atlas_sample_uv(tex_coords,  vec2( px.x, -px.y) * inv));
        color += Texel(tex, atlas_sample_uv(tex_coords,  vec2(-px.x, -px.y) * inv));
    }

    return color / 25.0;
}

vec4 effect(vec4 color, Image tex, vec2 tex_coords, vec2 screen_coords)
{
    vec4 base = Texel(tex, tex_coords) * color;
    if (base.a <= 0.001) return base;

    highp vec2 uv = sprite_local_uv(tex_coords);
    highp number t = time * max(speed_factor, 0.0);
    highp number pulse = sin(t * (0.8 + speed * 1.2) + GameID * 0.37) * 0.5 + 0.5;
    highp number contrast = 1.05 + 0.35 * pulse;
    highp number threshold = 0.04 + bleed * 0.08;
    highp number intensity = 0.28 + wobble * 0.42 + pulse * 0.20;

    vec4 bloom = soft_bloom_sample(tex, tex_coords) * color;
    vec4 highlight = clamp((bloom - threshold) / max(1.0 - threshold, 0.001), 0.0, 1.0);
    highp number sweep = smoothstep(0.12, 0.0, abs(uv.x - fract(t * (0.11 + speed * 0.05) + GameID * 0.017)));
    highp vec3 glint = 1.0 - (1.0 - base.rgb) * (1.0 - highlight.rgb * intensity * (0.45 + sweep * 0.55));

    base.rgb = mix(base.rgb, glint, base.a);
    base.rgb = sigmoid_contrast(base.rgb, contrast, 0.42);
    return apply_fx_mask(base, clamp(uv, vec2(0.0), vec2(1.0)));
}
