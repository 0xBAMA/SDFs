#version 430 core
layout( local_size_x = 8, local_size_y = 8, local_size_z = 1 ) in;

// render texture, this is written to by this shader
layout( binding = 0, rgba8ui ) uniform uimage2D current;

#define MAX_STEPS 255
#define MAX_DIST  300
#define EPSILON   0.001 // closest surface distance

uniform vec3 lightPos1;
uniform vec3 lightPos2;
uniform vec3 lightPos3;

uniform vec3 lightCol1;
uniform vec3 lightCol2;
uniform vec3 lightCol3;

uniform vec3 basis_x;
uniform vec3 basis_y;
uniform vec3 basis_z;

uniform vec3 ray_origin;

// some geometric primitives
float sdSphere( vec3 p, float s ) {return length(p)-s;}
float sdTorus( vec3 p, vec2  t ) {return length( vec2(length(p.xz)-t.x,p.y) )-t.y;}
float sdCylinder( vec3 p, vec2  h ) {
    vec2 d = abs(vec2(length(p.xz),p.y)) - h;
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float de( vec3 p ) { // distance estimator for the scene
    // todo
    return 0.;
}

// global state tracking
uint num_steps = 0; // how many steps taken by the raymarch function
float dmin = 1e10; // minimum distance initially large

float raymarch(vec3 ro, vec3 rd) {
    float d0 = 0.0, d1 = 0.0;
    for(int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + rd * d0;      // point for distance query from parametric form
        d1 = de(p); d0 += d1;       // increment distance by de evaluated at p
        dmin = min( dmin, d1);      // tracking minimum distance
        num_steps++;                // increment step count
        if(d0 > MAX_DIST || d1 < EPSILON) return d0; // return the final ray distance
    }
}

vec3 norm(vec3 p) {
    vec2 e = vec2( EPSILON, 0.);
    return normalize( vec3(de(p)) - vec3( de(p-e.xyy), de(p-e.yxy), de(p-e.yyx) ));
}


void main()
{
    imageStore(current, ivec2(gl_GlobalInvocationID.xy), uvec4( 120, 45, 12, 255 ));
}
