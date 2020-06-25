#version 430 core

in vec2 v_pos;

//uniform bool show_trails;
layout( binding = 0, rgba16ui ) uniform uimage2D current;

out vec4 fragment_output;

void main()
{
	uvec4 s = imageLoad(current, ivec2(imageSize(current)*(0.5*(v_pos+vec2(1)))));
	
	fragment_output = vec4(s.r/65535,s.g/65535,s.b/65536,1);
}
