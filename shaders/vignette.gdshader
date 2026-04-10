shader_type canvas_item;

// Vignette + subtle color grading overlay
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.4;
uniform float vignette_radius : hint_range(0.0, 2.0) = 0.7;
uniform float scene_brightness : hint_range(0.5, 1.5) = 1.0;
uniform float scene_saturation : hint_range(0.5, 1.5) = 1.0;

void fragment() {
    // Subtle color pass-through
    COLOR = vec4(1.0);
    
    // Vignette calculation
    vec2 uv = UV - 0.5;
    float dist = length(uv * vignette_radius);
    float vignette = smoothstep(0.5, 1.0, dist) * vignette_strength;
    
    // Apply vignette as darkening
    COLOR.rgb = vec3(1.0 - vignette);
    COLOR.a = vignette * 0.5; // Overlay mode
}

render_mode blend_premul_alpha;
