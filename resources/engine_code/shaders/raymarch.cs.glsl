#version 430 core
layout( local_size_x = 8, local_size_y = 8, local_size_z = 1 ) in;

// render texture, this is written to by this shader
layout( binding = 0, rgba8ui ) uniform uimage2D current;

void main()
{
    bvec2 mod_result = bvec2(gl_GlobalInvocationID.x%2==0, gl_GlobalInvocationID.y%2==0);
    imageStore(current, ivec2(gl_GlobalInvocationID.xy), uvec4(mod_result.x ? 0:255, mod_result.y ? 0:255,   0, 255 ));
}
