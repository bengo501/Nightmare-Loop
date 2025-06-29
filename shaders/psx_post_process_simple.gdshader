shader_type canvas_item;

// PSX Post-Process Shader SIMPLES para debug
// Versão básica para identificar problemas

// Parâmetros básicos
uniform bool enable_color_limitation : hint_default = true;
uniform int color_levels : hint_range(4, 32) = 16;
uniform bool enable_dithering : hint_default = true;
uniform float dither_strength : hint_range(0.0, 1.0) = 0.5;
uniform float brightness : hint_range(0.2, 2.0) = 1.0;
uniform float contrast : hint_range(0.5, 2.0) = 1.0;

// Função de limitação de cores
vec3 limit_colors(vec3 color, int levels) {
	float step_size = 1.0 / float(levels - 1);
	return floor(color / step_size) * step_size;
}

// Função principal SIMPLES
void fragment() {
	// Usa a textura padrão do canvas_item
	vec4 original_color = texture(TEXTURE, UV);
	vec3 final_color = original_color.rgb;
	
	// Debug: se não há cor, mostra verde
	if (length(final_color) < 0.001) {
		final_color = vec3(0.0, 1.0, 0.0); // Verde para debug
	}
	
	// Aplicar brilho e contraste básicos
	final_color = (final_color - 0.5) * contrast + 0.5;
	final_color *= brightness;
	
	// Limitação de cores básica
	if (enable_color_limitation) {
		final_color = limit_colors(final_color, color_levels);
	}
	
	// Clamp para evitar valores inválidos
	final_color = clamp(final_color, 0.0, 1.0);
	
	COLOR = vec4(final_color, original_color.a);
} 