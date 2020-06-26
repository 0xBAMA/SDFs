#version 430 core

in vec2 v_pos;

layout( binding = 0, rgba8ui ) uniform uimage2D current;

out vec4 fragment_output;

void main()
{
	vec2 lv_pos = v_pos/2.0f + vec2(0.5);
	
	uvec4 s = imageLoad(current, ivec2(lv_pos.x*256, lv_pos.y*256));
	
	fragment_output = vec4(float(s.r)/256.0,float(s.g)/1024.0,float(s.b)/256.0,float(s.a)/256.0);
}
