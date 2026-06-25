extern highp vec3 _6_diamond;
extern highp number fx_mask;

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
const highp number contrast = 1.2;

extern highp number time;

number GameID = _6_diamond.z;

#pragma HM_INCLUDE "_0_lib/_1_masks/_0_dir_sweep.inc"

number triangleWave(number value)
{
	number hval = value * 0.5;
	return 2.0 * abs(2.0 * (hval - floor(hval + 0.5))) - 1.0;
}

vec2 rotate2(vec2 pos, number angle)
{
	number a = 3.14159 * angle;
	number sa = sin(a);
	number ca = cos(a);

	return vec2(
		ca * pos.x - sa * pos.y,
		sa * pos.x + ca * pos.y
	);
}

vec2 zoomout(vec2 p)
{
	return p * 3.14159;
}

vec2 wrap2(vec2 p)
{
	number zoomFactor = 1.5;
	number repeatFactor = 3.0;
	number radius = length(p) * zoomFactor;
	number angle = atan(p.y, p.x) * repeatFactor;
	return vec2(radius * cos(angle), radius * sin(angle));
}

vec3 gold_fx(vec2 pos, number t)
{
	vec4 gold = vec4(-0.296, 0.481, 0.349, -0.412);

	vec2 zp = wrap2(zoomout(pos));
	number xoff = triangleWave(rotate2(zp, t * 0.2).x);
	vec2 p = zp + vec2(xoff, xoff);

	number fold = triangleWave(atan(p.y, p.x) / 3.14159);

	vec4 c = gold - vec4(fold);
	c = (c + 1.0) * 0.5;
	c = vec4(c.y, c.z, c.w, c.x);

	return clamp(c.rgb, 0.0, 1.0);
}

vec3 golden_highlight(vec3 fx, number luma)
{
	number gold_mask = smoothstep(0.55, 0.92, luma);
	vec3 warm_gold = vec3(1.0, 0.84, 0.30);
	vec3 hot_gold = vec3(1.0, 0.95, 0.72);
	vec3 gold_tint = mix(warm_gold, hot_gold, smoothstep(0.72, 1.0, luma));
	return mix(fx, gold_tint, gold_mask * 0.5);
}

vec3 apply_gold_shine(vec3 base, vec3 fx, number fx_luma)
{
	number shine = smoothstep(0.40, 0.92, fx_luma);
	vec3 gold_boost = vec3(1.00, 0.82, 0.18);
	vec3 hot_boost = vec3(1.00, 0.92, 0.42);
	vec3 boost = mix(gold_boost, hot_boost, smoothstep(0.70, 1.0, fx_luma));

	number base_warmth = smoothstep(0.02, 0.28, base.r - base.b);
	vec3 metallic = base * mix(vec3(1.0), boost, 0.55 + 0.35 * shine);
	metallic += boost * fx_luma * (0.10 + 0.18 * base_warmth);

	return mix(base, metallic, shine);
}

vec4 effect(vec4 color, Image tex0, vec2 tc, vec2 sc)
{
	vec4 base = Texel(tex0, tc);
	vec2 uv01 = ((tc * image_details) - _tex_details.xy ) / _tex_details.ba;
	uv01 = uv01 - vec2(0.1, 0.1);
	if (shadow) {
		return apply_fx_mask(base, uv01);
	}

	if (base.a <= 0.0001) {
		return apply_fx_mask(base, uv01);
	}
    
    vec2 res = _tex_details.ba;

	number tit = _6_diamond.x;
	number t = _6_diamond.y;
	number on_time  = 1;
	number off_time = 0.63;
	number id_phase = hash11(GameID);
	number time_scale = mix(0.9, 1.15, hash11(GameID + 17.3));
	number sweep_phase = 6.28318530718 * hash11(GameID + 43.7);

	if (hovering > 0.0) {
		t *= 0.5;
		tit *= 2.0;
	} else {
		t *= 0.25;
		// on_time = 0.08;
	}
    if (position_shader_mode >= 0.5 && hovering <= 0.0) { t *= 0.5; }
	t = t * time_scale + sweep_phase;

	number period = on_time + off_time;
	number p = fract(t / period);              // 0..1 within the cycle
	number duty = on_time / period;            // ON fraction of the cycle

	number edge_in = 0.2;                      // faster fade-in
	number edge_out = 0.2;
	number gate_in  = smoothstep(0.0, edge_in, p);
	number gate_out = 1.0 - smoothstep(duty - edge_out, duty, p);
	number gate = gate_in * gate_out;          // 1 during ON window, 0 during OFF window (with fades)
	if (gate <= 0.001) {
		return apply_fx_mask(vec4(base.rgb, base.a), uv01);
	}

	vec2 q = uv01;
	q.y = 1.0 - q.y;

	vec2 pos = -1.0 + 2.0 * q;
	pos.x *= res.x / max(res.y, 1.0);
	pos += vec2(
		0.10 * tit + 0.05 * cos(6.28318530718 * id_phase),
		-0.04 * tit + 0.05 * sin(6.28318530718 * id_phase)
	);

	vec3 fx = gold_fx(pos, t);

	number fx_luma = dot(fx, vec3(0.299, 0.587, 0.114));
	fx = golden_highlight(fx, fx_luma);
	fx_luma = max(fx_luma, dot(fx, vec3(0.299, 0.587, 0.114)));
	vec3 shine_rgb = apply_gold_shine(base.rgb, fx, fx_luma);
	vec3 final_rgb = mix(base.rgb, shine_rgb, gate);

	vec4 outc = vec4(final_rgb, base.a);
	return apply_fx_mask(outc, uv01);
}

#ifdef VERTEX
#pragma HM_INCLUDE "_0_lib/_0_position/_0_card_position.inc"
#endif
