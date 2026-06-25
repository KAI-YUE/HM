number hash11(number x)
{
	return fract(sin(x * 127.1) * 43758.5453123);
}

number hash21(vec2 p)
{
	p = fract(p * vec2(123.34, 345.45));
	p += dot(p, p + 34.345);
	return fract(p.x * p.y);
}

number vnoise(vec2 p)
{
	vec2 i = floor(p);
	vec2 f = fract(p);

	number a = hash21(i);
	number b = hash21(i + vec2(1.0, 0.0));
	number c = hash21(i + vec2(0.0, 1.0));
	number d = hash21(i + vec2(1.0, 1.0));

	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}


number angled_sweep_coord(vec2 uv, number angle)
{
	vec2 p = uv - vec2(0.5);

	vec2 line_dir = normalize(vec2(cos(angle), sin(angle)));
	
    vec2 sweep_n = line_dir;

	number max_proj = 0.5 * (abs(sweep_n.x) + abs(sweep_n.y));
	number s = 0.5 + 0.5 * dot(p, sweep_n) / max(max_proj, 0.0001);

	return clamp(s, 0.0, 1.0);
}

number separator_flow(vec2 uv, number seed)
{
	number along = uv.x * 100.0;
	number y = uv.y * 100.0;
	number h = 100.0;

	for (int k = 1; k <= 10; ++k)
	{
		number i = float(k);

		y += sin((along * i + seed * h * i) / h + tan(i + y / 70.0)) * 10.0 / i;
	}

	return (y - uv.y * 100.0) * 0.0014;
}

number separator_bleed(vec2 uv, number seed)
{
	number coarse = separator_flow(uv, seed);
	number cross = separator_flow(uv.yx + vec2(seed * 0.017, -seed * 0.011), seed + 9.43);
	number band = ceil((uv.y + coarse * 2.0) * 7.0 + hash11(seed + 5.19));
	number chunk = hash11(band + seed * 2.31) * 2.0 - 1.0;

	return coarse + cross * 0.42 + chunk * 0.010;
}

// --- Helper: page_wipe_seed
number page_wipe_seed()
{
	return abs(fx_mask_seed) > 0.0001 ? fx_mask_seed : GameID;
}

// --- Helper: horizontal_page_wipe_choose
number horizontal_page_wipe_choose(vec2 uv, number t, number sid)
{
	t = clamp(t, 0.0, 0.999);

	number w = mix(0.08, 0.14, hash11(sid + 1.13));

	number yMid = mix(0.46, 0.54, hash11(sid + 2.71));

	number dir0 = hash11(sid + 8.31) < 0.5 ? 1.0 : -1.0;
	number dir1 = hash11(sid + 9.73) < 0.5 ? 1.0 : -1.0;

	number angle = radians(40.0);
	number sweep = angled_sweep_coord(uv, angle);

	number aspect = _tex_details.z / max(_tex_details.w, 1.0);
	vec2 np = (uv - vec2(0.5)) * vec2(aspect, 1.0);
	number edge_noise = vnoise(np * 9.0 + vec2(sid * 0.37, -sid * 0.23));
	edge_noise = edge_noise * 2.0 - 1.0;
	number flow = separator_bleed(uv, sid + 21.7);
	number edge_breakup = edge_noise * mix(0.018, 0.006, smoothstep(0.0, 1.0, t));

	number s0 = dir0 > 0.0 ? sweep : 1.0 - sweep;
	number s1 = dir1 > 0.0 ? sweep : 1.0 - sweep;
	s0 = clamp(s0 + edge_breakup, 0.0, 1.0);
	s1 = clamp(s1 + edge_breakup, 0.0, 1.0);

	number split = yMid + flow;
	split = clamp(split, 0.32, 0.68);

	number correction = mix(w, -w, t);

	number phase = floor(t * 2.0);
	number step_t = t * 2.0 - phase;

	number split_blur = w * 2.75;
	number sweep_blur = w * 2.45;

	number yTransition = smoothstep(split - split_blur, split + split_blur, uv.y);

	number sweep0 = smoothstep(step_t - sweep_blur, step_t + sweep_blur, s0 + correction);
	number sweep1 = smoothstep(step_t - sweep_blur, step_t + sweep_blur, s1 + correction);

	number choose = 0.0;

	if (phase < 1.0)
	{
		choose = mix(1.0, sweep0, yTransition);
	}
	else
	{
		choose = mix(sweep1, 0.0, yTransition);
	}

	return clamp(choose, 0.0, 1.0);
}

number section_wipe_choose(vec2 uv, number t)
{
	number sid = page_wipe_seed();
	return horizontal_page_wipe_choose(uv, t, sid);
}

vec4 apply_fx_mask(vec4 tex, vec2 uv)
{
	number source_a = tex.a;

	vec4 base = vec4(
		shadow ? vec3(0.0) : tex.rgb,
		shadow ? source_a * 0.30 : source_a
	);

	number d = clamp(fx_mask, 0.0, 1.0);

	number wipe_t = min(d * d * (3.0 - 2.0 * d), 0.999);
	number choose = section_wipe_choose(uv, wipe_t);

	number aa = 1.0 / max(min(_tex_details.z, _tex_details.w), 1.0);
	number mask = smoothstep(0.0, aa * 1.5, choose);
	number reveal_alpha = 1.0 - smoothstep(0.0, 1.0, d);
	mask *= mix(0.45, 1.0, reveal_alpha);

	vec4 masked = vec4(
		shadow ? vec3(0.0) : tex.rgb,
		shadow ? source_a * mask * 0.10 : source_a * mask
	);

	number reveal = smoothstep(0.0, 0.08, d);
	return mix(base, masked, reveal);
}
