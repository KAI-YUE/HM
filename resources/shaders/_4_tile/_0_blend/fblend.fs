extern highp vec2 resolution;
extern highp number time;
extern highp number fx_mask;
extern highp vec4 _tex_details;
extern highp vec2 image_details;
extern bool shadow;
extern highp vec4 c1;
extern highp vec4 c2;

extern highp number input_scale;
extern highp number edge_pad;
extern highp number LightBoost;
extern highp vec2 world_phase;

const highp number GameID = 0.0;
const highp number PerspectiveCenter = 3;
const highp number PerspectiveSlope = 1.5;
const highp number Depth = 150;

#pragma HM_INCLUDE "_0_lib/_1_masks/_0_dir_sweep.inc"

vec2 hash(vec2 p)
{
	return fract(sin(p * mat2(127.1, 311.7, 269.5, 183.3)) * 43758.5453);
}

vec2 local_uv_to_tc(vec2 uv)
{
	vec2 pad = min(vec2(edge_pad), max(_tex_details.ba * 0.5 - vec2(0.5), vec2(0.0)));
	vec2 inner_size = max(_tex_details.ba - 2.0 * pad, vec2(1.0));
	return (_tex_details.xy + pad + fract(uv) * inner_size) / image_details;
}

vec4 sample_local_repeat(Image tex, vec2 uv)
{
	return Texel(tex, local_uv_to_tc(uv));
}

void TriangleGrid(
	vec2 uv,
	out number w1,
	out number w2,
	out number w3,
	out vec2 vertex1,
	out vec2 vertex2,
	out vec2 vertex3
) {
	uv *= max(input_scale, 0.001);

	const mat2 gridToSkewedGrid = mat2(
		1.0, 0.0,
		-0.57735027, 1.15470054
	);

	vec2 skewedCoord = gridToSkewedGrid * uv;
	vec2 baseId = floor(skewedCoord);
	vec3 temp = vec3(fract(skewedCoord), 0.0);
	temp.z = 1.0 - temp.x - temp.y;

	if (temp.z > 0.0) {
		w1 = temp.z;
		w2 = temp.y;
		w3 = temp.x;
		vertex1 = baseId;
		vertex2 = baseId + vec2(0.0, 1.0);
		vertex3 = baseId + vec2(1.0, 0.0);
	} else {
		w1 = -temp.z;
		w2 = 1.0 - temp.y;
		w3 = 1.0 - temp.x;
		vertex1 = baseId + vec2(1.0, 1.0);
		vertex2 = baseId + vec2(1.0, 0.0);
		vertex3 = baseId + vec2(0.0, 1.0);
	}
}

vec4 stochastic_repeat(Image tex, vec2 uv)
{
	number w1, w2, w3;
	vec2 v1, v2, v3;
	TriangleGrid(uv, w1, w2, w3, v1, v2, v3);

	vec4 s1 = sample_local_repeat(tex, uv + hash(v1));
	vec4 s2 = sample_local_repeat(tex, uv + hash(v2));
	vec4 s3 = sample_local_repeat(tex, uv + hash(v3));
	return s1 * w1 + s2 * w2 + s3 * w3;
}

vec4 fractal_texture(Image tex, vec2 uv, number depth)
{
	depth = max(depth, 1e-4);

	number lod = log(depth);
	number lod_floor = floor(lod);
	number lod_fract = lod - lod_floor;

	vec2 uv1 = uv / exp(lod_floor - 1.0);
	vec2 uv2 = uv / exp(lod_floor + 0.0);
	vec2 uv3 = uv / exp(lod_floor + 1.0);

	vec4 tex0 = stochastic_repeat(tex, uv1);
	vec4 tex1 = stochastic_repeat(tex, uv2);
	vec4 tex2 = stochastic_repeat(tex, uv3);

	return 0.5 * (tex1 + mix(tex0, tex2, lod_fract));
}

number wave(number t, number rate, number phase)
{
	return 0.5 + 0.5*sin(t*rate + phase);
}

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc)
{
	vec2 uv01 = ((tc * image_details) - _tex_details.xy) / _tex_details.ba;
    
	number z_t = time * 0.1;
    number t = time * 0.1;

	vec2 uv = sc / max(resolution, vec2(1.0, 1.0)) - 0.5;
	uv.y = -uv.y;
	number phase = dot(uv, vec2(4.0, -3.0));
	number center = PerspectiveCenter + mix(-0.22, 0.18, wave(t, 0.9, phase));
	number slope = PerspectiveSlope + mix(-0.16, 0.22, wave(t, 1.2, phase + 1.7));
	number light_boost = LightBoost * mix(0.75, 1., wave(t, 1.6, phase + 0.8));
	number perspective = 1.0 / max(abs(center - uv.y * slope), 1e-4);

    // number scale = exp(cos(z_t * 0.2) * 2.5);
	number scale = 0.9 + 0.2*cos(z_t * 0.5);
    // number scale = 0.9;

	vec2 coords = uv * perspective * scale;
	coords += world_phase;
	coords.x += (z_t + sin(z_t * 0.5) / 0.5) / 50.0;
	coords.y += 0.04 * sin(z_t * 1.4 + phase);

	number depth = length(vec3(uv, 1.0)) * scale * perspective;
	depth *= Depth / max(resolution.y, 1.0);

	vec4 outc = fractal_texture(tex, coords, depth);
	outc.rgb += vec3(light_boost * perspective);
	outc *= color;

	return apply_fx_mask(outc, uv01);
}
