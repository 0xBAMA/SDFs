#version 430 core
layout( local_size_x = 8, local_size_y = 8, local_size_z = 1 ) in;

// render texture, this is written to by this shader
layout( binding = 0, rgba8ui ) uniform uimage2D current;

void main()
{
    if(int(gl_GlobalInvocationID.y) % 3 == 0)
    {
        imageStore(current, ivec2(gl_GlobalInvocationID.xy), uvec4( 255, 255,   0, 255 ));
    }
    else
    {
        imageStore(current, ivec2(gl_GlobalInvocationID.xy), uvec4(   0,   0,  0, 255 ));
    }
}
