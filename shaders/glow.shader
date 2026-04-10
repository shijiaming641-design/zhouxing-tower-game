shader_type canvas_item;

// Glow shader for RPS shapes - adds pulsing glow effect
uniform vec4 glow_color : source_color = vec4(1.0, 0.9, 0.5, 1.0);
uniform float glow_intensity : hint_range(0.0, 3.0) = 1.5;
uniform float pulse_speed : hint_range(0.0, 5.0) = 2.0;
uniform float pulse_amount : hint_range(0.0, 1.0) = 0.3;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    
    // Calculate luminance for glow spread
    float luma = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
    
    // Pulsing effect
    float pulse = 1.0 + sin(TIME * pulse_speed) * pulse_amount;
    
    // Bloom-style glow: bright parts glow outward
    vec3 glow = tex.rgb * glow_intensity * pulse * smoothstep(0.1, 0.5, luma);
    
    COLOR = tex + vec4(glow, 0.0);
}
