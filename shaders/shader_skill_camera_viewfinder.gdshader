shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform vec2 viewfinder_position;
uniform float viewfinder_rotation;
uniform vec2 viewfinder_scale;

float get_area(vec2 a, vec2 b, vec2 c) {
	// abs( (Bx * Ay - Ax * By) + (Cx * By - Bx * Cy) + (Ax * Cy - Cx * Ay) ) / 2
	float aa = b.x * a.y - a.x * b.y;
	float bb = c.x * b.y - b.x * c.y;
	float cc = a.x * c.y - c.x * a.y;
	return abs(aa + bb + cc) / 2.0;
}

void fragment() {
	vec2 screen_resolution = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 current_pixel = SCREEN_UV * screen_resolution;
	vec2 uv = FRAGCOORD.xy / screen_resolution.xy;
	float base_darken = 0.5;
	
	vec2 viewfinder_size = viewfinder_scale * vec2(120, 90);
	float x = viewfinder_position.x;
	float y = viewfinder_position.y;
	float w = viewfinder_size.x / 2.0;
	float h = viewfinder_size.y / 2.0;
	
	if (current_pixel.x > x - 2.0 * w &&
		current_pixel.x < x + 2.0 * w &&
		current_pixel.y > y - 2.0 * h &&
		current_pixel.y < y + 2.0 * h) {
		
		float angle = viewfinder_rotation;
		mat2 rotation = mat2(
			vec2(cos(angle), sin(angle)),
			vec2(-sin(angle), cos(angle))
		);
		
		vec2 a = viewfinder_position + (rotation * vec2(-w, -h));
		vec2 b = viewfinder_position + (rotation * vec2( w, -h));
		vec2 c = viewfinder_position + (rotation * vec2( w,  h));
		vec2 d = viewfinder_position + (rotation * vec2(-w,  h));
		vec2 p = current_pixel;
		
		float rectangle_area = viewfinder_size.x * viewfinder_size.y;
		float sum_area = get_area(a, p, d) + get_area(d, p, c) + get_area(c, p, b) + get_area(p, b, a);
		
		float darken = 1.0;
		if (sum_area - 0.1 > rectangle_area) {
			darken = base_darken;
		}
		
		vec4 base_texture = texture(SCREEN_TEXTURE, uv);
		COLOR = vec4(darken * base_texture.rgb, base_texture.a);
	} else {
		
		vec4 base_texture = texture(SCREEN_TEXTURE, uv);
		COLOR = vec4(base_darken * base_texture.rgb, base_texture.a);
	}
}
