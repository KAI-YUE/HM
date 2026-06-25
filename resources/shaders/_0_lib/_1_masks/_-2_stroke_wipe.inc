vec4 apply_fx_mask(vec4 tex, vec2 uv)
{
	number source_a = tex.a;

	vec4 base = vec4(
		shadow ? vec3(0.0) : tex.rgb,
		shadow ? source_a * 0.30 : source_a
	);

	number d = clamp(fx_mask, 0.0, 1.0);
	number reveal = 1.0 - d;
	number t = reveal * reveal * (3.0 - 2.0 * reveal);

	number aa = 1.0 / max(_tex_details.z, 1.0);
	number feather = max(aa * 2.0, 0.012);
	number edge = 1.0 - smoothstep(t - feather, t + feather, uv.x);

	number fade = smoothstep(0.0, 0.10, reveal);
	number mask = clamp(edge * fade, 0.0, 1.0);

	vec4 masked = vec4(
		shadow ? vec3(0.0) : tex.rgb,
		shadow ? source_a * mask * 0.10 : source_a * mask
	);

	return mix(base, masked, smoothstep(0.0, 0.08, d));
}
