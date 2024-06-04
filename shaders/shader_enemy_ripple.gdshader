// Converted/modified from ShaderToy: https://www.shadertoy.com/view/ldBXDD
// Attach this shader to a ColorRect

shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float wave_radius = 1.0;

vec2 rotate(vec2 uv, vec2 pivot, float angle)
{
	mat2 rotation = mat2(
		vec2(sin(angle), -cos(angle)),
		vec2(cos(angle), sin(angle))
	);
	
	uv -= pivot;
	uv = uv * rotation;
	uv += pivot;
	return uv;
}

void fragment() {
	vec2 screen_resolution = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 texture_resolution = 1.0 / TEXTURE_PIXEL_SIZE;
	
	// This is a vector extending
	// from the origin (0, 0) in the middle of the ColorRect
	// to the pixel currently being processed
	vec2 wave_vector = -1.0 + 2.0 * UV / TEXTURE_PIXEL_SIZE;
	float wave_vector_length = length(wave_vector);
	vec2 wave_vector_normalized = wave_vector / wave_vector_length;
	
	float wave_strength_t = min(1.0, wave_vector_length / wave_radius);
	float wave_strength = mix(1, 0, wave_strength_t);
	
	vec2 uv_base = FRAGCOORD.xy / screen_resolution.xy;
	vec2 uv_offset;
	
	uv_offset = rotate(wave_vector_normalized, vec2(0, 0), TIME);
	uv_offset *= 0.05 * sin(TIME) * wave_strength;
	
    vec2 uv = uv_base - uv_offset;
	vec3 col = texture(SCREEN_TEXTURE, uv).xyz;
	
	COLOR = vec4(col, 1.0);
}