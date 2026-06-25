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

vec4 apply_fx_mask(vec4 tex, vec2 uv)
{
	number source_a = tex.a;
	vec4 base = vec4(
		shadow ? vec3(0.0) : tex.rgb,
		shadow ? source_a * 0.30 : source_a
	);

	number d_raw = clamp(fx_mask, 0.0, 1.0);
	number d = pow(d_raw, 0.96);
	number adjusted = (d * d * (3.0 - 2.0 * d)) * 1.02 - 0.01;

	number aspect = _tex_details.z / max(_tex_details.w, 1.0);
	vec2 p = (uv - vec2(0.5)) * vec2(aspect, 1.0);

	number n1 = vnoise(p * 8.0 + vec2(time * 0.13, -time * 0.11));
	number n2 = vnoise(p * 15.0 + vec2(-time * 0.07, time * 0.09));
	number field = 0.65 * n1 + 0.35 * n2;

	vec2 b = vec2(0.18, 0.82);
	number border_penalty = 0.0;

	if (uv.x > b.y) border_penalty += (uv.x - b.y) * (5.0 + 5.0 * d);
	if (uv.y > b.y) border_penalty += (uv.y - b.y) * (5.0 + 5.0 * d);
	if (uv.x < b.x) border_penalty += (b.x - uv.x) * (5.0 + 5.0 * d);
	if (uv.y < b.x) border_penalty += (b.x - uv.y) * (5.0 + 5.0 * d);

	number ang = hash11(GameID) * 6.28318530718;
	vec2 axis  = vec2(cos(ang), sin(ang));

	vec2 h = vec2(0.5 * aspect, 0.5);
	number max_proj = dot(abs(axis), h);
	number sweep = 0.5 + 0.5 * dot(p, axis) / max(max_proj, 0.0001);
    // number sweep = 1.0 - uv.x;

	number breakup = (field - 0.5) * 0.30;

	number res = sweep + breakup - border_penalty * d;
	res = clamp(res, 0.0, 1.0);

	if (source_a > 0.01 && !shadow && c1.a > 0.01) {
		number edge_band = 0.10 + 0.18 * (0.5 - abs(adjusted - 0.5));

		if (res < adjusted + edge_band && res > adjusted) {
			if (res < adjusted + edge_band * 0.6) {
				tex = c1;
			} else if (c2.a > 0.01) {
				tex = c2;
			}
		}
	}

	number aa = 1.0 / max(min(_tex_details.z, _tex_details.w), 1.0);
	number mask = smoothstep(adjusted - 1.5 * aa, adjusted + 1.5 * aa, res);
	number out_a = mask * (shadow ? tex.a * 0.10 : tex.a);
	vec4 masked = vec4(shadow ? vec3(0.0) : tex.rgb, out_a);

	number reveal = smoothstep(0.0, 0.08, d_raw);
	return mix(base, masked, reveal);
}
