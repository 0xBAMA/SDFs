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

const float eps = 0.0000001;
// these expect normalized vec4s for color
vec4 HSLtoRGB( in vec4 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
    return vec4(vec3(c.z + c.y * (rgb-0.5)*(1.0-abs(2.0*c.z-1.0))), c.a);
}

vec4 RGBtoHSL( vec4 col )
{
    float minc = min( col.r, min(col.g, col.b) );
    float maxc = max( col.r, max(col.g, col.b) );
    vec3  mask = step(col.grr,col.rgb) * step(col.bbg,col.rgb);
    vec3 h = mask * (vec3(0.0,2.0,4.0) + (col.gbr-col.brg)/(maxc-minc + eps)) / 6.0;
    return vec4( fract( 1.0 + h.x + h.y + h.z ),              // H
                 (maxc-minc)/(1.0-abs(minc+maxc-1.0) + eps),  // S
                 (minc+maxc)*0.5,                             // L
                 col.a); // existing alpha value
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


    // get the normalized values of the HSL representation
    vec4 normalizedHSL = RGBtoHSL(vec4(e/256.));

    // get the uint representation of the normalized
    e = uvec4(normalizedHSL*256);

    // bitcrush
    l.xyz = e.xyz & uvec3(0x0FU);   // low bits
    e.xyz = e.xyz & uvec3(0xF0U);  // high bits

    // dither
    l.r = (indexValue4() >= l.r) ? e.r : e.r + 0x10U;
    l.g = (indexValue4() >= l.g) ? e.g : e.g + 0x10U;
    l.b = (indexValue4() >= l.b) ? e.b : e.b + 0x10U;

    // convert back
    vec4 normalizedRGB = HSLtoRGB(vec4(l/256.));

    // again, the uint representation
    l = uvec4(normalizedRGB*256);

    // store result
    imageStore(current, ivec2(gl_GlobalInvocationID.xy), uvec4(l.rgb, e.a));
}
