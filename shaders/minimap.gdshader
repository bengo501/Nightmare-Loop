shader_type spatial;

uniform vec4 edge_color : source_color = vec4(0.2, 0.2, 0.2, 1.0);
uniform vec4 floor_color : source_color = vec4(0.3, 0.3, 0.3, 1.0);
uniform vec4 player_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);

void fragment() {
	// Detecta bordas
	float edge = 0.0;
	vec2 uv = UV;
	
	// Aplica cor base
	vec4 color = floor_color;
	
	// Adiciona bordas
	if (uv.x < 0.1 || uv.x > 0.9 || uv.y < 0.1 || uv.y > 0.9) {
		color = edge_color;
	}
	
	// Destaca o jogador (assumindo que está no centro)
	float dist = length(uv - vec2(0.5));
	if (dist < 0.05) {
		color = player_color;
	}
	
	ALBEDO = color.rgb;
	ALPHA = color.a;
} 