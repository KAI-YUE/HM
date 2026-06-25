
extern highp vec3 _4_rad;
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

number GameID = _4_rad.z;

#pragma HM_INCLUDE "_0_lib/_1_masks/_0_dir_sweep.inc"

number colormap_red(number x)
{
	if (x < 0.0) {
		return 54.0 / 255.0;
	} else if (x < 20049.0 / 82979.0) {
		return (829.79 * x + 54.51) / 255.0;
	} else {
		return 1.0;
	}
}

number colormap_green(number x)
{
	if (x < 20049.0 / 82979.0) {
		return 0.0;
	} else if (x < 327013.0 / 810990.0) {
		return (8546482679670.0 / 10875673217.0 * x - 2064961390770.0 / 10875673217.0) / 255.0;
	} else if (x <= 1.0) {
		return (103806720.0 / 483977.0 * x + 19607415.0 / 483977.0) / 255.0;
	} else {
		return 1.0;
	}
}

number colormap_blue(number x)
{
	if (x < 0.0) {
		return 54.0 / 255.0;
	} else if (x < 7249.0 / 82979.0) {
		return (829.79 * x + 54.51) / 255.0;
	} else if (x < 20049.0 / 82979.0) {
		return 127.0 / 255.0;
	} else if (x < 327013.0 / 810990.0) {
		return (792.0224934136139 * x - 64.36479073560233) / 255.0;
	} else {
		return 1.0;
	}
}

vec4 colormap(number x)
{
	x = clamp(x, 0.0, 1.0);
	vec3 deep = vec3(0.06, 0.18, 0.10);
	vec3 mid = vec3(0.18, 0.56, 0.28);
	vec3 glow = vec3(0.78, 0.98, 0.72);
	vec3 tint = mix(deep, mid, smoothstep(0.0, 0.62, x));
	tint = mix(tint, glow, smoothstep(0.48, 1.0, x));
	return vec4(tint, 1.0);
}

number rand(vec2 n)
{
	return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

number noise(vec2 p)
{
	vec2 ip = floor(p);
	vec2 u = fract(p);
	u = u * u * (3.0 - 2.0 * u);

	number res = mix(
		mix(rand(ip), rand(ip + vec2(1.0, 0.0)), u.x),
		mix(rand(ip + vec2(0.0, 1.0)), rand(ip + vec2(1.0, 1.0)), u.x),
		u.y
	);

	return res * res;
}

number fbm(vec2 p, number t)
{
	mat2 mtx = mat2(0.80, 0.60, -0.60, 0.80);
	number f = 0.0;

	f += 0.500000 * noise(p + t); p = mtx * p * 2.02;
	f += 0.031250 * noise(p); p = mtx * p * 2.01;
	f += 0.250000 * noise(p); p = mtx * p * 2.03;
	f += 0.125000 * noise(p); p = mtx * p * 2.01;
	f += 0.062500 * noise(p); p = mtx * p * 2.04;
	f += 0.015625 * noise(p + sin(t));

	return f / 0.96875;
}

number pattern(vec2 p, number t)
{
	return fbm(p + fbm(p + fbm(p, t), t), t);
}

vec4 effect(vec4 color, Image tex0, vec2 tc, vec2 sc)
{
	vec4 base = Texel(tex0, tc);
	vec2 uv01 = ((tc * image_details) - _tex_details.xy) / _tex_details.ba;
	if (shadow) {
		return apply_fx_mask(base, uv01);
	}

	vec2 res = _tex_details.ba;
	if (base.a <= 0.0001) {
		return apply_fx_mask(base, uv01);
	}

	number tit = _4_rad.x;
	number t = _4_rad.y;
    // number t = time;
	number GameID = _4_rad.z;

	if (hovering > 0.0) {
		t *= 1.5;
		tit *= 2.0;
	} else {
		t *= 0.5;
	}
    if (position_shader_mode >= 0.5 && hovering <= 0.0) { t *= 0.5; }

	vec2 centered = uv01 - vec2(0.5);
	centered.x *= res.x / max(res.y, 1.0);

	number id_phase = GameID * 0.173;
	number swirl = 0.35 + 0.18 * sin(t * 0.7 + GameID);
	vec2 p = uv01 * 1.65;
	p += vec2(0.05 * t + id_phase, -0.03 * t + id_phase * 0.37);
	p += centered * swirl;
	p += vec2(centered.y, -centered.x) * (0.08 * tit);

	vec2 blur = vec2(0.035, 0.025);
	number shade = 0.40 * pattern(p, t + id_phase);
	shade += 0.20 * pattern(p + blur, t + id_phase);
	shade += 0.20 * pattern(p - blur, t + id_phase);
	shade += 0.20 * pattern(p + vec2(blur.x, -blur.y), t + id_phase);
	shade = smoothstep(0.18, 0.92, shade);
	vec4 mapped = colormap(shade);
	number overlay = (0.35 + 0.30 * shade) * base.a;
	vec3 rgb = mix(base.rgb, mapped.rgb, overlay);
	vec4 outc = vec4(rgb, base.a);
	return apply_fx_mask(outc, uv01);
}


#ifdef VERTEX
#pragma HM_INCLUDE "_0_lib/_0_position/_0_card_position.inc"
#endif
