extern highp vec3 circular;
extern highp number fx_mask;
extern highp number time;
extern highp vec4 _tex_details;
extern highp vec2 image_details;
extern bool shadow;
extern highp vec4 c1;
extern highp vec4 c2;
extern highp number cloud_fade;

extern highp vec2 mouse_screen_pos;
extern highp float hovering;
extern highp float hover_tilt;
extern highp float screen_scale;
extern highp float position_shader_mode;

number GameID = circular.z;

#pragma HM_INCLUDE "_0_lib/_1_masks/_0_dir_sweep.inc"

#define PI 3.14159265359
#define TAU 6.28318530718
#define SPEED 0.3
#define REVEAL_PORTION 0.1
#define STROKE_WIDTH 0.075
#define START_EDGE_WIDTH 0.1
#define START_EDGE_NOISE 0.055

vec2 safe_norm(vec2 v)
{
	float l = length(v);
	if (l < 0.0001) return vec2(0.0, -1.0);
	return v / l;
}

float spiral_wipe(vec2 uv01, vec2 forward)
{
	vec2 uv = uv01 * 2.0 - 1.0;
	vec2 n = safe_norm(uv);

	float uvDot = clamp(dot(n, forward), -1.0, 1.0);
	float uvDot90 = dot(vec2(n.y, -n.x), forward);

	float angle = acos(uvDot) / PI;

	float angle1 = (1.0 - angle) * 0.5;
	float angle2 = angle * 0.5 + 0.5;

	return mix(angle1, angle2, step(0.0, uvDot90));
}

float noisy_start_edge(vec2 uv01, float spiral, float aa)
{
	vec2 p = uv01 * vec2(9.0, 14.0) + vec2(hash11(GameID), hash11(GameID + 17.0));
	float n1 = vnoise(p);
	float n2 = vnoise(p * 2.15 + vec2(3.7, -1.9));
	float noise = (n1 * 0.65 + n2 * 0.35) - 0.5;
	float width = max(START_EDGE_WIDTH, aa);
	float threshold = noise * START_EDGE_NOISE;

	return smoothstep(threshold, threshold + width, spiral);
}

float reveal_timing(float t)
{
	return t * t ;
}

float clockwise_reveal_mask(vec2 uv01, float spiral, float amount, float aa)
{
	if (amount >= 1.0) return 1.0;

	float stroke_width = max(STROKE_WIDTH, aa);
	float start_edge = noisy_start_edge(uv01, spiral, aa);
	float sweep_edge = 1.0 - smoothstep(amount - stroke_width, amount + aa, spiral);
	return start_edge * sweep_edge;
}

vec4 effect(vec4 color, Image tex0, vec2 tc, vec2 sc)
{
	vec2 uv01 = ((tc * image_details) - _tex_details.xy) / _tex_details.ba;

	vec4 base = Texel(tex0, tc) * color;

	float reveal_clock = circular.y * 0.25 * SPEED + 0.3;
	if (hovering > 0.0) reveal_clock = hovering * SPEED;

	float start_dir = hash11(GameID) * TAU;
	vec2 forward = vec2(sin(start_dir), -cos(start_dir));

	float spiral = spiral_wipe(uv01, forward);

	float cycle = fract(reveal_clock);
	float t = reveal_timing(min(cycle / REVEAL_PORTION, 1.0));
	float edge = 1.5 / max(min(_tex_details.z, _tex_details.w), 1.0);
	float mask = clockwise_reveal_mask(uv01, spiral, t, edge);

	vec4 out_color = vec4(base.rgb, base.a * mask);

	return apply_fx_mask(out_color, uv01);
}

#ifdef VERTEX
#pragma HM_INCLUDE "_0_lib/_0_position/_0_card_position.inc"
#endif
