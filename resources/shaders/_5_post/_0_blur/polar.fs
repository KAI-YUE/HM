#define Strength 0.003
#define Speed 0.02

#define NoiseTiling 8.0
#define NoiseSpeed 0.5

#define PulseSpeed 2.0
#define PulseMin 1.0
#define PulseMax 2.0

#define M_PI 3.1415926535897932384626433832795

extern highp vec2 texel_size;
extern highp float blur_radius;
extern highp vec4 dim_color;
extern highp float time;

// helper: hash
vec3 hash(vec3 p)
{
    p = vec3(dot(p, vec3(127.1, 311.7, 74.7)),
             dot(p, vec3(269.5, 183.3, 246.1)),
             dot(p, vec3(113.5, 271.9, 124.6)));

    return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

// helper: noised
vec4 noised(in vec3 x)
{
    vec3 i = floor(x);
    vec3 w = fract(x);

    vec3 u = w * w * w * (w * (w * 6.0 - 15.0) + 10.0);
    vec3 du = 30.0 * w * w * (w * (w - 2.0) + 1.0);

    vec3 ga = hash(i + vec3(0.0, 0.0, 0.0));
    vec3 gb = hash(i + vec3(1.0, 0.0, 0.0));
    vec3 gc = hash(i + vec3(0.0, 1.0, 0.0));
    vec3 gd = hash(i + vec3(1.0, 1.0, 0.0));
    vec3 ge = hash(i + vec3(0.0, 0.0, 1.0));
    vec3 gf = hash(i + vec3(1.0, 0.0, 1.0));
    vec3 gg = hash(i + vec3(0.0, 1.0, 1.0));
    vec3 gh = hash(i + vec3(1.0, 1.0, 1.0));

    float va = dot(ga, w - vec3(0.0, 0.0, 0.0));
    float vb = dot(gb, w - vec3(1.0, 0.0, 0.0));
    float vc = dot(gc, w - vec3(0.0, 1.0, 0.0));
    float vd = dot(gd, w - vec3(1.0, 1.0, 0.0));
    float ve = dot(ge, w - vec3(0.0, 0.0, 1.0));
    float vf = dot(gf, w - vec3(1.0, 0.0, 1.0));
    float vg = dot(gg, w - vec3(0.0, 1.0, 1.0));
    float vh = dot(gh, w - vec3(1.0, 1.0, 1.0));

    return vec4(va + u.x * (vb - va) + u.y * (vc - va) + u.z * (ve - va) + u.x * u.y * (va - vb - vc + vd) + u.y * u.z * (va - vc - ve + vg) + u.z * u.x * (va - vb - ve + vf) + (-va + vb + vc - vd + ve - vf - vg + vh) * u.x * u.y * u.z,
                ga + u.x * (gb - ga) + u.y * (gc - ga) + u.z * (ge - ga) + u.x * u.y * (ga - gb - gc + gd) + u.y * u.z * (ga - gc - ge + gg) + u.z * u.x * (ga - gb - ge + gf) + (-ga + gb + gc - gd + ge - gf - gg + gh) * u.x * u.y * u.z +
                du * (vec3(vb, vc, ve) - va + u.yzx * vec3(va - vb - vc + vd, va - vc - ve + vg, va - vb - ve + vf) + u.zxy * vec3(va - vb - ve + vf, va - vb - vc + vd, va - vc - ve + vg) + u.yzx * u.zxy * (-va + vb + vc - vd + ve - vf - vg + vh)));
}

// helper: Rotate2dVector
vec2 Rotate2dVector(vec2 v, vec2 a)
{
    return vec2(a.x * v.x - a.y * v.y, a.y * v.x + a.x * v.y);
}

// helper: Pulse
float Pulse(float t, float noise)
{
    float p = (sin(t * PulseSpeed) + 1.0) / 2.0;
    return (p * (PulseMax - PulseMin) + PulseMin) * noise;
}

// helper: GetVector
vec2 GetVector(vec2 v, float rad, float noise)
{
    vec2 angle = vec2(cos(rad), sin(rad));
    angle *= Pulse(rad, noise);
    return Rotate2dVector(v, angle);
}

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc)
{
    vec2 resolution = 1.0 / texel_size;
    float shift_amount = Strength * max(blur_radius, 1.0);

    float div = M_PI * 2.0 / 3.0;
    float t = time * Speed;
    float i = mod(div + (t * 2.0), M_PI * 2.0);
    float j = mod((div * 2.0) + (t * 2.0), M_PI * 2.0);
    float k = mod((div * 3.0) + (t * 2.0), M_PI * 2.0);

    vec2 vec = vec2(1.0, 0.0);
    vec2 p = (-resolution + 2.0 * sc) / resolution.y * NoiseTiling;
    vec4 n = noised(vec3(p.x, p.y, time * NoiseSpeed));
    n.x = (n.x + 1.0) / 2.0;

    vec2 r_shift = GetVector(vec, i, n.x) * shift_amount;
    vec2 g_shift = GetVector(vec, j, n.x) * shift_amount;
    vec2 b_shift = GetVector(vec, k, n.x) * shift_amount;

    vec3 c;
    c.r = Texel(tex, tc + r_shift).r;
    c.g = Texel(tex, tc + g_shift).g;
    c.b = Texel(tex, tc + b_shift).b;

    c = mix(c, dim_color.rgb, dim_color.a);
    return vec4(c, 1.0) * color;
}
