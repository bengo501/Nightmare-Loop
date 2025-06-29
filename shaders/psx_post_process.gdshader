shader_type canvas_item;

// PSX Post-Process Shader FORTE
// Aplica efeitos PSX intensos a toda a tela (incluindo UI)
// Configurações mais fortes por padrão

// SCREEN_TEXTURE precisa ser declarado como uniform para funcionar
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest, repeat_disable;

// Parâmetros principais FORTES
uniform bool enable_color_limitation : hint_default = true;
uniform int color_levels : hint_range(4, 32) = 10;  // REDUZIDO (era 24)
uniform bool enable_dithering : hint_default = true;
uniform float dither_strength : hint_range(0.0, 1.0) = 0.75;  // AUMENTADO (era 0.4)

// Parâmetros de fog/atmosfera FORTES
uniform bool enable_fog : hint_default = true;
uniform vec3 fog_color : source_color = vec3(0.15, 0.1, 0.1);  // Mais escuro
uniform float fog_strength : hint_range(0.0, 1.0) = 0.8;  // AUMENTADO
uniform float fog_distance : hint_range(10.0, 500.0) = 120.0;
uniform float fog_fade_range : hint_range(5.0, 200.0) = 60.0;

// Parâmetros de ruído FORTES
uniform bool enable_noise : hint_default = true;
uniform vec3 noise_color : source_color = vec3(0.1, 0.05, 0.05);  // Mais escuro
uniform float noise_strength : hint_range(0.0, 1.0) = 0.65;  // AUMENTADO
uniform float noise_time_fac : hint_range(0.1, 10.0) = 2.5;

// Parâmetros de contraste/brilho FORTES
uniform bool enable_contrast_boost : hint_default = true;
uniform float contrast : hint_range(0.5, 3.0) = 1.6;  // AUMENTADO
uniform float brightness : hint_range(0.2, 1.5) = 0.7;  // REDUZIDO (mais escuro)
uniform float saturation : hint_range(0.0, 2.0) = 0.5;  // REDUZIDO

// Função de dithering FORTE (Bayer 4x4)
float dither_4x4(vec2 position, float brightness) {
	int x = int(mod(position.x, 4.0));
	int y = int(mod(position.y, 4.0));
	
	// Matriz Bayer 4x4 mais intensa
	int dither_matrix[16] = int[](
		0,  8,  2, 10,
		12, 4, 14,  6,
		3, 11,  1,  9,
		15, 7, 13,  5
	);
	
	float dither_value = float(dither_matrix[y * 4 + x]) / 16.0;
	return step(dither_value * dither_strength, brightness);
}

// Função de limitação de cores FORTE
vec3 limit_colors(vec3 color, int levels) {
	// Reduz drasticamente o número de cores
	float step_size = 1.0 / float(levels - 1);
	return floor(color / step_size) * step_size;
}

// Função de ruído FORTE
float noise(vec2 uv, float time) {
	// Ruído mais pronunciado
	return fract(sin(dot(uv + time * noise_time_fac, vec2(12.9898, 78.233))) * 43758.5453) * noise_strength;
}

// Função principal
void fragment() {
	vec2 screen_uv = SCREEN_UV;
	
	// Verifica se SCREEN_TEXTURE está disponível, senão usa TEXTURE
	vec4 original_color;
	if (SCREEN_UV != vec2(0.0)) {
		original_color = texture(SCREEN_TEXTURE, screen_uv);
	} else {
		original_color = texture(TEXTURE, UV);
	}
	
	vec3 final_color = original_color.rgb;
	
	// Se a cor original for muito escura, pode indicar problema
	if (length(final_color) < 0.001) {
		// Fallback: usa cor base para debug
		final_color = vec3(0.5, 0.5, 0.5);
	}
	
	// 1. Aplicar contraste e brilho FORTES
	if (enable_contrast_boost) {
		final_color = (final_color - 0.5) * contrast + 0.5;  // Contraste
		final_color *= brightness;  // Brilho reduzido
		
		// Reduzir saturação drasticamente
		float gray = dot(final_color, vec3(0.299, 0.587, 0.114));
		final_color = mix(vec3(gray), final_color, saturation);
	}
	
	// 2. Aplicar fog FORTE
	if (enable_fog) {
		// Simula distância baseada na luminância
		float luminance = dot(final_color, vec3(0.299, 0.587, 0.114));
		float fog_factor = smoothstep(0.0, 1.0, luminance) * fog_strength;
		final_color = mix(final_color, fog_color, fog_factor);
	}
	
	// 3. Adicionar ruído FORTE
	if (enable_noise) {
		float noise_value = noise(screen_uv, TIME);
		final_color = mix(final_color, noise_color, noise_value);
	}
	
	// 4. Limitação de cores FORTE
	if (enable_color_limitation) {
		final_color = limit_colors(final_color, color_levels);
	}
	
	// 5. Dithering FORTE
	if (enable_dithering) {
		vec2 pixel_pos = screen_uv * get_viewport().get_visible_rect().size;
		float brightness_val = dot(final_color, vec3(0.299, 0.587, 0.114));
		float dither = dither_4x4(pixel_pos, brightness_val);
		
		// Aplica dithering mais agressivo
		final_color = mix(final_color * 0.5, final_color, dither);
	}
	
	// 6. Clamp final para evitar valores inválidos
	final_color = clamp(final_color, 0.0, 1.0);
	
	COLOR = vec4(final_color, original_color.a);
}
