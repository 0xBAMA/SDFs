#version 430 core

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in; // workgroup size

layout( binding = 0, rgba8ui ) uniform uimage2D current;

// matrix from http://alex-charlton.com/posts/Dithering_on_the_GPU/ 
const uint indexMatrix4x4[16] = uint[](  0,  8,  2,  10,
                                        12, 4,  14, 6,
                                        3,  11, 1,  9,
                                        15, 7,  13, 5);

uint indexValue4() 
{
    int x = int(mod(gl_GlobalInvocationID.x, 4));
    int y = int(mod(gl_GlobalInvocationID.y, 4));
    return indexMatrix4x4[(x + y * 4)];
}

// these expect normalized vec4s for color
vec4 RGBtoYUV(vec4 rgba)
{
    vec4 yuva;
    yuva.r = rgba.r * 0.2126 + 0.7152 * rgba.g + 0.0722 * rgba.b;
    yuva.g = (rgba.b - yuva.r) / 1.8556;
    yuva.b = (rgba.r - yuva.r) / 1.5748;
    yuva.a = rgba.a;

    // Adjust to work on GPU
    yuva.gb += 0.5;

    return yuva;
}

vec4 YUVtoRGB(vec4 yuva) {
    yuva.gb -= 0.5;
    return vec4(
        yuva.r * 1 + yuva.g * 0 + yuva.b * 1.5748,
        yuva.r * 1 + yuva.g * -0.187324 + yuva.b * -0.468124,
        yuva.r * 1 + yuva.g * 1.8556 + yuva.b * 0,
        yuva.a);
}

const uint indexMatrix8x8[64] = uint[](  0,  32, 8,  40, 2,  34, 10, 42,
                                         48, 16, 56, 24, 50, 18, 58, 26,
                                         12, 44, 4,  36, 14, 46, 6,  38,
                                         60, 28, 52, 20, 62, 30, 54, 22,
                                         3,  35, 11, 43, 1,  33, 9,  41,
                                         51, 19, 59, 27, 49, 17, 57, 25,
                                         15, 47, 7,  39, 13, 45, 5,  37,
                                         63, 31, 55, 23, 61, 29, 53, 21);

uint indexValue8() {
    int x = int(mod(gl_GlobalInvocationID.x, 8));
    int y = int(mod(gl_GlobalInvocationID.y, 8));
    return indexMatrix8x8[(x + y * 8)];
}


void main()
{
    uvec4 e = imageLoad(current, ivec2(gl_GlobalInvocationID.xy));
    uvec4 l = uvec4(255);

    uvec4 temp = e;


    // get the normalized values of the YUV representation
    vec4 normalizedYUV = RGBtoYUV(vec4(e/256.));

    // get the uint representation of the normalized
    e = uvec4(normalizedYUV*256);

    // bitcrush
    l.xyz = e.xyz & uvec3(0x0FU);   // low bits
    e.xyz = e.xyz & uvec3(0xF0U);  // high bits

    // dither
    l.r = (indexValue4() >= l.r) ? e.r : e.r + 0x10U;
    l.g = (indexValue4() >= l.g) ? e.g : e.g + 0x10U;
    l.b = (indexValue4() >= l.b) ? e.b : e.b + 0x10U;

    // convert back
    vec4 normalizedRGB = YUVtoRGB(vec4(l/256.));

    // again, the uint representation
    l = uvec4(normalizedRGB*256);

    // store result
    imageStore(current, ivec2(gl_GlobalInvocationID.xy), uvec4(l.rgb, e.a));
}
