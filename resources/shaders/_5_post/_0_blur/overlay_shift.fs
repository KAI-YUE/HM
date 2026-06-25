float Epsilon = 1e-10;

extern highp vec2 texel_size;
extern highp float blur_radius;
extern highp vec4 dim_color;

// helper: RGBToHCV
vec3 RGBToHCV(vec3 RGB)
{
    vec4 P = (RGB.g < RGB.b) ? vec4(RGB.bg, -1.0, 2.0 / 3.0) : vec4(RGB.gb, 0.0, -1.0 / 3.0);
    vec4 Q = (RGB.r < P.x) ? vec4(P.xyw, RGB.r) : vec4(RGB.r, P.yzx);
    float C = Q.x - min(Q.w, Q.y);
    float H = abs((Q.w - Q.y) / (6.0 * C + Epsilon) + Q.z);
    return vec3(H, C, Q.x);
}

// helper: HUEToRGB
vec3 HUEToRGB(float H)
{
    float R = abs(H * 6.0 - 3.0) - 1.0;
    float G = 2.0 - abs(H * 6.0 - 2.0);
    float B = 2.0 - abs(H * 6.0 - 4.0);
    return clamp(vec3(R, G, B), 0.0, 1.0);
}

// helper: HSVToRGB
vec3 HSVToRGB(vec3 HSV)
{
    vec3 RGB = HUEToRGB(HSV.x);
    return ((RGB - 1.0) * HSV.y + 1.0) * HSV.z;
}

// helper: RGBToHSV
vec3 RGBToHSV(vec3 RGB)
{
    vec3 HCV = RGBToHCV(RGB);
    float S = HCV.y / (HCV.z + Epsilon);
    return vec3(HCV.x, S, HCV.z);
}

// helper: modifyHSV
vec3 modifyHSV(vec3 color, vec3 params)
{
    vec3 result = RGBToHSV(color);
    result += params;
    return HSVToRGB(result);
}

// helper: blendOverlayChannel
float blendOverlayChannel(float base, float blend)
{
    return base < 0.5 ? (2.0 * base * blend) : (1.0 - 2.0 * (1.0 - base) * (1.0 - blend));
}

// helper: blendOverlay
vec3 blendOverlay(vec3 base, vec3 blend)
{
    return vec3(blendOverlayChannel(base.r, blend.r), blendOverlayChannel(base.g, blend.g), blendOverlayChannel(base.b, blend.b));
}

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc)
{
    vec2 shift = vec2(-blur_radius, 0.0) * texel_size;
    vec4 src1 = Texel(tex, tc);
    vec4 src2 = Texel(tex, tc + shift);

    src1.g = src1.b;
    src2.g = src2.b;

    vec3 inverted = modifyHSV(src2.rgb, vec3(0.5, 0.0, 0.0));
    vec3 c = blendOverlay(src1.rgb, inverted);
    c = mix(c, dim_color.rgb, dim_color.a);

    return vec4(c, src1.a) * color;
}
