#version 430 core

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in; // workgroup size

layout( binding = 0, rgba8ui ) uniform uimage2D current;

void main()
{
    uvec4 e = imageLoad(current, ivec2(gl_GlobalInvocationID.xy));

    e.xyz = (e.xyz>>4)<<4;

    /* imageStore(current, ivec2(gl_GlobalInvocationID.xy), uvec4(e.xyz, 255)); */
    imageStore(current, ivec2(gl_GlobalInvocationID.xy), e);
}
