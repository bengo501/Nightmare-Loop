shader_type spatial;

render_mode blend_mix, cull_back, unshaded, depth_draw_always;

uniform float fuwafuwa_speed = 1.0;
uniform float fuwafuwa_size = 0.02;

uniform vec4 ghost_color = vec4(0.4, 1.0, 0.85, 0.5); // Cor mais viva, estilo fantasma
uniform float outline_ratio = 1.2;
uniform float noise_speed = 0.4;
uniform float noise_scale = 1.0;

vec3 hsv2rgb(float h, float s, float v) {
	return (
		(clamp(abs(fract(h + vec3(0.0, 2.0, 1.0) / 3.0) * 6.0 - 3.0) - 1.0, 0.0, 1.0) - 1.0)
		* s + 1.0
	) * v;
}

float random(vec2 pos) {
	return fract(sin(dot(pos, vec2(12.9898, 78.233))) * 43758.5453);
}

void vertex() {
	vec3 v = clamp(cos(VERTEX * 6.0 + vec3(TIME * fuwafuwa_speed)) + vec3(1.0), 0.0, 1.0);
	VERTEX += NORMAL * dot(v, v) * fuwafuwa_size;
}

void fragment() {
	float outline_alpha = clamp((1.0 - dot(NORMAL, VIEW)) * outline_ratio, 0.0, 1.0);

	// Gera brilho dinâmico com base no tempo
	float dynamic_brightness = sin(TIME * noise_speed + UV.x * 10.0) * 0.2 + 0.8;

	vec3 ghost_shade = ghost_color.rgb * dynamic_brightness;

	// Adiciona mistura com brilho colorido pulsante
	vec3 glow = hsv2rgb(TIME * 0.1, 1.0, 1.0) * noise_scale * outline_alpha;

	ALBEDO = mix(glow, ghost_shade, 0.7);
	ALPHA = ghost_color.a * outline_alpha;
}
