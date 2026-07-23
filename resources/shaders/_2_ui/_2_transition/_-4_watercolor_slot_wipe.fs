extern highp vec4 rect;
extern highp vec2 x_axis;
extern highp vec2 y_axis;
extern highp number wave_px;
extern highp number feather_px;
extern highp number seed;
extern highp number wobble;
extern highp number bleed;

extern highp number fx_mask;
extern highp number fx_mask_dir;
extern highp number light_sweep;
extern highp number light_sweep_brightness;
extern highp number time;
extern highp vec4 _tex_details;
extern highp vec2 image_details;
extern bool shadow;
extern highp vec3 generic;
number GameID = generic.z;

#pragma HM_INCLUDE "_0_lib/_1_masks/_2_bup_wipe.inc"

highp vec2 local_pos(highp vec2 screen_pos)
{
    highp vec2 p = screen_pos - rect.xy;
    highp number det = x_axis.x * y_axis.y - y_axis.x * x_axis.y;
    if (abs(det) < 0.00001) return p;
    return vec2(
        ( y_axis.y * p.x - y_axis.x * p.y) / det,
        (-x_axis.y * p.x + x_axis.x * p.y) / det
    );
}

highp number hash21(highp vec2 p)
{
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

highp number value_noise(highp vec2 p)
{
    highp vec2 i = floor(p);
    highp vec2 f = fract(p);
    highp vec2 u = f * f * (3.0 - 2.0 * f);

    highp number a = hash21(i);
    highp number b = hash21(i + vec2(1.0, 0.0));
    highp number c = hash21(i + vec2(0.0, 1.0));
    highp number d = hash21(i + vec2(1.0, 1.0));

    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

highp number fbm(highp vec2 p)
{
    highp number v = 0.0;
    highp number a = 0.5;
    highp mat2 m = mat2(1.6, 1.2, -1.2, 1.6);

    for (int i = 0; i < 5; i++)
    {
        v += a * value_noise(p);
        p = m * p + 17.31;
        a *= 0.5;
    }

    return v;
}

highp number watercolor(highp vec2 p)
{
    p *= 5.0;

    highp vec2 q = vec2(0.0);
    q.x = fbm(p);
    q.y = fbm(p + vec2(1.0));

    highp vec2 r = vec2(0.0);
    r.x = fbm(p + q + vec2(1.7, 9.2));
    r.y = fbm(p + q + vec2(8.3, 2.8));

    return clamp(fbm(p + r), 0.0, 1.0);
}

highp number rounded_rect_sdf(highp vec2 p, highp vec2 half_size, highp number radius)
{
    radius = clamp(radius, 0.0, min(half_size.x, half_size.y) - 0.0001);
    highp vec2 q = abs(p) - (half_size - vec2(radius));
    return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
}

highp number watercolor_round_dist(highp vec2 p, highp number dist, highp number seed)
{
    highp number wave = max(wave_px, 0.0);
    highp number edge_bleed = clamp(bleed, 0.0, 10.0);
    highp number scale = max(max(rect.z, rect.w), 1.0);
    highp vec2 uv = p / scale;
    highp vec2 n = uv * 12.0 + vec2(seed * 0.071, -seed * 0.039);

    highp number broad = fbm(n);
    highp number fine = fbm(n * 2.2 + vec2(4.7, 2.1));
    highp number edge_wobble = clamp(wobble, 0.0, 20.0);
    highp number delta = ((broad - 0.48) * 0.62 + (fine - 0.5) * 0.18) * wave * edge_bleed * edge_wobble;

    return dist + clamp(delta, -wave * 1.4 * edge_bleed * edge_wobble, wave * 1.4 * edge_bleed * edge_wobble);
}

vec4 effect(vec4 color, Image tex, vec2 tex_coords, vec2 screen_coords)
{
    highp vec2 lp = local_pos(screen_coords);
    highp vec2 half_size = max(rect.zw * 0.5, vec2(0.0001));
    highp number paint_seed = seed;
    highp number corner_radius = min(min(half_size.x, half_size.y) * 0.38, 6.0);

    highp number base_dist = -rounded_rect_sdf(lp, half_size, corner_radius);
    highp number dist = watercolor_round_dist(lp, base_dist, paint_seed + 17.1);

    highp number aa = max(fwidth(dist) * 1.5, 0.001);
    highp number feather = min(feather_px, aa);
    // number feather     = 0.1;
    highp number alpha = smoothstep(-feather, feather, dist);

    highp number edge_px = 1.0;
    highp number edge = 1.0 - smoothstep(0.0, edge_px, dist);

    highp vec2 uv = lp / max(max(rect.z, rect.w), 1.0);
    highp number wash = watercolor(uv * 3.2 + vec2(paint_seed * 0.017, -paint_seed * 0.023));
    highp number grain = fbm(uv * 34.0 + vec2(paint_seed, paint_seed * 0.37));
    highp vec3 stained = color.rgb * (0.94 + 0.10 * wash - 0.025 * grain);
    highp vec3 edge_rgb = mix(color.rgb, stained, edge);

    vec2 mask_uv = lp / max(rect.zw, vec2(0.0001)) + vec2(0.5);
    mask_uv = clamp(mask_uv, vec2(0.0), vec2(1.0));
    highp number angle_jitter = (bup_hash11(GameID + 19.7) - 0.5) * 0.52;
    highp number axis = (mask_uv.y * (1.0 - angle_jitter) + mask_uv.x * (3.0 + angle_jitter)) * 0.25;
    highp number center = mix(-0.18, 1.18, light_sweep);
    highp number sweep_dist = abs(axis - center);
    highp number col = (1.0 - smoothstep(0.035, 0.16, sweep_dist)) * light_sweep_brightness;
    col *= smoothstep(0.0, 0.08, light_sweep) * (1.0 - smoothstep(0.92, 1.0, light_sweep));

    vec4 base = vec4(edge_rgb + vec3(col), color.a * alpha);
    return apply_fx_mask(base, mask_uv);
}
