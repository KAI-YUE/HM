#define ITER 32

extern highp vec2 texel_size;
extern highp float blur_radius;
extern highp vec4 dim_color;
extern highp float time;

// helper: srand
void srand(vec2 a, out float r)
{
    r = sin(dot(a, vec2(1233.224, 1743.335)));
}

// helper: rand
float rand(inout float r)
{
    r = fract(3712.65 * r + 0.61432);
    return (r - 0.5) * 2.0;
}

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc)
{
    vec2 resolution = 1.0 / texel_size;
    float p = blur_radius / resolution.y * (sin(time * 0.05) + 1.0);
    vec4 c = vec4(0.0);
    float r;
    vec2 rv;

    srand(tc, r);

    for (int i = 0; i < ITER; i++) {
        rv.x = rand(r);
        rv.y = rand(r);
        c += Texel(tex, tc + rv * p) / float(ITER);
    }

    c.rgb = mix(c.rgb, dim_color.rgb, dim_color.a);
    return c * color;
}
