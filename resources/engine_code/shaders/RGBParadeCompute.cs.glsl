#version 430 core
layout( local_size_x = 8, local_size_y = 8, local_size_z = 1 ) in;
layout( binding = 0, rgba8ui ) uniform uimage2D current;

layout( binding = 3, r32ui ) uniform uimage2D redComposite;
layout( binding = 4, r32ui ) uniform uimage2D greenComposite;
layout( binding = 5, r32ui ) uniform uimage2D blueComposite;

void main() {
	// this is called after the dither - building histograms with atomic adds

	if( !( any( greaterThan( gl_GlobalInvocationID.xy, imageSize( current ).xy ) ) || any( lessThanEqual( gl_GlobalInvocationID.xy, ivec2( 0 ) ) ) ) ) {
		// passes bounds check
		uvec3 intensities = imageLoad( current, ivec2( gl_GlobalInvocationID.xy ) ).xyz;

		uint writeX = gl_GlobalInvocationID.x;
		imageAtomicAdd(   redComposite, ivec2( writeX, intensities.r ), 1 );
		imageAtomicAdd( greenComposite, ivec2( writeX, intensities.g ), 1 );
		imageAtomicAdd(  blueComposite, ivec2( writeX, intensities.b ), 1 );
	}
}
