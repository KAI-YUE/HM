extern highp number time;
extern highp number fx_mask;
extern highp vec4 _tex_details;
extern highp vec2 image_details;
extern bool shadow;
extern highp vec4 c1;
extern highp vec4 c2;

extern highp number input_scale;
extern highp number edge_pad;
extern bool show_original;

const highp number GameID = 0.0;

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
	uv *= input_scale;

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

vec4 effect(vec4 color, Image tex0, vec2 tc, vec2 sc)
{
	vec2 uv01 = ((tc * image_details) - _tex_details.xy) / _tex_details.ba;

	if (show_original) {
		vec4 base = sample_local_repeat(tex0, uv01) * color;
		return apply_fx_mask(base, uv01);
	}

	number w1, w2, w3;
	vec2 vertex1, vertex2, vertex3;
	TriangleGrid(uv01, w1, w2, w3, vertex1, vertex2, vertex3);

	vec2 uv1 = uv01 + hash(vertex1);
	vec2 uv2 = uv01 + hash(vertex2);
	vec2 uv3 = uv01 + hash(vertex3);

	vec4 input1 = sample_local_repeat(tex0, uv1);
	vec4 input2 = sample_local_repeat(tex0, uv2);
	vec4 input3 = sample_local_repeat(tex0, uv3);

	vec4 outc = input1 * w1 + input2 * w2 + input3 * w3;
	outc *= color;

	return apply_fx_mask(outc, uv01);
}
