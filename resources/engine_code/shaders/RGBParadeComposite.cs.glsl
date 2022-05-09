#version 430 core
layout( local_size_x = 8, local_size_y = 8, local_size_z = 1 ) in;

layout( binding = 3, r32ui ) uniform uimage2D RAccumulate;
layout( binding = 4, r32ui ) uniform uimage2D GAccumulate;
layout( binding = 5, r32ui ) uniform uimage2D BAccumulate;

// sample this as overlayfor the rendered output
layout( binding = 6, rgba8ui ) uniform uimage2D RGBCompositeOutput;

float mapping( uint val ){
	return log( float( val ) / 10.0 ) + 0.375;
}

void main() {
	uvec4 accumulates;
	accumulates.r = imageLoad( RAccumulate, ivec2( gl_GlobalInvocationID.xy ) ).r;
	accumulates.g = imageLoad( GAccumulate, ivec2( gl_GlobalInvocationID.xy ) ).r;
	accumulates.b = imageLoad( BAccumulate, ivec2( gl_GlobalInvocationID.xy ) ).r;
	accumulates.a = max( max( accumulates.r, accumulates.g ), accumulates.b ); // set alpha channel with the max of r,g,b

	vec4 Faccumulates; // logarithmic remapping, to try to keep these in visible ranges
	Faccumulates.r = mapping( accumulates.r );
	Faccumulates.g = mapping( accumulates.g );
	Faccumulates.b = mapping( accumulates.b );
	Faccumulates.a = mapping( accumulates.a );

	Faccumulates = clamp( Faccumulates, vec4( 0.0 ), vec4( 1.0 ) );
	accumulates = uvec4( Faccumulates * 255 );

	// writeback
	imageStore( RGBCompositeOutput, ivec2( gl_GlobalInvocationID.xy ), accumulates );

	// reset the accumulator buffers to zero
	imageStore( RAccumulate, ivec2( gl_GlobalInvocationID.xy ), uvec4( 0 ) );
	imageStore( GAccumulate, ivec2( gl_GlobalInvocationID.xy ), uvec4( 0 ) );
	imageStore( BAccumulate, ivec2( gl_GlobalInvocationID.xy ), uvec4( 0 ) );
}
