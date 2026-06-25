#define GOLDEN_ANGLE 2.39996323
#define ITERATIONS 512

extern highp vec2 texel_size;
extern highp float blur_radius; // 0.8 is recommended 
extern highp vec4 dim_color;
extern highp float time;

const float DISTORTION_ANAMORPHIC = 0.6;
const float DISTORTION_BARREL = 0.6;

// helper: rotate
vec2 rotate(vec2 vector, float angle)
{
    float s = sin(angle);
    float c = cos(angle);
    return vec2(c * vector.x - s * vector.y, s * vector.x + c * vector.y);
}

// helper: rotMatrix
mat2 rotMatrix(float angle)
{
    return mat2(cos(angle), sin(angle), -sin(angle), cos(angle));
}

// helper: GetDistOffset
vec2 GetDistOffset(vec2 uv, vec2 pxoffset)
{
    vec2 tocenter = uv + vec2(-0.5, 0.5);
    vec3 prep = normalize(vec3(tocenter.y, -tocenter.x, 0.0));

    float angle = length(tocenter) * 2.221 * DISTORTION_BARREL;
    vec3 oldoffset = vec3(pxoffset, 0.0);
    float anam = 1.0 - DISTORTION_ANAMORPHIC;
    oldoffset.x *= anam;

    vec3 rotated = oldoffset * cos(angle) + cross(prep, oldoffset) * sin(angle) + prep * dot(prep, oldoffset) * (1.0 - cos(angle));
    return rotated.xy;
}

// helper: Bokeh
vec3 Bokeh(Image tex, vec2 uv, float radius, float amount)
{
    vec3 acc = vec3(0.0);
    vec3 div = vec3(0.0);
    float r = 1.0;
    vec2 vangle = vec2(0.0, radius);
    mat2 rot = rotMatrix(GOLDEN_ANGLE);

    amount += radius * 500.0;

    for (int j = 0; j < ITERATIONS; j++) {
        r += 1.0 / r;
        vangle = rot * vangle;
        vec2 pos = GetDistOffset(uv, texel_size * (r - 1.0) * vangle);
        vec3 col = texture2D(tex, uv + pos, radius * 1.25).xyz;
        col = col * col * 1.5;
        vec3 bokeh = pow(col, vec3(9.0)) * amount + 0.4;
        acc += col * bokeh;
        div += bokeh;
    }

    return acc / max(div, vec3(0.0001));
}

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc)
{
    float radius = max(blur_radius, 0.01);
    float amount = 40.0;
    vec4 c = vec4(Bokeh(tex, tc, radius, amount), 1.0);

    c.rgb = mix(c.rgb, dim_color.rgb, dim_color.a);
    return c * color;
}
