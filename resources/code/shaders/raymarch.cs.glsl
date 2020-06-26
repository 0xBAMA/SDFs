#version 430 core

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in; // workgroup size

layout( binding = 0, rgba8ui ) uniform uimage2D current;

void main()
{
    uvec4 e = imageLoad(current, ivec2(gl_GlobalInvocationID.xy));

    // get your pixel coords in the range [-1, 1] on x and y
    vec2 pixcoord = (vec2(gl_GlobalInvocationID.xy)-vec2(128)) / vec2(128);

    imageStore(current, ivec2(gl_GlobalInvocationID.xy),  uvec4(256*pixcoord.x, 256*pixcoord.y, 0, e.a));
}
