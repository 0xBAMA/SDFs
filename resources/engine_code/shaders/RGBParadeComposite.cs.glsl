#version 430 core
layout( local_size_x = 8, local_size_y = 8, local_size_z = 1 ) in;

layout( binding = 3, r32ui ) uniform uimage2D RAccumulate;
layout( binding = 4, r32ui ) uniform uimage2D GAccumulate;
layout( binding = 5, r32ui ) uniform uimage2D BAccumulate;

// sample this as overlayfor the rendered output
layout( binding = 6, rgba8ui ) uniform uimage2D RGBCompositeOutput;

void main() {
	uvec4 accumulates;
	accumulates.r = imageLoad( RAccumulate, ivec2( gl_GlobalInvocationID.xy ) ).r;
	accumulates.g = imageLoad( GAccumulate, ivec2( gl_GlobalInvocationID.xy ) ).r;
	accumulates.b = imageLoad( BAccumulate, ivec2( gl_GlobalInvocationID.xy ) ).r;

	// set alpha channel with the max of r,g,b
	accumulates.a = max( max( accumulates.r, accumulates.g ), accumulates.b );

	// clamp and writeback - consider doing something logarithmic
	accumulates = clamp( accumulates, uvec4( 0 ), uvec4( 255 ) );
	imageStore( RGBCompositeOutput, ivec2( gl_GlobalInvocationID.xy ), accumulates );

	imageStore( RAccumulate, ivec2( gl_GlobalInvocationID.xy ), uvec4( 0 ) );
	imageStore( GAccumulate, ivec2( gl_GlobalInvocationID.xy ), uvec4( 0 ) );
	imageStore( BAccumulate, ivec2( gl_GlobalInvocationID.xy ), uvec4( 0 ) );
}
