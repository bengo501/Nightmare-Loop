shader_type spatial;

// Transparência simples com mistura de cores
render_mode blend_mix, cull_back, unshaded;

uniform vec4 color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// fade_amount = 0 → opaco | fade_amount = 1 → invisível
uniform float fade_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	ALBEDO = color.rgb;
	ALPHA = 1.0 - fade_amount;
}
