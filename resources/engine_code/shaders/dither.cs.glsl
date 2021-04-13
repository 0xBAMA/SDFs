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

//  ╔═╗┌─┐┬  ┌─┐┬─┐┌─┐┌─┐┌─┐┌─┐┌─┐  ╔═╗┬ ┬┌┐┌┌─┐┌┬┐┬┌─┐┌┐┌┌─┐
//  ║  │ ││  │ │├┬┘└─┐├─┘├─┤│  ├┤   ╠╣ │ │││││   │ ││ ││││└─┐
//  ╚═╝└─┘┴─┘└─┘┴└─└─┘┴  ┴ ┴└─┘└─┘  ╚  └─┘┘└┘└─┘ ┴ ┴└─┘┘└┘└─┘
// key thing is to have RGB->colorspace and colorspace->RGB for each colorspace to be used
// need to refer to the old code, as well as a few shadertoy examples for different spaces




vec4 get_bayer(){
  return texture(bayer_dither_pattern, gl_GlobalInvocationID.xy/float(textureSize(bayer_dither_pattern, 0).r));
}

vec4 get_blue(){
  return texture(blue_noise_dither_pattern, gl_GlobalInvocationID.xy/float(textureSize(blue_noise_dither_pattern, 0).r));
}

vec4 bitcrush_reduce(vec4 value){
  return vec4(0);
}

// trying a new dithering method now based on the above linked shadertoy example (exponential)
vec4 exponential_reduce(vec4 value){
  return vec4(0);
}

// these two functions rely on global state (spaceswitch)
vec4 convert(uvec4 value){
  switch(spaceswitch)
  {
    case 0: // blah
      break;
    default:
      break;
  }
  return vec4(0);
}

// takes in a value in the globally indicated colorspace
// returns a uvec4 which is ready to be written as 8-bit RGBA
uvec4 convert_back(vec4 value){
  switch(spaceswitch)
  {
    case 0: // blah
      break;
    default:
      break;
  }
  return uvec4(0);
}

vec4 process(vec4 value){
  // take in converted value (at least one color space uses all four channels)
  // reduce the precision, just numerically (maybe shift up by 0.5 for ycbcr?)
  // processed value ready to be converted from chosen color space back to RGBA
  return vec4(0);
}

void main()
{
  // read the old value
  uvec4 read = imageLoad(current, ivec2(gl_GlobalInvocationID.xy));

  // convert it (relies on global state of spaceswitch)
  vec4 converted = convert(read);

  // reduce precision in the selected manner (colorspace, pattern, method)
  vec4 processed = process(converted);

  // convert back (again using spaceswitch)
  uvec4 write = convert_back(processed);

  // store the processed result back to the image
  // imageStore(current, ivec2(gl_GlobalInvocationID.xy), write); // this is what will be used once the rest is implemented
  imageStore(current, ivec2(gl_GlobalInvocationID.xy), read); // for now just write the same value back
  // imageStore(current, ivec2(gl_GlobalInvocationID.xy), temp);
}
