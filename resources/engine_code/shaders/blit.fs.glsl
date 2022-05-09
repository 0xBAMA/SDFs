#version 430 core

// need to study Voraldo's simultaneous use of image/texture bindings of the render texture
// fragment shader, samples from current color buffer
// layout( binding = 0 ) uniform sampler2DRect imageData;

// render texture, which is read from by this shader
layout( binding = 0, rgba8ui ) uniform uimage2D imageData;
layout( binding = 6, rgba8ui ) uniform uimage2D paradePresent;
// uniform sampler2DRect paradePresent;

uniform vec2 resolution;
out vec4 fragment_output;

// this requires refitting in a couple places to use samplers instead of the imageLoad -
// this is similar to what's done in Voraldo for multiple types of access to the same data

// this implementation shared by Inigo Quilez https://www.shadertoy.com/view/MllBWf
vec4 myTexture( sampler2D tex, vec2 uv){
	vec2 res = vec2(textureSize(tex,0));
	uv = uv*res;
	vec2 seam = floor(uv+0.5);
	uv = seam + clamp( (uv-seam)/fwidth(uv), -0.5, 0.5);
	return texture(tex, uv/res);
}

void main()
{
	// fragment_output = texture(imageData, gl_FragCoord.xy);
	// fragment_output = imageLoad(imageData, ivec2(gl_FragCoord.xy));

	ivec2 position = ivec2((gl_FragCoord.xy / resolution.xy) * imageSize(imageData));
	fragment_output = vec4(imageLoad(imageData, position)) / 255.;

	// ivec2 position = ivec2((gl_FragCoord.xy / resolution.xy) * textureSize( paradePresent ));
	// fragment_output = vec4(imageLoad(paradePresent, position)) / 255.;

	if( all( lessThanEqual( ivec2( gl_FragCoord.xy ), ivec2( imageSize( paradePresent ) ) ) ) )
		fragment_output += vec4( imageLoad( paradePresent, ivec2( gl_FragCoord.xy ) ) ) / 255.;

	// fragment_output = texture( paradePresent, position );



	// alpha blend the parade graph over the result, in the bottomn right corner
	// ivec2 positionOverlay = ivec2( gl_FragCoord.xy / resolution.xy ) * ( imageSize( imageData ) * 4.0 );
	// vec4 paradeOverlay = vec4( imageLoad( paradePresent,  ) )
}
