shader_type spatial;
render_mode blend_add, cull_back, unshaded, depth_draw_never;

uniform float wave_speed = 4.0;
uniform float wave_amplitude = 0.03;
uniform float glow_intensity = 2.0;
uniform float alpha_strength = 0.8;

uniform vec4 core_color : source_color = vec4(0.3, 0.8, 1.0, 1.0);
uniform float distortion_strength = 1.0;

float random(vec2 pos) {
	return fract(sin(dot(pos, vec2(12.9898,78.233))) * 43758.5453);
}

void vertex() {
	// Cria ondulação ao longo da malha, simulando pulsação
	float offset = sin(TIME * wave_speed + VERTEX.y * 10.0) * wave_amplitude;
	VERTEX += NORMAL * offset;
}

void fragment() {
	// Brilho animado ao longo do tempo
	float glow = sin(TIME * wave_speed + UV.y * 20.0) * 0.5 + 0.5;
	glow *= glow_intensity;

	// Distúrbio animado para parecer instável
	vec2 noise_uv = UV + vec2(
		sin(UV.y * 30.0 + TIME * 5.0),
		cos(UV.x * 30.0 + TIME * 5.0)
	) * 0.01 * distortion_strength;

	// Mistura entre cor base e efeito de brilho
	vec3 color = core_color.rgb * (0.6 + glow * 0.4);
	ALBEDO = color;
	ALPHA = core_color.a * (glow * alpha_strength);
}
