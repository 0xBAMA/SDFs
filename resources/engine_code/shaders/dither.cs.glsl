#version 430 core
layout( local_size_x = 8, local_size_y = 8, local_size_z = 1 ) in;

// render texture - will be both reading and writing
layout( binding = 0, rgba8ui ) uniform uimage2D current;

layout( binding = 1 ) uniform sampler2D bayer_dither_pattern;
layout( binding = 2 ) uniform sampler2D blue_noise_dither_pattern;

// bayer is static, but blue cycles over time, like https://www.shadertoy.com/view/wlGfWG
uniform int ditherswitch;
uniform float time;

void main()
{

}
