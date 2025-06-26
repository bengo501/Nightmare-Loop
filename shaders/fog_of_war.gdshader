shader_type spatial;
render_mode depth_test_disabled, depth_draw_never, unshaded, cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform vec3 player_position : source_color = vec3(0.0, 0.0, 0.0);
uniform float reveal_radius : hint_range(1.0, 20.0) = 6.0;
uniform float fade_distance : hint_range(0.5, 10.0) = 2.0;
uniform vec4 fog_color : source_color = vec4(0.01, 0.05, 0.01, 0.95);
uniform float fog_intensity : hint_range(0.0, 1.0) = 0.9;
uniform float noise_scale : hint_range(0.1, 10.0) = 2.0;
uniform float noise_speed : hint_range(0.1, 5.0) = 1.0;
uniform sampler2D noise_texture : hint_default_white;

varying vec3 world_position;

void vertex() {
    world_position = VERTEX;
    POSITION = vec4(VERTEX, 1.0);
}

float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

void fragment() {
    // Calcula a distância do fragmento atual até o jogador
    vec3 fragment_world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
    float distance_to_player = length(fragment_world_pos.xz - player_position.xz);
    
    // Calcula o fator de revelação baseado na distância (mais abrupto)
    float reveal_factor = 1.0 - smoothstep(reveal_radius - fade_distance, reveal_radius + fade_distance * 0.5, distance_to_player);
    
    // Adiciona ruído sutil para bordas orgânicas
    vec2 noise_uv = fragment_world_pos.xz * noise_scale + TIME * noise_speed;
    float noise_value = noise(noise_uv) * 0.15;
    
    // Cria uma revelação mais dramática - só revela muito próximo do jogador
    float circle_reveal = 1.0 - step(reveal_radius, distance_to_player);
    float soft_edge = smoothstep(reveal_radius - fade_distance, reveal_radius, distance_to_player);
    
    // Combina revelação circular com transição suave
    float final_reveal = circle_reveal * (1.0 - soft_edge);
    
    // Fog muito denso fora da área revelada
    float final_alpha = (1.0 - final_reveal) * fog_intensity + noise_value * 0.1;
    final_alpha = clamp(final_alpha, 0.0, 1.0);
    
    // Cor do fog mais escura e densa
    ALBEDO = fog_color.rgb;
    ALPHA = final_alpha;
    
    // Efeito de borda sutil apenas na transição
    if (final_reveal > 0.1 && final_reveal < 0.8) {
        EMISSION = vec3(0.02, 0.08, 0.02) * (1.0 - final_reveal) * 0.3;
    }
} 