shader_type canvas_item;

uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	// Mix original color toward white, preserving alpha
	COLOR = vec4(mix(col.rgb, vec3(1.0), flash_amount), col.a);
}
