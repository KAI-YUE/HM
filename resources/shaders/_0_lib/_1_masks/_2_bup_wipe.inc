number bup_hash11(number x)
{
	return fract(sin(x * 127.1) * 43758.5453123);
}

number bup_hash21(vec2 p)
{
	p = fract(p * vec2(123.34, 345.45));
	p += dot(p, p + 34.345);
	return fract(p.x * p.y);
}

number bup_vnoise(vec2 p)
{
	vec2 i = floor(p);
	vec2 f = fract(p);

	number a = bup_hash21(i);
	number b = bup_hash21(i + vec2(1.0, 0.0));
	number c = bup_hash21(i + vec2(0.0, 1.0));
	number d = bup_hash21(i + vec2(1.0, 1.0));

	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

number fx_sweep_up(vec2 uv, number mask, number width)
{
	number t = clamp(mask, 0.0, 1.0);
	number axis_y = fx_mask_dir < 0.0 ? 1.0 - uv.y : uv.y;

	if (t <= 0.0001) return 1.0;
	if (t >= 0.9999) return 0.0;

	number sid = 1;
	number edge_width = width * mix(0.85, 1.20, bup_hash11(sid + 13.7));
	number edge_noise = (bup_vnoise(vec2(uv.x, axis_y) * vec2(2.0, 5.0) + vec2(bup_hash11(sid + 31.1), bup_hash11(sid + 47.3)) * 8.0) - 0.5) * edge_width * 0.45;
	number edge = 1.0 - t + edge_noise;

	return 1.0 - smoothstep(edge - edge_width, edge + edge_width, axis_y);
}

vec4 apply_fx_mask(vec4 tex, vec2 uv)
{
	number cut = fx_sweep_up(uv, fx_mask, 0.2);

	vec4 outc = tex;
	outc.a *= cut;

	if (fx_mask <= 0.0001) {
		return tex;
	}

	return outc;
}
