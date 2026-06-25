extern highp vec3	_10_smoke;			// x = tilt_var (mouseX-ish), y = time, z = GameID
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
number GameID = _10_smoke.z;

#pragma HM_INCLUDE "_0_lib/_1_masks/_0_dir_sweep.inc"

const float PI = 3.14159;
const float TAU = 2.0 * PI;
const vec3 _10_smoke_WHITE = vec3(0.88);
const float GAMMA = 2.2;
const vec3 INV_GAMMA = vec3(1.0 / GAMMA);

mat2 rotate2D(float a)
{
	float c = cos(a);
	float s = sin(a);
	return mat2(c, -s, s, c);
}

float _10_smoke_rand(float seed)
{
	return fract(sin(seed) * 43758.5453123);
}

float _10_smokeBase(vec2 pos)
{
	float v = clamp(pos.x * 1.5, -1.0, 1.0);
	return 1.0 - exp(-cos(v * PI * 0.5) * smoothstep(0.0, -1.0, pos.y) * 3.0);
}

vec2 swirl(vec2 center, float angle, float radius, vec2 pos)
{
	pos -= center;
	angle *= exp(-length(pos) / radius);
	pos *= rotate2D(angle);
	pos += center;
	return pos;
}

vec2 movingSwirl(vec2 start, vec2 end, float angle, float radius, float frequency, vec2 pos, float t, float angleScale, float freqScale, vec2 drift)
{
	float phase = fract((t + 10.0) * frequency * freqScale);
	float swirlAngle = angle * angleScale * (1.0 - cos(phase * TAU)) * 0.5;
	vec2 center = mix(start + drift, end + drift, phase);
	return swirl(center, swirlAngle, radius, pos);
}

vec2 swirls(vec2 pos, float t, float angleScale, float freqScale, vec2 drift)
{
	pos = movingSwirl(vec2( 0.0, -2.5), vec2( 0.3, 2.0),  5.0, 0.5, 0.10, pos, t, angleScale, freqScale, drift);
	pos = movingSwirl(vec2( 0.0, -2.5), vec2(-0.3, 2.0), -4.0, 0.5, 0.11, pos, t, angleScale, freqScale, drift);
	pos = movingSwirl(vec2( 0.2, -1.1), vec2( 0.5, 1.8),  4.5, 0.4, 0.12, pos, t, angleScale, freqScale, drift);
	pos = movingSwirl(vec2(-0.2, -1.3), vec2(-0.4, 1.2), -3.8, 0.4, 0.13, pos, t, angleScale, freqScale, drift);
	pos = movingSwirl(vec2( 0.1, -2.5), vec2(-0.3, 1.5),  4.7, 0.3, 0.14, pos, t, angleScale, freqScale, drift);
	pos = movingSwirl(vec2(-0.1, -1.4), vec2( 0.4, 1.6), -3.8, 0.3, 0.15, pos, t, angleScale, freqScale, drift);
	pos = movingSwirl(vec2( 0.0, -2.5), vec2( 0.3, 2.0),  5.0, 0.5, 0.16, pos, t, angleScale, freqScale, drift);
	pos = movingSwirl(vec2( 0.0, -2.5), vec2(-0.3, 2.0), -4.0, 0.5, 0.17, pos, t, angleScale, freqScale, drift);
	pos = movingSwirl(vec2( 0.2, -1.1), vec2( 0.5, 1.8),  4.5, 0.4, 0.18, pos, t, angleScale, freqScale, drift);
	pos = movingSwirl(vec2(-0.2, -1.3), vec2(-0.4, 1.2), -3.8, 0.4, 0.19, pos, t, angleScale, freqScale, drift);

	return pos;
}

float __10_smoke(vec2 pos, float t, float angleScale, float freqScale, vec2 drift)
{
	pos = swirls(pos, t, angleScale, freqScale, drift);
	return _10_smokeBase(pos);
}

vec4 effect(vec4 color, Image tex0, vec2 tc, vec2 sc)
{
	vec4 base = Texel(tex0, tc);
	vec2 uv01 = ((tc * image_details) - _tex_details.xy) / _tex_details.ba;
    uv01.y = 1.0 - uv01.y;
	if (shadow) {
		return apply_fx_mask(base * color, uv01);
	}

	if (base.a <= 0.0001) {
		return apply_fx_mask(base, uv01);
	}

	vec2 res = _tex_details.ba;
	vec2 fragCoord = uv01 * res;

	vec2 uv = 2.0 * (fragCoord - 0.5 * res) / max(res.y, 1.0);

    float t    = _10_smoke.y;
    number tit = _10_smoke.r;
    number on_time  = 0.50;
    number off_time = 0.2;
    if (hovering > 0.0) { t *= 0.4; tit *= 2; }
    else{
        t *= 0.2;
        // on_time = 0.08;
    }
    if (position_shader_mode >= 0.5 && hovering <= 0.0) { t *= 0.5; }

    number period = on_time + off_time;
    number p = fract(t / period);              // 0..1 within the cycle
    number duty = on_time / period;            // ON fraction of the cycle

    number edge_in = 0.2;                     // faster fade-in
    number edge_out = 0.4;                    // slower fade-out for a smoother shutoff
    number gate_in  = smoothstep(0.0, edge_in, p);
    number gate_out = 1.0 - smoothstep(duty - edge_out, duty, p);
    number gate = gate_in * gate_out;          // 1 during ON window, 0 during OFF window (with fades)
	if (gate <= 0.001) {
		return apply_fx_mask(vec4(base.rgb, base.a), uv01);
	}

	float gid0 = _10_smoke_rand(GameID * 17.13 + 0.7);
	float gid1 = _10_smoke_rand(GameID * 31.97 + 3.4);
	float gid2 = _10_smoke_rand(GameID * 47.61 + 9.1);
	float angleScale = 0.88 + 0.28 * gid0;
	float freqScale = 0.92 + 0.22 * gid1;
	vec2 swirlDrift = vec2((gid1 - 0.5) * 0.18, (gid2 - 0.5) * 0.24);
	float shadowTimeOffset = (gid0 - 0.5) * 0.35;

	// tilt: slight drift/offset
	float tilt_amt = clamp(tit, -1.0, 1.0);
	if (tilt_amt >= 0.0 && tilt_amt <= 1.0){
        tilt_amt = tilt_amt * 2.0 - 1.0;
    }
		
	uv.x += tilt_amt * 0.12;

	vec3 bg = pow(base.rgb, vec3(GAMMA));

	float _10_smokeWhite = __10_smoke(uv, t, angleScale, freqScale, swirlDrift);
	float _10_smokeShadow = __10_smoke(uv + vec2(-0.15, 0.1), t + shadowTimeOffset, angleScale, freqScale, swirlDrift);
	float _10_smokeMask  = smoothstep(0.18, 0.72, _10_smokeWhite);
	float shadowMask = smoothstep(0.20, 0.78, _10_smokeShadow);
	float _10_smokeAlpha = clamp(0.65 * _10_smokeMask + 0.10 * shadowMask, 0.0, 1.0);
	_10_smokeAlpha *= gate;

	// Composite a softer _10_smoke layer over the original sprite without reducing the sprite alpha.
	vec3 _10_smokeCol = mix(bg, _10_smoke_WHITE, _10_smokeMask);
	vec3 col = mix(bg, _10_smokeCol, _10_smokeAlpha);
	vec4 outc = vec4(pow(col, INV_GAMMA), base.a) * color;

	return apply_fx_mask(outc, uv01);
}

#ifdef VERTEX
#pragma HM_INCLUDE "_0_lib/_0_position/_0_card_position.inc"
#endif
