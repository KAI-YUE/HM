extern highp vec3 paper_sway;
extern highp number speed;

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

number GameID = paper_sway.z;

#pragma HM_INCLUDE "_0_lib/_1_masks/_0_dir_sweep.inc"

vec2 uv01_to_tc(vec2 uv01) {
	uv01 = clamp(uv01, vec2(0.001), vec2(0.999));
	return (uv01 * _tex_details.ba + _tex_details.xy) / image_details;
}

vec4 sample_sprite(Image tex, vec2 uv01) {
	if (uv01.x <= 0.0 || uv01.x >= 1.0 || uv01.y <= 0.0 || uv01.y >= 1.0) {
		return vec4(0.0);
	}
	return Texel(tex, uv01_to_tc(uv01));
}

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
	vec2 uv01 = ((tc * image_details) - _tex_details.xy) / _tex_details.ba;
	vec2 res = _tex_details.ba;
	vec4 base = Texel(tex, tc);

	const float waveFrequency = 3.0;
	const float waveAmplitude = 0.1;

	float time = paper_sway.y * 0.6 * speed;
	float idPhaseX = 6.28318530718 * hash11(GameID + 11.3);
	float idPhaseY = 6.28318530718 * hash11(GameID + 29.7);
	float idTimeScale = mix(0.92, 1.08, hash11(GameID + 47.1));
	time *= idTimeScale;

	vec2 baseUV = vec2(uv01.x, 1.0 - uv01.y);

	vec2 mainUV = baseUV;
	mainUV.x += sin(time + idPhaseX + mainUV.y * waveFrequency) * waveAmplitude;
	mainUV.y += sin(time + idPhaseY + mainUV.x * waveFrequency) * waveAmplitude;

	vec2 mouseUV = clamp(vec2(0.5) + paper_sway.xy * 0.25, 0.0, 1.0);
	vec2 mouseBaseUV = vec2(mouseUV.x, 1.0 - mouseUV.y);

	vec2 d = baseUV - mouseBaseUV;
	d.x *= res.x / max(res.y, 0.0001);

	float distortionParameter = length(d);
	float distortionIntensity = clamp(pow(distortionParameter, 2.0), 0.0, 1.0);

	vec2 differenceInUV = mainUV - baseUV;
	vec2 warpedBaseUV = baseUV + differenceInUV * distortionIntensity;

	vec2 sampleUV = vec2(warpedBaseUV.x, 1.0 - warpedBaseUV.y);
	vec4 surfaceColor = sample_sprite(tex, sampleUV);
	if (shadow) {
		return apply_fx_mask(vec4(0.0, 0.0, 0.0, surfaceColor.a * base.a) * color, uv01);
	}

	vec4 outc = vec4(surfaceColor.rgb, surfaceColor.a * base.a) * color;
	return apply_fx_mask(outc, uv01);
}

#ifdef VERTEX
#pragma HM_INCLUDE "_0_lib/_0_position/_0_card_position.inc"
#endif
