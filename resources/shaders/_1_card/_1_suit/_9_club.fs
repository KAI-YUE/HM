extern highp vec3 _9_club;
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

number GameID = _9_club.z;

#pragma HM_INCLUDE "_0_lib/_1_masks/_0_dir_sweep.inc"

vec2 hash22(vec2 p)
{
	vec3 p3 = fract(vec3(p.xyx) * vec3(443.897, 441.423, 437.195));
	p3 += dot(p3.zxy, p3.yxz + 19.19);
	return fract(vec2(p3.x * p3.y, p3.z * p3.x)) * 2.0 - 1.0;
}

number _9_club_noise2(vec2 p)
{
	vec2 i = floor(p);
	vec2 f = fract(p);

	vec2 u = f * f * (3.0 - 2.0 * f);

	return mix(
		mix(
			dot(hash22(i + vec2(0.0, 0.0)), f - vec2(0.0, 0.0)),
			dot(hash22(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0)),
			u.x
		),
		mix(
			dot(hash22(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0)),
			dot(hash22(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0)),
			u.x
		),
		u.y
	);
}

number hash111(number x)
{
	return fract(sin(x * 127.1) * 43758.5453123);
}

vec4 render_reeds_water(vec2 uv, vec2 res, number t, number tit)
{
	const int REED_N = 56;
	const number reedW = 0.014;
	number aa_px = 1.5 / max(min(res.x, res.y), 1.0);
	number inv_tit = tit * 3.14159;
	number wind_scale = pow(uv.y + 0.5, 2.0) * 0.032;

	number recordA = 0.0;
	number recordS = 0.0;
	vec2 reedUV = vec2(0.0, 1.0);

	for (int ii = 0; ii < REED_N; ii++) {
		number i = number(ii);

		number s = hash111(i * 1.731 + 0.13);
		s = s * 1.4 - 0.2;

		number h = hash111(i * 2.417 + 0.5);
		h *= ((1.0 - uv.x) * 0.32 + 0.58);

		number wv = hash111(i * 3.191 + 0.9);
		number w = reedW * (1.0 + 0.25 * wv);

		number widthF = 0.8;
		number yh = 1.0 - max(uv.y - (h - widthF), 0.0) / widthF;
		yh = pow(max(yh, 0.0), 0.4);

		number wind = wind_scale * (sin(t + uv.x * 2.2 + inv_tit) + 1.0);

		number bentF = 1.5 * h;
		number bent1 = pow(max((uv.y - (h - bentF)), 0.0) / max(bentF, 0.0001), 4.0) * 0.1;

		number uvx = uv.x - bent1 - wind;
		number width_expand = smoothstep(0.0, 0.85, yh);
		number reed_half_width = w * mix(1.35, 0.95, width_expand) * (0.85 + 0.15 * yh);
		number edge_aa = max(aa_px, 0.55 * reed_half_width + aa_px * 0.5);
		number tip_aa = max(aa_px, 0.02 + 0.08 * h);
		number a = 1.0 - smoothstep(reed_half_width - edge_aa, reed_half_width + edge_aa, abs(uvx - s));
		a *= 1.0 - smoothstep(h - tip_aa, h + tip_aa, uv.y);

		if (abs(uvx - s) < reed_half_width + edge_aa && a > recordA) {
			reedUV.x = reedUV.x * recordA + (1.0 - recordA) * (uvx - s + reed_half_width) / max(reed_half_width * 2.0, 0.0001);
			reedUV.y = min(reedUV.y, uv.y / max(h, 0.0001));
			recordS = recordS * recordA + (1.0 - recordA) * s;
			recordA = a;
		}
	}

	vec3 col = vec3(116.0 / 255.0, 127.0 / 255.0, 133.0 / 255.0);
	vec3 col1 = vec3(182.0 / 255.0, 172.0 / 255.0, 162.0 / 255.0);

	vec2 st = uv * vec2(res.x / max(res.y, 1.0), 1.0);
	number sun = distance(st, vec2(1.5 - 0.15 * tit, 0.9));
	sun = pow(max(sun, 0.0), 1.7);

	col = mix(col, col * 1.2, sun);
	col1 = mix(col1, col1 * 1.5, sun);

	number waterMix = smoothstep(
		0.42,
		0.84,
		uv.y + 0.5 * _9_club_noise2(vec2(
			(uv.x + 0.26 * _9_club_noise2(vec2(uv.y * 24.0, 0.17 + t * 0.35))) * 3.6,
			0.33 + t * 0.10
		))
	);

	col = mix(col1, col, waterMix);

	vec3 reedCol = mix(
		vec3(185.0 / 255.0, 134.0 / 255.0, 102.0 / 255.0),
		vec3(249.0 / 255.0, 218.0 / 255.0, 179.0 / 255.0),
		0.5 + 0.5 * _9_club_noise2(vec2(recordS * 15.337, 0.1177))
	);

	reedCol = mix(reedCol, reedCol * 1.22, sun);
	col = mix(col, reedCol, recordA);

	return vec4(col, recordA);
}

vec4 effect(vec4 color, Image tex0, vec2 tc, vec2 sc)
{
	vec4 base = Texel(tex0, tc);
	vec2 uv01 = ((tc * image_details) - _tex_details.xy) / _tex_details.ba;
	uv01.y = 1 - uv01.y;
	if (shadow) {
		return apply_fx_mask(base, uv01);
	}

	if (base.a <= 0.0001) {
		return apply_fx_mask(base, uv01);
	}
    
    vec2 res = _tex_details.ba;

	number tit = _9_club.x;
	number t = _9_club.y;

	if (hovering > 0.0) {
		t *= 0.5;
		tit *= 2.0;
	} else {
		t *= 0.25;
	}
    if (position_shader_mode >= 0.5 && hovering <= 0.0) { t *= 0.5; }

	number id_phase = fract(sin(GameID * 91.731) * 43758.5453123);
	number axis_offset = 0.10;
	number gate_softness = 0.1;
	number phase_blend = 0.3;
	number phase_period = 1.0 + 0.08 * (id_phase - 0.5);
	number cycle_pos = t / phase_period;
	number phase_index = mod(floor(cycle_pos), 3.0);
	number phase_frac = fract(cycle_pos);
	number gate = 1.0;
	number gate_phase_1 = smoothstep(0.5 - axis_offset - gate_softness, 0.5 - axis_offset + gate_softness, uv01.y);
	number gate_phase_2 = 1.0 - smoothstep(0.5 + axis_offset - gate_softness, 0.5 + axis_offset + gate_softness, uv01.y);
	number gate_phase_3 = 0.0;

    if (phase_index < 0.5) {
        gate = gate_phase_1;
        if (phase_frac > 1.0 - phase_blend) {
            number mix_t = smoothstep(1.0 - phase_blend, 1.0, phase_frac);
            gate = mix(gate_phase_1, gate_phase_2, mix_t);
        }
    } else if (phase_index < 1.5) {
        gate = gate_phase_2;
        if (phase_frac > 1.0 - phase_blend) {
            number mix_t = smoothstep(1.0 - phase_blend, 1.0, phase_frac);
            gate = mix(gate_phase_2, gate_phase_3, mix_t);
        }
    } else {
        gate = gate_phase_3;
        if (phase_frac > 1.0 - phase_blend) {
            number mix_t = smoothstep(1.0 - phase_blend, 1.0, phase_frac);
            gate = mix(gate_phase_3, gate_phase_1, mix_t);
        }
    }
	

	if (gate <= 0.001) {
		return apply_fx_mask(vec4(base.rgb, base.a), uv01);
	}

	number upper_mask = smoothstep(0.58, 0.70, uv01.y);
	number lower_mask = 1.0 - smoothstep(0.30, 0.42, uv01.y);
	number center_gap_mask = smoothstep(0.08, 0.16, abs(uv01.y - 0.5));
	number axis_band = 1.0 - smoothstep(0.0, 0.055, abs(uv01.y - 0.5));
	number axis_fade = smoothstep(0.18, 0.06, abs(uv01.x - 0.5));
	number top_mask = (upper_mask + lower_mask) * center_gap_mask + 0.42 * axis_band * axis_fade;
	number center_soften = 1.0 - smoothstep(0.0, 0.28, abs(uv01.x - 0.5));
	number edge_dist = min(min(uv01.x, 1.0 - uv01.x), min(uv01.y, 1.0 - uv01.y));
	number boundary_mask = smoothstep(0.20, 0.28, edge_dist);
	number print_mask = min(top_mask, 1.0) * (0.72 + 0.28 * center_soften) * boundary_mask;
	if (print_mask <= 0.001) {
		return apply_fx_mask(vec4(base.rgb, base.a), uv01);
	}

	vec2 suit_uv = uv01;
	number gap = 0.18;
	number half_span = max(0.5 - gap, 0.0001);
	number lower_shift = 0.08;
	if (uv01.y >= 0.5) {
		suit_uv.y = clamp((uv01.y - 0.5) / half_span, 0.0, 1.0);
	} else {
		suit_uv.y = clamp((0.5 - uv01.y) / half_span - lower_shift, 0.0, 1.0);
	}
	suit_uv += vec2(0.008 * tit, 0.0);

	vec4 reeds = render_reeds_water(suit_uv, res, t, tit);
	number print_alpha = reeds.a * base.a * print_mask * 0.58 * gate;

	vec3 print_rgb = mix(base.rgb, reeds.rgb, 0.82);
	print_rgb += vec3(0.06, 0.035, 0.01) * print_mask;
	print_rgb = clamp(print_rgb, 0.0, 1.0);
	vec3 final_rgb = mix(base.rgb, print_rgb, print_alpha);

	vec4 outc = vec4(final_rgb, base.a);
	return apply_fx_mask(outc, uv01);
}


#ifdef VERTEX
#pragma HM_INCLUDE "_0_lib/_0_position/_0_card_position.inc"
#endif
