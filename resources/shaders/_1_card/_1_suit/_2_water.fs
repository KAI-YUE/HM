extern highp vec3 _2_water;
extern highp number fx_mask;
extern highp number time;
extern highp vec4 _tex_details;
extern highp vec2 image_details;
extern bool shadow;
extern highp vec4 c1;
extern highp vec4 c2;

extern highp vec2 mouse_screen_pos;
extern highp float hovering;
extern highp float hover_tilt;
extern highp float screen_scale;
extern highp float position_shader_mode;
const highp number contrast = 1.1;
const vec3 water_fill = vec3(0.16, 0.46, 0.92);

number GameID = _2_water.z;

#pragma HM_INCLUDE "_0_lib/_1_masks/_0_dir_sweep.inc"

number sqrLength2(vec2 x)
{
	return dot(x, x);
}

vec4 sample_sprite_clamp(Image tex, vec2 uv01)
{
	uv01 = clamp(uv01, vec2(0.001), vec2(0.999));
	vec2 tc2 = (uv01 * _tex_details.ba + _tex_details.xy) / image_details;
	vec4 sample = Texel(tex, tc2);
	if (sample.a > 0.0001) {
		// Counter dark fringes from linear filtering against transparent black atlas padding.
		sample.rgb = clamp(sample.rgb / sample.a, 0.0, 1.0);
	}
	return sample;
}

number edge_protect(vec2 uv01)
{
	number edge_d = min(min(uv01.x, 1.0 - uv01.x), min(uv01.y, 1.0 - uv01.y));
	return smoothstep(0.02, 0.08, edge_d);
}

vec2 tex_to_cartesian(vec2 uv, vec2 origin)
{
	uv = 2.0 * uv - 1.0;
	uv -= origin;
	return uv;
}

vec2 cartesian_to_tex(vec2 uv, vec2 origin)
{
	uv += origin;
	return uv * 0.5 + 0.5;
}

vec2 tex_to_polar(vec2 uv, vec2 origin)
{
	uv = tex_to_cartesian(uv, origin);
	return vec2(length(uv), atan(uv.y, uv.x));
}

vec2 polar_to_tex(vec2 rt, vec2 origin)
{
	vec2 xy = vec2(rt.x * cos(rt.y), rt.x * sin(rt.y));
	return cartesian_to_tex(xy, origin);
}

vec2 get_raindrop_origin(vec2 uv)
{
	vec2 origins[15];
	origins[0] = vec2(-0.5427058957, -0.4167352024);
	origins[1] = vec2(-0.4157342902, 0.8479817999);
	origins[2] = vec2(0.8022551725, 0.3361642723);
	origins[3] = vec2(0.6362738733, -0.7584309062);
	origins[4] = vec2(-0.0357409576, 0.9024994999);
	origins[5] = vec2(-0.9007136620, 0.6781372098);
	origins[6] = vec2(0.7189383123, -0.4151052172);
	origins[7] = vec2(0.2644921082, 0.0666671797);

	int min_i = 0;
	number min_d2 = sqrLength2(uv - origins[0]);

	for (int i = 1; i < 8; i++) {
		number d2 = sqrLength2(uv - origins[i]);
		if (d2 < min_d2) {
			min_d2 = d2;
			min_i = i;
		}
	}

	return origins[min_i];
}

vec2 raindrop_transform(vec2 uv, number tt)
{
	const number RAINDROPS_AMPLITUDE = 0.0075;
	number tr = RAINDROPS_AMPLITUDE * (1.0 + sin(2.0 * 3.14159265359 * tt));
	return uv - vec2(tr, 0.0);
}

/* main */
vec4 effect(vec4 color, Image _tex, vec2 _tex_coords, vec2 screen_coords)
{
	vec4 base = Texel(_tex, _tex_coords);
	vec2 uv = ((_tex_coords * image_details) - _tex_details.xy) / _tex_details.ba;
	if (shadow) {
		return apply_fx_mask(base, uv);
	}

	if (base.a <= 0.0001) {
		return apply_fx_mask(base, uv);
	}

	number tit = _2_water.r;
	number t = _2_water.g;
    number rain_scale = 0.8;

	if (hovering > 0.0) {
		t *= 1.7;
		tit *= 2.0;
        rain_scale += 0.1;
	} else {
		t *= 0.5;
	}
    if (position_shader_mode >= 0.5 && hovering <= 0.0) { t *= 0.5; }

	vec2 uv_local = 2.0 * uv - 1.0;
	uv_local += vec2(0.03 * tit, -0.01 * tit);

	vec2 closest_origin = get_raindrop_origin(uv_local);
	number drop_dist = length(uv_local - closest_origin);
	number drop_fade = 1.0 - smoothstep(0.18, 0.65, drop_dist);

	vec2 uv_s = tex_to_polar(uv, closest_origin);
	vec2 uv_t = raindrop_transform(uv_s, rain_scale * t + 33.0 * closest_origin.x - 9.0 * closest_origin.y);
	vec2 uv_warp = polar_to_tex(uv_t, closest_origin);
	// number edge_fade = edge_protect(uv);
    number  edge_fade = 1;
	number warp_mix = edge_fade * drop_fade * 0.55;
	uv_warp = mix(uv, uv_warp, warp_mix);

	vec4 warped_tex = sample_sprite_clamp(_tex, uv_warp);
	number warped_cover = smoothstep(0.02, 0.20, warped_tex.a);
	vec3 fill_rgb = mix(water_fill, warped_tex.rgb, warped_cover);
	vec4 tex = vec4(fill_rgb, base.a);

	vec2 adjusted_uv = uv_warp;
	number adjusted_len = length(adjusted_uv);
	number len20 = 20.0 * adjusted_len;
	number len170 = 170.0 * adjusted_len;
	number len200 = 200.0 * adjusted_len;
	number tit2 = tit * 2.0;
	number tit3 = tit * 3.121;

	number low = min(tex.r, min(tex.g, tex.b));
	number high = max(tex.r, max(tex.g, tex.b));
	number delta = min(high, max(0.5, 1.0 - low));

	number fac = max(min(
		1.2 * sin((len170 + tit2) + 2.0 * (1.0 + 0.8 * cos(len200 - tit3)))
		- 1.0
		- max(5.0 - len20, 0.0),
		1.0
	), 0.0);

	vec2 rotater = vec2(cos(tit * 0.1221), sin(tit * 0.3512));
	number ang_denom = max(length(rotater) * max(adjusted_len, 0.0001), 0.0001);
	number angle = dot(rotater, adjusted_uv) / ang_denom;
	number tit_wave = tit * 1.65 + 0.2 * t;

	number fac2 = max(min(
		5.0 * cos(t * 0.3 + angle * 3.14 * (2.2 + 0.9 * sin(tit_wave)))
		- 4.0
		- max(2.0 - len20, 0.0),
		1.0
	), 0.0);

	number fac3 = 0.3 * max(min(2.0 * sin(tit * 15.0 + uv_warp.x * 3.0 + 3.0 * (1.0 + 0.5 * cos(tit * 7.0))) - 1.0, 1.0), -1.0);
	number fac4 = 0.3 * max(min(2.0 * sin(tit * 16.66 + uv_warp.y * 3.8 + 3.0 * (1.0 + 0.5 * cos(tit * 3.414))) - 1.0, 1.0), -1.0);

	number maxfac = max(
		max(fac, max(fac2, max(fac3, max(fac4, 0.0)))) + 2.2 * (fac + fac2 + fac3 + fac4),
		0.0
	);

	tex.r = tex.r - delta * maxfac * 0.3;
	tex.b = tex.b + delta * maxfac * 0.2;

	vec3 old_tint = vec3(1.00, 0.95, 0.84);
	number old_strength = 0.40;
	tex.rgb = mix(tex.rgb, tex.rgb * old_tint, old_strength * tex.a);

	tex.rgb = (tex.rgb - 0.5) * contrast + 0.5;
	tex.rgb = clamp(tex.rgb, 0.0, 1.0);
	number blend_mask = max(edge_fade * warped_cover, warp_mix);
	tex.rgb = mix(base.rgb, tex.rgb, blend_mask);
	tex.a = base.a;

	return apply_fx_mask(tex, uv);
}

#ifdef VERTEX
#pragma HM_INCLUDE "_0_lib/_0_position/_0_card_position.inc"
#endif
