// Converted/modified from ShaderToy: https://www.shadertoy.com/view/ldBXDD
// Attach this shader to a ColorRect

shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float tick;
uniform float wave_max_width = 0.1;
uniform float wave_max_strength = 0.1;
uniform float wave_speed = 1.0;

void fragment() {
	float t = min(1.0, tick * wave_speed);
	float wave_radius = mix(0.0, 1.0 - wave_max_width, t);
	float wave_width = 0.3; // mix(0.0, wave_max_width, t);
	
	vec2 screen_resolution = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 texture_resolution = 1.0 / TEXTURE_PIXEL_SIZE;
	
	// This is a vector extending
	// from the origin (0, 0) in the middle of the ColorRect
	// to the pixel currently being processed
	vec2 wave_vector = -1.0 + 2.0 * UV / TEXTURE_PIXEL_SIZE;
	float wave_vector_length = length(wave_vector);
	vec2 wave_vector_normalized = wave_vector / wave_vector_length;
	
	vec2 uv_base = FRAGCOORD.xy / screen_resolution.xy;
	vec2 uv_offset = vec2(0, 0);
	
	float wave_distance = wave_vector_length - wave_radius;
	if (abs(wave_distance) < wave_width) {
		float wave_strength_damper = 1.0;
		wave_strength_damper = mix(1.0, 0.0, t);
		
		float wave_strength = wave_strength_damper * 0.05 * abs(wave_distance);
		uv_offset = wave_vector_normalized * wave_strength;
	}
	
    vec2 uv = uv_base - uv_offset;
	vec3 col = texture(SCREEN_TEXTURE, uv).xyz;
	
	COLOR = vec4(col, 1.0);
}