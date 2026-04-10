shader_type canvas_item;

// Button glow shader - adds animated glow to battle move buttons
uniform vec4 glow_color : source_color = vec4(1.0, 0.95, 0.8, 0.8);
uniform float glow_radius : hint_range(0.0, 1.0) = 0.3;
uniform float anim_speed : hint_range(0.0, 4.0) = 2.0;
uniform float base_brightness : hint_range(0.0, 2.0) = 1.0;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    
    // Animated glow intensity
    float pulse = 0.7 + sin(TIME * anim_speed) * 0.3;
    
    // Distance from edge for glow
    float edge_dist = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
    float glow_mask = smoothstep(glow_radius, 0.0, edge_dist) * pulse;
    
    // Add glow to transparent areas around button
    if (tex.a < 0.1 && glow_mask > 0.01) {
        vec3 glow = glow_color.rgb * glow_mask * glow_color.a;
        tex.rgb += glow * 0.5;
    }
    
    // Boost overall brightness
    tex.rgb *= base_brightness;
    
    COLOR = tex;
}
