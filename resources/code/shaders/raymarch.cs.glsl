#version 430 core

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in; // workgroup size

layout( binding = 0, rgba8ui ) uniform uimage2D current;


#define MAX_STEPS 100
#define MAX_DIST 100.0f
#define SURFACE_DISTANCE  0.01f


float GetDist(vec3 p)
{
    vec4 s = vec4( 0, 1, 6, 1);

    float sphereDist = length(p-s.xyz)-s.w;
    float planeDist = p.y;

    float d = min(sphereDist, planeDist);
    return d;
}


float RayMarch(vec3 ro, vec3 rd)
{
    float d0 = 0.0;

    for(int i = 0; i < MAX_STEPS; i++)
    {
        vec3 p = ro + rd * d0;
        float dS = GetDist(p);
        d0 += dS;
        if(d0>MAX_DIST || dS<SURFACE_DISTANCE)
            break;
    }

    return d0;
}


vec3 GetNormal(vec3 p)
{
    float d = GetDist(p);
    vec2 e = vec2( 0.01, 0);

    vec3 n = d - vec3(
            GetDist(p-e.xyy),
            GetDist(p-e.yxy),
            GetDist(p-e.yyx));

    return normalize(n);
}


float GetLight(vec3 p)
{
    //set this with a uniform
    vec3 lightPos = vec3( 2, 5, 6);

    vec3 l = normalize(lightPos-p);
    vec3 n = GetNormal(p);

    float dif = clamp( dot( n, l), 0.0, 1.0);

    float d = RayMarch(p+n*SURFACE_DISTANCE*2.0, l);

    if(d < length(lightPos - p))
        dif *= 0.1;

    return dif;
}


void main()
{
    uvec4 e = imageLoad(current, ivec2(gl_GlobalInvocationID.xy));

    // get your pixel coords in the range [-1, 1] on x and y
    vec2 pixcoord = (vec2(gl_GlobalInvocationID.xy)-vec2(128)) / vec2(128);

    vec3 col = vec3(0);

    vec3 ro = vec3(0,1,0);
    vec3 rd = normalize(vec3(1.5*pixcoord.x, pixcoord.y, 1));

    float d = RayMarch(ro, rd);

    vec3 p = ro + rd * d;

    float dif = GetLight(p);
    col = vec3(dif);


    /* imageStore(current, ivec2(gl_GlobalInvocationID.xy),  uvec4(256*pixcoord.x, 256*pixcoord.y, 256*pixcoord.x*pixcoord.y, e.a)); */
    imageStore(current, ivec2(gl_GlobalInvocationID.xy),  uvec4(256*col.r, 256*col.g, 256*col.b, 255));
}
