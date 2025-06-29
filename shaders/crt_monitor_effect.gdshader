shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float wiggle_strength : hint_range(0.0, 10.0) = 0.5;
uniform float wiggle_speed : hint_range(0.1, 5.0) = 0.8;
uniform float chromatic_aberration : hint_range(0.0, 0.01) = 0.001;
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.2;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.15;
uniform float brightness : hint_range(0.5, 2.0) = 1.0;

vec2 wiggle(vec2 uv, float time) {
    float wiggle_amount = sin(time * wiggle_speed) * wiggle_strength * 0.0005;
    uv.x += sin(uv.y * 600.0 + time * wiggle_speed * 8.0) * wiggle_amount;
    uv.y += sin(uv.x * 400.0 + time * wiggle_speed * 6.0) * wiggle_amount * 0.3;
    return uv;
}

vec3 chromatic_shift(sampler2D tex, vec2 uv) {
    vec2 offset = vec2(chromatic_aberration, 0.0);
    float r = texture(tex, uv - offset).r;
    float g = texture(tex, uv).g;
    float b = texture(tex, uv + offset).b;
    return vec3(r, g, b);
}

float scanlines(vec2 uv) {
    float scanline = sin(uv.y * 600.0) * 0.5 + 0.5;
    return mix(1.0, scanline, scanline_intensity);
}

float vignette(vec2 uv) {
    vec2 center = uv - 0.5;
    float dist = length(center);
    return 1.0 - smoothstep(0.4, 0.9, dist * vignette_strength);
}

void fragment() {
    vec2 iResolution = 1.0 / SCREEN_PIXEL_SIZE;
    vec2 uv = SCREEN_UV;
    
    vec2 wiggled_uv = wiggle(uv, TIME);
    
    // Clamp UV to prevent wrapping
    wiggled_uv = clamp(wiggled_uv, 0.0, 1.0);
    
    vec3 color = chromatic_shift(screen_texture, wiggled_uv);
    
    // Apply scanlines
    color *= scanlines(uv);
    
    // Apply vignette
    color *= vignette(uv);
    
    // Apply brightness
    color *= brightness;
    
    COLOR = vec4(color, 1.0);
} 