shader_type spatial;

render_mode blend_mix, cull_back, unshaded;

// Textura principal da parede
uniform sampler2D texture_albedo;

// Cor multiplicadora
uniform vec4 color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// Transparência controlada via GDScript
uniform float fade_amount : hint_range(0.0, 1.0) = 0.0;

// Padrão mágico para dithering
const vec3 magic = vec3(0.06711056, 0.00583715, 52.9829189);

void fragment() {
	vec4 tex_color = texture(texture_albedo, UV);
	ALBEDO = tex_color.rgb * color.rgb;

	if (fade_amount > 0.0) {
		float threshold = mix(1.0, 0.0, fade_amount);
		float dither = fract(magic.z * fract(dot(FRAGCOORD.xy, magic.xy)));
		if (dither > threshold) {
			discard;
		}
	}
}
