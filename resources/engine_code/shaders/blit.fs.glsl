#version 430 core

// need to study Voraldo's simultaneous use of image/texture bindings of the render texture
// fragment shader, samples from current color buffer
// layout( binding = 0 ) uniform sampler2DRect image_data;

// render texture, which is read from by this shader
layout( binding = 0, rgba8ui ) uniform uimage2D image_data;

uniform vec2 resolution;
out vec4 fragment_output;

void main()
{
	// fragment_output = texture(image_data, gl_FragCoord.xy);
	// fragment_output = imageLoad(image_data, ivec2(gl_FragCoord.xy));

	ivec2 position = ivec2((gl_FragCoord.xy / resolution.xy) * imageSize(image_data));
	fragment_output = imageLoad(image_data, position) / 255.;
}
