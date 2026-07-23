extern highp number fx_mask;
extern highp number time;
extern highp vec4 _tex_details;
extern highp vec2 image_details;
extern bool shadow;
extern highp vec3 generic;

extern highp vec4 gradient_color_0;
extern highp vec4 gradient_color_1;
extern highp vec2 gradient_a;
extern highp vec2 gradient_b;
extern highp number gradient_noise;

number GameID = generic.z;

#pragma HM_INCLUDE "_0_lib/_1_masks/_-2_stroke_wipe.inc"

highp vec2 sprite_local_uv(highp vec2 tex_coords)
{
    return ((tex_coords * image_details) - _tex_details.xy) / max(_tex_details.zw, vec2(0.0001));
}

highp number gradient_noise_at(highp vec2 uv)
{
    const highp vec3 magic = vec3(0.06711056, 0.00583715, 52.9829189);
    return fract(magic.z * fract(dot(uv, magic.xy)));
}

vec4 effect(vec4 color, Image tex, vec2 tex_coords, vec2 screen_coords)
{
    vec4 base = Texel(tex, tex_coords) * color;
    if (base.a <= 0.001 || shadow) return apply_fx_mask(base, clamp(sprite_local_uv(tex_coords), vec2(0.0), vec2(1.0)));

    highp vec2 uv = sprite_local_uv(tex_coords);
    highp vec2 ba = gradient_b - gradient_a;
    highp number t = dot(uv - gradient_a, ba) / max(dot(ba, ba), 0.0001);
    t = smoothstep(0.0, 1.0, clamp(t, 0.0, 1.0));

    highp vec3 rgb = mix(gradient_color_0.rgb, gradient_color_1.rgb, t);
    rgb += gradient_noise * (gradient_noise_at(screen_coords + vec2(GameID)) - 0.5);

    return apply_fx_mask(vec4(clamp(rgb, 0.0, 1.0), base.a * mix(gradient_color_0.a, gradient_color_1.a, t)), clamp(uv, vec2(0.0), vec2(1.0)));
}
