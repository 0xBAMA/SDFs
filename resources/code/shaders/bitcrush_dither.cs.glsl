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

    uvec4 tmp = e;

    l.xyz = e.xyz & uvec3(0xFU); // low bits
    e.xyz = (e.xyz>>4)<<4;      // high bits

    // get the red
    l.r = (indexValue4() >= l.r) ? e.r : e.r + 0x10U;

    // get the green
    l.g = (indexValue4() >= l.g) ? e.g : e.g + 0x10U;
    
    // get the blue
    l.b = (indexValue4() >= l.b) ? e.b : e.b + 0x10U;
    
    /* imageStore(current, ivec2(gl_GlobalInvocationID.xy), uvec4(e.xyz, 255)); */
    /* imageStore(current, ivec2(gl_GlobalInvocationID.xy), uvec4(l.rgb, 255)); */
    imageStore(current, ivec2(gl_GlobalInvocationID.xy), l);
}
