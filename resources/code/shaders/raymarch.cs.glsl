#version 430 core

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in; // workgroup size

layout( binding = 0, rgba8ui ) uniform uimage2D current;


#define MAX_STEPS 255
#define MAX_DIST 100.0f
#define SURFACE_DISTANCE  0.001f


uniform vec3 lightPos;
uniform vec3 lightPos2;
uniform vec3 lightPos3;


//-------------------------------

float sdSphere( vec3 p, float s )
{
    return length(p)-s;
}

//-------------------------------

float sdTorus( vec3 p, vec2 t )
{
    return length( vec2(length(p.xz)-t.x,p.y) )-t.y;
}

//-------------------------------

float sdCylinder( vec3 p, vec2 h )
{
    vec2 d = abs(vec2(length(p.xz),p.y)) - h;
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

//-------------------------------


//-------------------------------


//-------------------------------

float GetDist(vec3 p)
{
    vec4 s = vec4( 0, 4, 6, 1);
    vec4 s2 = vec4( 0, 1, 6, 1);

    float sphereDist = min(max(-sdSphere(p-s.xyz, s.w), sdCylinder(p-s.xyz, vec2(0.5, 1.5))), sdSphere(p-s.xyz, 0.75*s.w));
    float torusDist = sdTorus(vec3(p.x, mod(p.y, 2), p.z)-s2.xyz, vec2(3, 0.25));
    float planeDist = p.y;

    float d = min(sphereDist, min(torusDist, planeDist));
    return d;
}

uint num_steps;
float RayMarch(vec3 ro, vec3 rd)
{
    num_steps = 0;
    float d0 = 0.0;

    for(int i = 0; i < MAX_STEPS; i++)
    {
        vec3 p = ro + rd * d0;
        float dS = GetDist(p);
        d0 += dS;
        
        num_steps++;

        if(d0>MAX_DIST || dS<SURFACE_DISTANCE)
            break;
    }

    return d0;
}


vec3 GetNormal(vec3 p)
{
    float d = GetDist(p);
    vec2 e = vec2( 0.001, 0);

    vec3 n = d - vec3(
            GetDist(p-e.xyy),
            GetDist(p-e.yxy),
            GetDist(p-e.yyx));

    return normalize(n);
}


float GetLight(vec3 p)
{
    //set this with a uniform
    /* vec3 lightPos = vec3( 2, 5, 6); */

    vec3 l = normalize(lightPos-p);
    vec3 n = GetNormal(p);

    float dif = clamp( dot( n, l), 0.0, 1.0);

    float d = RayMarch(p+n*SURFACE_DISTANCE*2.0, l);

    if(d < length(lightPos - p))
        dif *= 0.1;

    return dif;
}


float GetLight2(vec3 p)
{
    vec3 l = normalize(lightPos2-p);
    vec3 n = GetNormal(p);

    float dif = clamp( dot( n, l), 0.0, 1.0);

    float d = RayMarch(p+n*SURFACE_DISTANCE*2.0, l);

    if(d < length(lightPos2 - p))
        dif *= 0.1;

    return dif;
}


float GetLight3(vec3 p)
{
    vec3 l = normalize(lightPos3-p);
    vec3 n = GetNormal(p);

    float dif = clamp( dot( n, l), 0.0, 1.0);

    float d = RayMarch(p+n*SURFACE_DISTANCE*2.0, l);

    if(d < length(lightPos3 - p))
        dif *= 0.1;

    return dif;
}




void main()
{
    uvec4 e = imageLoad(current, ivec2(gl_GlobalInvocationID.xy));

    // get your pixel coords in the range [-1, 1] on x and y
    vec2 pixcoord = (vec2(gl_GlobalInvocationID.xy)-vec2(imageSize(current).x/2)) / vec2(imageSize(current).x/2);

    vec3 col = vec3(0);

    vec3 ro = vec3(0,4,0);
    vec3 rd = normalize(vec3(1.5*pixcoord.x, pixcoord.y, 1));

    float d = RayMarch(ro, rd);

    uint aaa = num_steps;

    vec3 p = ro + rd * d;

    float dif1 = GetLight(p);
    float dif2 = GetLight2(p);
    float dif3 = GetLight3(p);

    col = vec3(dif1);
    col += vec3(0.6*dif2, 0.3*dif2, 0);
    col += vec3(0.1*dif3, 0.3*dif3, 0.5*dif3);

    /* imageStore(current, ivec2(gl_GlobalInvocationID.xy),  uvec4(256*pixcoord.x, 256*pixcoord.y, 256*pixcoord.x*pixcoord.y, e.a)); */
    imageStore(current, ivec2(gl_GlobalInvocationID.xy),  uvec4(255*col.r, 255*col.g, 255*col.b, 255));
    /* imageStore(current, ivec2(gl_GlobalInvocationID.xy), uvec4(255, 255, 255, 255)); */
    /* imageStore(current, ivec2(gl_GlobalInvocationID.xy), uvec4(0, 0, 0, 255)); */
}
