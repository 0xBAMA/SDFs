#version 430 core
layout( local_size_x = 8, local_size_y = 8, local_size_z = 1 ) in;

// render texture - will be both reading and writing
layout( binding = 0, rgba8ui ) uniform uimage2D current;

layout( binding = 1 ) uniform sampler2D bayer_dither_pattern;
layout( binding = 2 ) uniform sampler2D blue_noise_dither_pattern;

// bayer is static, but blue cycles over time, like https://www.shadertoy.com/view/wlGfWG
uniform int spaceswitch; // what color space
uniform int dithermode; // methodology (bitcrush blue, bitcrush bayer, exponential blue, exponential bayer)
uniform float time;    // used to cycle the blue noise values over time

// key thing is to have RGB->colorspace and colorspace->RGB for each colorspace to be used
// need to refer to the old code, as well as a few shadertoy examples for different spaces
// trying a new dithering method now based on the above linked shadertoy example (exponential)

vec3 get_bayer(){
  // return texture()
  return vec3(0);
}

vec3 get_blue(){
  return vec3(0);
}

vec3 bitcrush_reduce(){
  return vec3(0);
}

vec3 exponential_reduce(){
  return vec3(0);
}

// these two functions rely on global state (spaceswitch)
vec3 convert(vec3 value){
  switch(spaceswitch)
  {
    case 0: // blah
      break;
    default:
      break;
  }
  return vec3(0);
}

vec3 convert_back(vec3 value){
  switch(spaceswitch)
  {
    case 0: // blah
      break;
    default:
      break;
  }
  return vec3(0);
}

void main()
{
  // read the old value
  uvec4 temp = imageLoad(current, ivec2(gl_GlobalInvocationID.xy));

  // convert it (relies on global state of spaceswitch)

  // reduce precision in the selected manner

  // convert back (again using spaceswitch)

  // store back to the image
  imageStore(current, ivec2(gl_GlobalInvocationID.xy), temp);
}
