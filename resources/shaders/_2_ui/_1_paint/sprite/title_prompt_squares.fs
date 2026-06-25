extern highp number fx_mask;
extern highp number time;
extern highp vec4 _tex_details;
extern highp vec2 image_details;
extern highp vec3 title_prompt_squares;
extern bool shadow;
extern highp number speed;
extern highp number projection;
extern highp number lift;
extern highp number density;
extern highp number brightness;
extern highp vec4 c1;
extern highp vec4 c2;
extern highp number square_scale;
extern highp number eye_open;
extern highp number eye_soft;

number GameID = title_prompt_squares.z;

#pragma HM_INCLUDE "_0_lib/_1_masks/_-2_stroke_wipe.inc"

highp vec2 sprite_local_uv(highp vec2 tex_coords)
{
    return ((tex_coords * image_details) - _tex_details.xy) / max(_tex_details.zw, vec2(0.0001));
}

highp number hash11(highp number p)
{
    p = fract(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

highp number hash21(highp vec2 p) { return hash11(p.x * 41.7 + p.y * 117.3 + GameID * 0.013); }

highp vec2 rect_alpha_variants(highp vec2 p, highp number size, highp number rnd, highp number t)
{
    highp vec2 f = fract(p) - 0.5;
    highp number x_size = size * 1.04;
    highp number y_size = size * 0.68;
    highp number x_body = 1.0 - smoothstep(x_size, x_size + 0.014, abs(f.x));
    highp number y_band = 1.0 - smoothstep(y_size * 0.62, y_size, abs(f.y));
    highp number body = x_body * y_band;

    highp number trail_y = 1.0 - smoothstep(y_size, y_size + 0.24, abs(f.y - 0.18));
    highp number trail = x_body * trail_y * smoothstep(-0.34, 0.18, f.y);
    highp number inner = 0.58 + 0.42 * (1.0 - smoothstep(0.0, y_size, abs(f.y)));
    highp number wave = 0.84 + 0.16 * sin(t * (0.9 + rnd) + f.y * 10.0 + rnd * 6.2831853);
    return vec2(max(body, trail * 0.54), inner * wave);
}

highp vec3 rect_palette(highp number rnd, highp number t)
{
    highp vec3 pearl = vec3(0.92, 0.96, 1.00);
    highp number drift = 0.5 + 0.5 * sin(t * 0.28 + rnd * 6.2831853);
    highp vec3 tint = mix(c1.rgb, c2.rgb, drift);
    return mix(tint, pearl, 0.58);
}

highp vec2 project_plane(highp vec2 uv, highp number side, highp number z)
{
    highp number proj = clamp(projection, 0.0, 1.0);
    highp number perspective = mix(1.0, 1.0 / z, proj);
    highp vec2 p = (uv - 0.5) * perspective + 0.5;

    p.x = side > 0.0 ? p.x : 1.0 - p.x;
    p.x += side * proj * (p.y - 0.5) * 0.42;
    p.y = 0.5 + (p.y - 0.5) * mix(1.0, 0.78 + 0.12*z, proj);
    return p;
}

highp number eye_mask(highp vec2 uv)
{
    highp vec2 p = uv * 2.0 - 1.0;
    highp number open = max(eye_open, 0.05);
    highp number cap = open * sqrt(max(0.0, 1.0 - p.x*p.x));
    highp number d = cap - abs(p.y);
    highp number soft = max(eye_soft, 0.001);
    return smoothstep(-soft, soft, d);
}

highp vec4 plane_layer(highp vec2 uv, highp number side, highp number layer, highp number t)
{
    highp number phase = fract(t * 0.14 + layer * 0.137);
    highp number z = mix(4.2, 0.65, phase);
    highp vec2 p = project_plane(uv, side, z);
    p.y += lift * t * 0.18 / z;

    highp vec2 grid = vec2(9.5, 3.2) * square_scale / z;
    highp vec2 gp = p * grid + vec2(layer * 0.71, layer * 0.23);
    highp vec2 cell = floor(gp);
    highp number rnd = hash21(cell + layer * 19.0 + side * 7.0);
    highp number alive = step(1.0 - 0.42 * density, rnd);
    highp number rnd2 = hash21(cell + 5.0);
    highp number size = mix(0.22, 0.46, rnd2);
    highp vec2 variants = rect_alpha_variants(gp, size, rnd, t);

    highp number side_fade = smoothstep(0.08, 0.45, p.x) * (1.0 - smoothstep(0.82, 1.06, p.x));
    highp number depth_fade = 1.0 - smoothstep(0.55, 4.4, z);
    highp number wrap_fade = smoothstep(0.0, 0.16, phase) * (1.0 - smoothstep(0.82, 1.0, phase));
    highp number blink = 0.72 + 0.28 * sin(t * (0.55 + rnd) + rnd * 6.2831853);
    highp number cell_alpha = mix(0.36, 1.0, rnd2) * blink * variants.y;
    highp number alpha = alive * variants.x * side_fade * depth_fade * wrap_fade * cell_alpha;
    highp vec3 tint = rect_palette(rnd, t) * (0.82 + 0.25 * cell_alpha);
    return vec4(tint * alpha, alpha);
}

vec4 effect(vec4 color, Image tex, vec2 tex_coords, vec2 screen_coords)
{
    highp vec2 uv = clamp(sprite_local_uv(tex_coords), vec2(0.0), vec2(1.0));

    highp number t = time * max(speed, 0.0);
    highp vec4 fx = vec4(0.0);

    fx += plane_layer(uv, -1.0, 0.70, t) * 0.95;
    fx += plane_layer(uv,  1.0, 0.92, t + 0.9) * 0.95;
    fx += plane_layer(uv, -1.0, 1.45, t + 1.7) * 0.75;
    fx += plane_layer(uv,  1.0, 1.86, t + 2.4) * 0.75;
    fx += plane_layer(uv, -1.0, 2.55, t + 3.1) * 0.55;
    fx += plane_layer(uv,  1.0, 3.20, t + 3.8) * 0.55;

    highp number mask = eye_mask(uv);
    highp number alpha = clamp(fx.a * mask * brightness, 0.0, 1.0);
    highp vec3 tint = fx.a > 0.001 ? fx.rgb / fx.a : vec3(0.92, 0.96, 1.0);
    tint = mix(tint, vec3(1.0), min(alpha * 0.38, 0.38));
    vec4 base = vec4(tint, alpha * color.a);

    return apply_fx_mask(base, uv);
}
