#version 430 core

// fragment shader, samples from current color buffer
// uniform sampler2DRect image_data;

layout( binding = 0, rgba8ui ) uniform uimage2D image_data;

uniform vec2 resolution;
out vec4 fragment_output;

void main()
{
	// fragment_output = texture(image_data, gl_FragCoord.xy);
	// fragment_output = imageLoad(image_data, ivec2(gl_FragCoord.xy));

	ivec2 position = ivec2((gl_FragCoord.xy / resolution.xy) * imageSize(image_data));
	fragment_output = imageLoad(image_data, position);
}
