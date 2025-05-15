shader_type canvas_item;

uniform bool is_symmetric = true;
uniform float rotation_speed = 1.0;
uniform vec4 line_color : source_color = vec4(1.0);
uniform vec4 line_outline_color : source_color = vec4(vec3(0.0), 1);
uniform float square_size_1 = 15.0;
uniform float square_size_2 = 25.0;
uniform float square_outline_thickness = 2.0;
uniform vec4 dot_color : source_color = vec4(1.0);
uniform vec4 dot_outline_color : source_color = vec4(vec3(0.0), 1.0);
uniform float dot_size = 2.0;
uniform float dot_outline_thickness = 1.0;

// Função para desenhar um quadrado sólido
float center_square(float size, float outline, vec2 pixel, vec2 uv) {
    size = round(size);
    outline = round(outline);
    
    if (is_symmetric) {
        size = size * 2.0 - 1.0;
        outline = outline * 2.0;
    }
    
    float square = step(abs(uv.x - 0.5), (size + outline) * pixel.x);
    square *= step(abs(uv.y - 0.5), (size + outline) * pixel.y);
    return square;
}

// Função para desenhar um quadrado apenas com linhas
float square_outline(float size, float thickness, vec2 pixel, vec2 uv) {
    float inner = center_square(size - thickness, 0.0, pixel, uv);
    float outer = center_square(size, 0.0, pixel, uv);
    return outer - inner;
}

// Função para mesclar camadas de cores
vec4 blend_layers(vec4 bottom, vec4 top) {
    float final_alpha = top.a + bottom.a * (1.0 - top.a);
    float safe_div = step(0.0001, final_alpha);
    vec3 final_color = (top.rgb * top.a + bottom.rgb * bottom.a * (1.0 - top.a)) / max(final_alpha, 0.0001);
    return vec4(final_color, final_alpha * safe_div);
}

void fragment() {
    float angle = TIME * rotation_speed;
    
    // Criar a matriz de rotação
    mat2 rotation_matrix = mat2(
        vec2(cos(angle), -sin(angle)),
        vec2(sin(angle), cos(angle))
    );

    // Centraliza a mira no centro do TextureRect
    vec2 uv = (FRAGCOORD.xy * SCREEN_PIXEL_SIZE) - vec2(0.5);
    uv = rotation_matrix * uv + vec2(0.5);
    vec2 pixel = SCREEN_PIXEL_SIZE / 2.0;

    // Criar os dois quadrados apenas com linhas em volta do ponto central (dot)
    float square_outer_lines = square_outline(square_size_2, square_outline_thickness, pixel, uv);
    float square_inner_lines = square_outline(square_size_1, square_outline_thickness, pixel, uv);

    // Criar o ponto central (dot)
    float center_dot_outline = center_square(dot_size, dot_outline_thickness, pixel, uv);
    float center_dot = center_square(dot_size, 0.0, pixel, uv);

    // Criar as camadas de cores para os elementos da mira
    vec4 square_layer_2 = square_outer_lines * line_color;
    vec4 square_layer_1 = square_inner_lines * line_color;
    vec4 center_dot_layer = center_dot * dot_color + (center_dot_outline - center_dot) * dot_outline_color;

    // Combinar todas as camadas
    vec4 blended_result = blend_layers(square_layer_2, square_layer_1);
    blended_result = blend_layers(blended_result, center_dot_layer);

    COLOR = blended_result;
}
