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

extern highp vec3 sand_storm;
number GameID = sand_storm.z;

vec2 get_local_uv(vec2 tex_coords)
{
    return ((tex_coords * image_details) - _tex_details.xy) / _tex_details.zw;
}

#pragma HM_INCLUDE "_0_lib/_1_masks/_0_dir_sweep.inc"


#define DUST_STEPS 7
#define DUST_FAR 10.0
#define DUST_STR 0.22

float tri(float x)
{
	return abs(fract(x) - 0.5);
}

vec3 tri3(vec3 p)
{
	return vec3(
		tri(p.z + tri(p.y)),
		tri(p.z + tri(p.x)),
		tri(p.y + tri(p.x))
	);
}

float triNoise3d(vec3 p)
{
	float z = 1.4;
	float rz = 0.0;
	vec3 bp = p;

	for (float i = 0.0; i <= 3.0; i++)
	{
		vec3 dg = tri3(bp);
		p += dg;

		bp *= 2.0;
		z *= 1.5;
		p *= 1.2;

		rz += tri(p.z + tri(p.x + tri(p.y))) / z;
		bp += 0.14;
	}

	return rz;
}

float dust_map(vec3 p, float d, float time, float phase)
{
	p.x += time * 1.15 + phase * 4.0;
	p.z += time * 0.55 + phase * 2.0;

	float ground_hug = 1.0 - smoothstep(0.0, 0.75, p.y);
	float n = triNoise3d(p * 2.2 / (d + 8.0));

	return n * ground_hug;
}

float edge_fade(vec2 uv01, float time, float phase)
{
	vec2 p = uv01 - 0.5;
	p.x *= 1.18;

	float n1 = vnoise(uv01 * 3.5 + vec2(phase * 2.7, time * 0.045));
	float n2 = vnoise(uv01 * 8.0 + vec2(-time * 0.035, phase * 4.1));
	float n = (0.68 * n1 + 0.32 * n2) - 0.5;

	float r = length(p) + n * 0.15;
	float blob = 1.0 - smoothstep(0.46, 0.73, r);

	float crop = smoothstep(0.0, 0.055, min(min(uv01.x, 1.0 - uv01.x), min(uv01.y, 1.0 - uv01.y)));
	return clamp(blob * crop, 0.0, 1.0);
}

vec4 effect(vec4 color, Image tex0, vec2 tc, vec2 sc)
{
	vec2 uv01 = ((tc * image_details) - _tex_details.xy) / _tex_details.ba;
	vec2 res = _tex_details.ba;

    uv01.y = 1 - uv01.y;

	vec4 base = Texel(tex0, tc) * color;

	float time = sand_storm.y;
	float tit = sand_storm.y;

	if (hovering > 0.0) {
		time *= 2.0;
		tit *= 2.0;
	} else {
		time *= 0.5;
	}

	float phase = hash11(sand_storm.z * 17.17 + 3.11);

	vec2 p = uv01 - 0.5;
	p.x *= res.x / res.y;

	float tilt = sand_storm.x * 2.0 - 1.0;

	vec3 ro = vec3(
		phase * 2.0 + sin(time * 0.27 + phase) * 0.15,
		0.18 + sin(time * 0.21 + phase * 4.0) * 0.05,
		-time * 0.65 + phase * 5.0
	);

	vec3 rd = normalize(vec3(
		p.x * 1.25 + tilt * 0.18,
		p.y * 1.05 - 0.18,
		1.0
	));

	float d = 0.5;
	float dust = 0.0;

	for (int i = 0; i < DUST_STEPS; i++)
	{
		vec3 pos = ro + rd * d;

		float rz = dust_map(pos, d, time, phase);
		float layer = rz * smoothstep(d, d * 1.8, DUST_FAR);

		dust += layer * DUST_STR;

		d *= 1.8;
	}

	dust = clamp(dust, 0.0, 1.0);

	float fade = edge_fade(uv01, time, phase);
	dust *= fade;

	float tint_seed = hash11(sand_storm.z * 31.37 + 9.23);
	vec3 dry_sand = vec3(0.92, 0.78, 0.55);
	vec3 red_sand = vec3(0.72, 0.46, 0.30);
	vec3 ash_sand = vec3(0.62, 0.57, 0.49);
	vec3 dust_color = mix(dry_sand, red_sand, smoothstep(0.10, 0.82, tint_seed));
	dust_color = mix(dust_color, ash_sand, 0.25 * hash11(sand_storm.z * 43.91 + 2.17));
	dust_color *= 0.92 + 0.16 * vnoise(uv01 * 2.8 + vec2(phase, time * 0.025));

	vec3 col = mix(base.rgb, dust_color, dust * 0.85);
	col += dust_color * dust * 0.18;

	vec4 out_color = vec4(col, dust * 0.85 * color.a);

	return apply_fx_mask(out_color, uv01);
}


#ifdef VERTEX
#pragma HM_INCLUDE "_0_lib/_0_position/_0_card_position.inc"
#endif
