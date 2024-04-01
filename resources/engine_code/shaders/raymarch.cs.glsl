#version 430 core
layout( local_size_x = 8, local_size_y = 8, local_size_z = 1 ) in;

// render texture, this is written to by this shader
layout( binding = 0, rgba8ui ) uniform uimage2D current;

#define M_PI 3.1415926535897932384626433832795

#define MAX_STEPS 200
#define MAX_DIST  100.
#define EPSILON   0.0015 // closest surface distance

#define AA 1

uniform vec3 basic_diffuse;
uniform vec3 fog_color;

uniform int tonemap_mode;
uniform float gamma;

uniform vec3 lightPos1;
uniform vec3 lightPos2;
uniform vec3 lightPos3;

// flicker factors
uniform float flickerfactor1;
uniform float flickerfactor2;
uniform float flickerfactor3;

// diffuse light colors
uniform vec3 lightCol1d;
uniform vec3 lightCol2d;
uniform vec3 lightCol3d;
// specular light colors
uniform vec3 lightCol1s;
uniform vec3 lightCol2s;
uniform vec3 lightCol3s;
// specular powers per light
uniform float specpower1;
uniform float specpower2;
uniform float specpower3;
// sharpness terms per light
uniform float shadow1;
uniform float shadow2;
uniform float shadow3;

uniform float AO_scale;

uniform vec3 basis_x;
uniform vec3 basis_y;
uniform vec3 basis_z;

uniform float fov;

uniform vec3 ray_origin;
uniform float time;

uniform float depth_scale;
uniform int depth_falloff;


#include "tonemap.glsl"
#include "twigl.glsl"
#include "hg_sdf.glsl"


// point rotation about an arbitrary axis, ax - from gaziya5
vec3 erot(vec3 p, vec3 ax, float ro) {
    return mix(dot(p,ax)*ax,p,cos(ro))+sin(ro)*cross(ax,p);
}

// from https://twitter.com/gaziya5/status/1340475834352631808
#define sabs(p) sqrt (p*p + 1e-2)
#define smin(a, b) (a + b-sabs (ab)) * .5
#define smax(a, b) (a + b + sabs (ab)) * .5

float opSmoothSubtraction( float d1, float d2, float k )
{
    float h = max(k-abs(-d1-d2),0.0);
    return max(-d1, d2) + h*h*0.25/k;
	//float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
	//return mix( d2, -d1, h ) + k*h*(1.0-h);
}

// smooth minimum
float smin_op(float a, float b, float k) {
    float h = max(0.,k-abs(b-a))/k;
    return min(a,b)-h*h*h*k/6.;
}

// from michael0884's marble marcher community edition
void planeFold(inout vec3 z, vec3 n, float d) {
    z.xyz -= 2.0 * min(0.0, dot(z.xyz, n) - d) * n;
}

void sierpinskiFold(inout vec3 z) {
    z.xy -= min(z.x + z.y, 0.0);
    z.xz -= min(z.x + z.z, 0.0);
    z.yz -= min(z.y + z.z, 0.0);
}

void mengerFold(inout vec3 z)
{
    z.xy += min(z.x - z.y, 0.0)*vec2(-1.,1.);
    z.xz += min(z.x - z.z, 0.0)*vec2(-1.,1.);
    z.yz += min(z.y - z.z, 0.0)*vec2(-1.,1.);
}

void boxFold(inout vec3 z, vec3 r) {
    z.xyz = clamp(z.xyz, -r, r) * 2.0 - z.xyz;
}

// from a distance estimated fractal by discord user Nameless#1608
// array repetition
#define pmod(p,a) mod(p - 0.5*a,a) - 0.5*a

// another fold
void sphereFold(inout vec3 z) {
    float minRadius2 = 1.;
    float fixedRadius2 = 5.;
    float r2 = dot(z,z);
    if (r2 < minRadius2) {
        float temp = (fixedRadius2/minRadius2);
        z*= temp;
    } else if (r2 < fixedRadius2) {
        float temp =(fixedRadius2/r2);
        z*=temp;
    }
}

// some geometric primitives
float sdSphere( vec3 p, float s ) {return length(p)-s;}
float sdTorus( vec3 p, vec2  t ) {return length( vec2(length(p.xz)-t.x,p.y) )-t.y;}
float sdCylinder( vec3 p, vec2  h ) {
    vec2 d = abs(vec2(length(p.xz),p.y)) - h;
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float old_de( vec3 porig ) { // distance estimator for the scene
    vec3 p = porig;

    // p = pmod(p, vec3(3.85,0.65,3.617));
		pModMirror2(p.xz, vec2(3.85, 3.617));
		pModMirror1(p.y, 0.685);

		// sphereFold(p);
		// mengerFold(p);

    float tfactor = abs(pow(abs(cos(time/2.)), 6.)) * 2 - 1;

		// float drings = sdTorus(p, vec2(1.182, 0.08 + 0.05 * cos(time/5.+0.5*porig.x+0.8*porig.z)));
		float drings = sdTorus(p, vec2(1.182, 0.08 ));

		// float dballz = sdSphere(p, 0.8 + 0.25*tfactor*(sin(time*2.1+porig.x*2.18+porig.z*2.7+porig.y*3.14)+1.));
		float dballz = sdSphere(p, 0.8 + 0.25*tfactor);

    float pillarz = smin_op(drings, dballz, 0.9);

		float dplane = fPlane(porig, vec3(0,1,0), 5.);

		// p = pmod(p*0.2, vec3(2.4,1.2,1.6));
		p = porig;

		pR(p.yz, time/3.14);
		// pR(p.xy, time*0.3);

    float dtorus = fTorus( p, 1.2, 6.6);

		float dfinal = smin_op(
											smin_op(
												max(pillarz, sdSphere(porig, 8.5)),
													dtorus, 0.385),
														dplane, 0.685);

		return dfinal;
}

// by gaz
float screw_de(vec3 p){
    float c=.2;
    p.z+=atan(p.y,p.x)/M_PI*c;
    p.z=mod(p.z,c*2.)-c;
    return length(vec2(length(p.xy)-.4,p.z))-.1;
}

float escape = 0.;
vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d ){
    return a + b*cos( 6.28318*(c*t+d) );
}


// // hard crash on desktop - probably hardware related - looks like shit on laptop
// // not indexed in the DEC
// float torus(vec3 pos, vec3 p, vec2 s){
//     vec2 a = normalize(p.xz-pos.xz);
//     pos.xz += a*s.x;
//     return length(pos-p)-s.y;
// }
// float fractal_de2(vec3 p0){
//     vec4 p = vec4(p0, 1.);
//     for(int i = 0; i < 8; i++){
//         p.xyz = mod(p.xyz-1., 2.)-1.;
//         p*=(1.8/dot(p.xyz,p.xyz));
//         escape += exp(-0.2*dot(p.xyz,p.xyz));
//     }
//     p.xyz /= p.w;
//     return 0.25*torus(p0, p.xyz, vec2(5.,0.7));
// }


// hard crash on desktop
float fractal_de11(vec3 p0){
    vec4 p = vec4(p0, 1.);
    escape = 0.;
    for(int i = 0; i < 8; i++){
        p.xyz = fract(p.xyz*0.5 - 1.)*2.-1.0;
        p*=(0.9/dot(p.xyz,p.xyz));
        escape += exp(-0.2*dot(p.xyz,p.xyz));
    }
    p/=p.w;
    return abs(p.y)*0.25;
}


// hard crash - maybe better with tile based renderer?
vec3 fold2(vec3 p0){
    vec3 p = p0;
    if(length(p) > 2.)return p;
        p = mod(p,2.)-1.;
    return p;
}
float fractal_de13(vec3 p0){
    vec4 p = vec4(p0*10., 1.);
    escape = 0.;
    for(int i = 0; i < 12; i++){
        //p.xyz = clamp(p.xyz, vec3(-2.3), vec3(2.3))-p.xyz;
        //p.xyz += sin(float(i+1));
        if(p.x > p.z)p.xz = p.zx;
        if(p.z > p.y)p.zy = p.yz;
        p = abs(p);
        p.xyz = fold2(p.xyz);

        //p.xyz = fract(p.xyz*0.5 - 1.)*2.-1.0;
        p.xyz = mod(p.xyz-1., 2.)-1.;
        p*=(1.1/dot(p.xyz,p.xyz));
        //p*=1.2;
        escape += exp(-0.2*dot(p.xyz,p.xyz));

    }
    p/=p.w;
    return (abs(p.x)*0.25)/10.;
}




float fractal_de33(vec3 p0){ // hard crash on desktop
    vec4 p = vec4(p0, 1.);
    escape = 0.;

    for(int i = 0; i < 8; i++){
        if(p.x > p.z)p.xz = p.zx;
        if(p.z > p.y)p.zy = p.yz;
        if(p.y > p.x)p.yx = p.xy;
        p = abs(p);
        p.xyz = fract(p.xyz*0.5 - 1.)*2.-1.0;
        p*=(1.0/clamp(dot(p.xyz,p.xyz),-0.1,2.));
        p.xyz-=vec3(0.1,0.4,0.2);
        escape += exp(-0.2*dot(p.xyz,p.xyz));

    }
    p/=p.w;
    return abs(p.x)*0.25;
}


float fractal_de34(vec3 p0){ // hard crash on desktop
    vec4 p = vec4(p0, 1.);
    escape = 0.;

    for(int i = 0; i < 8; i++){
        if(p.x > p.z)p.xz = p.zx;
        if(p.z > p.y)p.zy = p.yz;
        if(p.y > p.x)p.yx = p.xy;
        p = abs(p);
        p.xyz = fract(p.xyz*0.5 - 1.)*2.-1.0;
        p*=(1.0/clamp(dot(p.xyz,p.xyz),-0.1,1.));
        p.xyz-=vec3(0.1,0.4,0.2);
        escape += exp(-0.2*dot(p.xyz,p.xyz));

    }
    p/=p.w;
    return abs(p.x)*0.25;
}



//spiky forest - crash on desktop
#define rot(a)mat2(cos(a),sin(a),-sin(a),cos(a))
float lpNorm42(vec3 p, float n)
{
	p = pow(abs(p), vec3(n));
	return pow(p.x+p.y+p.z, 1.0/n);
}

float fractal_de42(vec3 p){
    vec3 q=p;
	float s = 2.5;
	for(int i = 0; i < 10; i++) {
        p=mod(p-1.,2.)-1.;
		float r2=1.1/pow(lpNorm42(abs(p),2.+q.y*10.),1.75);
    	p*=r2;
    	s*=r2;
        p.xy*=rot(.001);
    }
    return q.y>1.3?length(p)/s:abs(p.y)/s;
}
#undef rot


// hard crash on desktop
#define sabs53(p) sqrt((p)*(p)+.8)
void sfold90_53(inout vec2 p)
{
    p=(p.x+p.y+vec2(1,-1)*sabs(p.x-p.y))*.5;
}
float fractal_de53(vec3 p)
{
	p=mod(p-1.5,3.)-1.5;
	p=abs(p)-1.3;
	sfold90_53(p.xz);
	sfold90_53(p.xz);
	sfold90_53(p.xz);

	float s=1.;
	p-=vec3(.5,-.3,1.5);
	for(float i=0.;i++<7.;)
    {
		float r2=2.1/clamp(dot(p,p),.0,1.);
		p=abs(p)*r2;
		p-=vec3(.1,.5,7.);
		s*=r2;
	}
    float a=3.;
    p-=clamp(p,-a,a);
    return length(p)/s-.005;
}
#undef sabs53




// hard crash on desktop
#define sabs_54(x)sqrt((x)*(x)+.005)
#define sabs2_54(x)sqrt((x)*(x)+1e-4)
#define smax_54(a,b) (a+b+sabs2_54(a-b))*.5

void sfold90_54(inout vec2 p)
{
    p=(p.x+p.y+vec2(1,-1)*sabs(p.x-p.y))*.5;
}

float fractal_de54(vec3 p){
    vec3 q=p;
    p=abs(p)-4.;
    sfold90_54(p.xy);
    sfold90_54(p.yz);
    sfold90_54(p.zx);

	float s=2.5;
	p=sabs_54(p);
	vec3  p0 = p*1.5;
	for (float i=0.; i<4.; i++){
    	p=1.-sabs2_54(sabs2_54(p-2.)-1.);
    	float g=-5.5*clamp(.7*smax_54(1.6/dot(p,p),.7),.0,5.5);
    	p*=g;
    	p+=p0+normalize(vec3(1,5,12))*(5.-.8*i);
        s*=g;
	}
	s=sabs_54(s);
	float a=25.;
	p-=clamp(p,-a,a);

	q=abs(q)-vec3(3.7);
    sfold90_54(q.xy);
    sfold90_54(q.yz);
    sfold90_54(q.zx);
  	return smax_54(max(abs(q.y),abs(q.z))-1.3,length(p)/s-.00);
}

#undef sabs_54
#undef sabs2_54
#undef smax_54


// this one is very cool, but hard crash on desktop
float fractal_de58(vec3 p){
    float s=2.;
    float k=0.;
    p=abs(mod(p-1.,2.)-1.)-1.;
    for(int j=0;++j<9;)
        p=1.-abs(p-1.),
        p=p*(k=-1./dot(p,p))-vec3(.1,.3,.1),
        s*=abs(k);
    return length(p.xz)/s;
}



// by gaz - hard crash on desktop
float fractal_de63(vec3 p){
    p.x<p.z?p=p.zyx:p;
    p.y<p.z?p=p.xzy:p;
    float s=3.;
    float l=0.;
    for(int j=0;j++<6;)
        s*=l=2./min(dot(p,p),1.),
        p=abs(p)*l-vec3(.5,.5,7);
    return length(cross(p,p/p))/s;
}


// by iq - 'Fractal Cave'
float maxcomp132(in vec3 p ) { return max(p.x,max(p.y,p.z));}
float sdBox132( vec3 p, vec3 b ){
  vec3  di = abs(p) - b;
  float mc = maxcomp132(abs(p)-b);
  return min(mc,length(max(di,0.0)));
}
float fractal_de132(vec3 p){
    vec3 w = p; vec3 q = p;
    q.xz = mod( q.xz+1.0, 2.0 ) -1.0;
    float d = sdBox132(q,vec3(1.0));
    float s = 1.0;
    for( int m=0; m<7; m++ ){
        float h = float(m)/6.0;
        p =  q.yzx - 0.5*sin( 1.5*p.x + 6.0 + p.y*3.0 + float(m)*5.0 + vec3(1.0,0.0,0.0));
        vec3 a = mod( p*s, 2.0 )-1.0;
        s *= 3.0;
        vec3 r = abs(1.0 - 3.0*abs(a));
        float da = max(r.x,r.y);
        float db = max(r.y,r.z);
        float dc = max(r.z,r.x);
        float c = (min(da,min(db,dc))-1.0)/s;
        d = max( c, d );
   }
   return d*0.5;
}


// Jos Leys / Knighty
// https://www.shadertoy.com/view/XlVXzh
vec2 wrap(vec2 x, vec2 a, vec2 s){
	x -= s;
	return (x-a*floor(x/a)) + s;
}

void TransA(inout vec3 z, inout float DF, float a, float b){
	float iR = 1. / dot(z,z);
	z *= -iR;
	z.x = -b - z.x; z.y = a + z.y;
	DF *= max(1.,iR);
}

float JosKleinian(vec3 z) {
	float adjust = 6.2; // use this for time varying behavior

	float box_size_x=1.;
	float box_size_z=1.;

	float KleinR = 1.94+0.05*abs(sin(-adjust*0.5));//1.95859103011179;
	float KleinI = 0.03*cos(-adjust*0.5);//0.0112785606117658;
	vec3 lz=z+vec3(1.), llz=z+vec3(-1.);
	float d=0.; float d2=0.;

	float DE=1e10;
	float DF = 1.0;
	float a = KleinR;
	float b = KleinI;
	float f = sign(b)*1.;
	for (int i = 0; i < 20 ; i++) {
		z.x=z.x+b/a*z.y;
		z.xz = wrap(z.xz, vec2(2. * box_size_x, 2. * box_size_z), vec2(- box_size_x, - box_size_z));
		z.x=z.x-b/a*z.y;

		//If above the separation line, rotate by 180° about (-b/2, a/2)
		if  (z.y >= a * 0.5 + f *(2.*a-1.95)/4. * sign(z.x + b * 0.5)* (1. - exp(-(7.2-(1.95-a)*15.)* abs(z.x + b * 0.5))))
		{z = vec3(-b, a, 0.) - z;}

		//Apply transformation a
		TransA(z, DF, a, b);

		//If the iterated points enters a 2-cycle , bail out.
		if(dot(z-llz,z-llz) < 1e-5) {break;}

		//Store prévious iterates
		llz=lz; lz=z;
	}

	float y =  min(z.y, a-z.y) ;
	DE=min(DE,min(y,0.3)/max(DF,2.));
	// if (SI) {DE=DE*d2/(rad+d*DE);}
	return DE;
}


float de( vec3 p ){
  vec3 k = vec3( 5.0, 2.0, 1.0 );
  p.y += 5.5;
  for( int j = 0; ++j < 8; ) {
    p.xz = abs( p.xz );
    p.xz = p.z > p.x ? p.zx : p.xz;
    p.z = 0.9 - abs( p.z - 0.9 );
    p.xy = p.y > p.x ? p.yx : p.xy;
    p.x -= 2.3;
    p.xy = p.y > p.x ? p.yx : p.xy;
    p.y += 0.1;
    p = k + ( p - k ) * 3.2;
  }
  return length( p ) / 6e3 - 0.001;
}

//  ╦═╗┌─┐┌┐┌┌┬┐┌─┐┬─┐┬┌┐┌┌─┐  ╔═╗┌─┐┌┬┐┌─┐
//  ╠╦╝├┤ │││ ││├┤ ├┬┘│││││ ┬  ║  │ │ ││├┤
//  ╩╚═└─┘┘└┘─┴┘└─┘┴└─┴┘└┘└─┘  ╚═╝└─┘─┴┘└─┘
// global state tracking
uint num_steps = 0; // how many steps taken by the raymarch function
float dmin = 1e10; // minimum distance initially large

float raymarch(vec3 ro, vec3 rd) {
    float d0 = 0.0, d1 = 0.0;
    for(int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + rd * d0;        // point for distance query from parametric form
        d1 = de(p); d0 += 0.618 * d1; // increment distance by de evaluated at p, scaled by an understepping factor
        dmin = min( dmin, d1);        // tracking minimum distance
        num_steps++;                  // increment step count
        if(d0 > MAX_DIST || d1 < EPSILON || i == (MAX_STEPS-1)) return d0; // return the final ray distance
    }
}

vec3 norm(vec3 p) { // to get the normal vector for a point in space, this function evaluates the gradient of the distance function
#define METHOD 2
#if METHOD == 0
    // tetrahedron version, unknown source - 4 evaluations
    vec2 e = vec2(1,-1) * EPSILON;
    return normalize(e.xyy*de(p+e.xyy)+e.yyx*de(p+e.yyx)+e.yxy*de(p+e.yxy)+e.xxx*de(p+e.xxx));

#elif METHOD == 1
    // by iq = more efficient, 4 evaluations
    vec2 e = vec2( EPSILON, 0.); // computes the gradient of the estimator function
    return normalize( vec3(de(p)) - vec3( de(p-e.xyy), de(p-e.yxy), de(p-e.yyx) ));

#elif METHOD == 2
    // by iq - less efficient, 6 evaluations
    vec3 eps = vec3(EPSILON,0.0,0.0);
    return normalize( vec3(
                          de(p+eps.xyy) - de(p-eps.xyy),
                          de(p+eps.yxy) - de(p-eps.yxy),
                          de(p+eps.yyx) - de(p-eps.yyx)));
#endif
}

float sharp_shadow( in vec3 ro, in vec3 rd, float mint, float maxt ){
    for( float t=mint; t<maxt; )    {
        float h = de(ro + rd*t);
        if( h<0.001 )
            return 0.0;
        t += h;
    }
    return 1.0;
}

float soft_shadow( in vec3 ro, in vec3 rd, float mint, float maxt, float k /*higher is sharper*/ ){
    float res = 1.0;
    float ph = 1e20;
    for( float t=mint; t<maxt; )
    {
        float h = de(ro + rd*t);
        if( h<EPSILON )
            return 0.0;
        float y = h*h/(2.0*ph);
        float d = sqrt(h*h-y*y);
        res = min( res, k*d/max(0.0,t-y) );
        ph = h;
        t += h;
    }
    // return res;
    res = clamp( res, 0.0, 1.0 );
    return res*res*(3.0-2.0*res);
}

vec3 visibility_only_lighting(int lightnum, vec3 hitloc){
    vec3 shadow_rd, lightpos, lightcol;
    float mint, maxt, sharpness;

    switch(lightnum){
        case 1: lightpos = lightPos1; lightcol = lightCol1d; sharpness = shadow1; break;
        case 2: lightpos = lightPos2; lightcol = lightCol2d; sharpness = shadow2; break;
        case 3: lightpos = lightPos3; lightcol = lightCol3d; sharpness = shadow3; break;
        default: break;
    }

    shadow_rd = normalize(lightpos-hitloc);

    mint = EPSILON;
    maxt = distance(hitloc, lightpos);

    if(sharpness > 99)
        return lightcol * sharp_shadow(hitloc, shadow_rd, mint, maxt);
    else
        return lightcol * soft_shadow(hitloc, shadow_rd, mint, maxt, sharpness);
}

vec3 phong_lighting(int lightnum, vec3 hitloc, vec3 norm, vec3 eye_pos){


    vec3 shadow_rd, lightpos, lightcoldiff, lightcolspec;
    float mint, maxt, lightspecpow, sharpness;

    switch(lightnum){ // eventually handle these as uniform vector inputs, to handle more than three
        case 1:
            lightpos     = eye_pos + lightPos1 * (basis_x + basis_y + basis_z);
            lightcoldiff = lightCol1d;
            lightcolspec = lightCol1s;
            lightspecpow = specpower1;
            sharpness    = shadow1;
            break;
        case 2:
            lightpos     = eye_pos + lightPos2 * (basis_x + basis_y + basis_z);
            lightcoldiff = lightCol2d;
            lightcolspec = lightCol2s;
            lightspecpow = specpower2;
            sharpness    = shadow2;
            break;
        case 3:
            lightpos     = eye_pos + lightPos3 * (basis_x + basis_y + basis_z);
            lightcoldiff = lightCol3d;
            lightcolspec = lightCol3s;
            lightspecpow = specpower3;
            sharpness    = shadow3;
            break;
        default:
            break;
    }

    mint = EPSILON;
    maxt = distance(hitloc, lightpos);

    /*vec3 l = -normalize(hitloc - lightpos);
    vec3 v = normalize(hitloc - eye_pos);
    vec3 n = normalize(norm);
    vec3 r = normalize(reflect(l, n));

    diffuse_component = occlusion_term * dattenuation_term * max(dot(n, l),0.) * lightcoldiff;
    specular_component = (dot(n,l)>0) ? occlusion_term * dattenuation_term * pow(max(dot(r,v),0.),lightspecpow) * lightcolspec : vec3(0);
    */

    vec3 l = normalize(lightpos - hitloc);
    vec3 v = normalize(eye_pos - hitloc);
    vec3 h = normalize(l+v);
    vec3 n = normalize(norm);

    // then continue with the phong calculation
    vec3 diffuse_component, specular_component;

    // check occlusion with the soft/sharp shadow
    float occlusion_term;

    if(sharpness > 99)
        occlusion_term = sharp_shadow(hitloc, l, mint, maxt);
    else
        occlusion_term = soft_shadow(hitloc, l, mint, maxt, sharpness);

    float dattenuation_term = 1./pow(distance(hitloc, lightpos), 1.1);

    diffuse_component = occlusion_term * dattenuation_term * max(dot(n, l), 0.) * lightcoldiff;
    specular_component = (dot(n,l) > 0) ? occlusion_term * dattenuation_term * ((lightspecpow+2)/(2*M_PI)) * pow(max(dot(n,h),0.),lightspecpow) * lightcolspec : vec3(0);

    return diffuse_component + specular_component;
}


float calcAO( in vec3 pos, in vec3 nor )
{
    float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float h = 0.001 + 0.15*float(i)/4.0;
        float d = de( pos + h*nor );
        occ += (h-d)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 1.5*occ, 0.0, 1.0 );
}

// By TekF... getting a crash trying to use this (default value used was 0.5 degree)
// void BarrelDistortion( inout vec3 ray, float degree )
// {
// 	ray.z /= degree;
// 	ray.z = ( ray.z*ray.z - dot(ray.xy,ray.xy) );
// 	ray.z = degree*sqrt(ray.z);
// }


// spherical camera projection from wrighter
vec3 getRdSpherical ( vec2 uv ){
	// polar coords
	uv = vec2(atan(uv.y,uv.x),length(uv));
	uv += 0.5;
	uv.y *= PI;
	// parametrized sphere
	return normalize(vec3(cos(uv.y)*cos(uv.x),sin(uv.y),cos(uv.y)*sin(uv.x)));
}


void main()
{

    // imageStore(current, ivec2(gl_GlobalInvocationID.xy), uvec4( 120, 45, 12, 255 ));

    vec4 col = vec4(0, 0, 0, 1);
    float dresult_avg = 0.;

    for(int x = 0; x < AA; x++)
    for(int y = 0; y < AA; y++)
    {
        vec2 offset = vec2(float(x), float(y)) / float(AA) - 0.5;

        vec2 pixcoord = (vec2(gl_GlobalInvocationID.xy + offset)-vec2(imageSize(current)/2.)) / vec2(imageSize(current)/2.);
        vec3 ro = ray_origin;

        float aspect_ratio;
        // aspect_ratio = 1.618;
        aspect_ratio = float(imageSize(current).x) / float(imageSize(current).y);
        pixcoord.x *= aspect_ratio;
        
        vec3 rd = normalize(pixcoord.x*basis_x + pixcoord.y*basis_y + (1./fov)*basis_z);

		// spherical rays
		// vec3 rd = getRdSpherical( pixcoord * 0.75 );
		// rd = rd.x * basis_x + rd.y * basis_y + rd.z * basis_z;

        escape = 0.;
        float dresult = raymarch(ro, rd);
        float escape_result = escape;

        // vec3 lightpos = vec3(8.); pR(lightpos.xz, time);
        vec3 lightpos = vec3(2*sin(time), 2., 2*cos(time));

        vec3 hitpos = ro+dresult*rd;
        vec3 normal = norm(hitpos);

        vec3 shadow_ro = hitpos+normal*EPSILON*2.;

        vec3 sresult1 = vec3(0.);
        vec3 sresult2 = vec3(0.);
        vec3 sresult3 = vec3(0.);

        sresult1 = phong_lighting(1, hitpos, normal, ro) * flickerfactor1;
        // sresult2 = phong_lighting(2, hitpos, normal, ro) * flickerfactor2;
        // sresult3 = phong_lighting(3, hitpos, normal, ro) * flickerfactor3;

        // vec3 temp = ((norm(hitpos)/2.)+vec3(0.5)); // visualizing normal vector

        vec3 palatte_read = 0.4 * basic_diffuse * pal( escape_result, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,1.0),vec3(0.0,0.10,0.20) );

        // apply lighting
        // vec3 temp = basic_diffuse + sresult1 + sresult2  + sresult3;
        // vec3 temp = palatte_read + sresult1 + sresult2  + sresult3;
        vec3 temp = palatte_read * (sresult1 + sresult2  + sresult3);


        temp *= ((1./AO_scale) * calcAO(shadow_ro, normal)); // ambient occlusion calculation

        // // do the depth scaling here
        // // compute the depth scale term
        // float depth_term = depth_scale * dresult;
        dresult_avg += dresult;
        // switch(depth_falloff)
        // {
        //     case 0: depth_term = 0.;
        //     case 1: depth_term = 2.-2.*(1./(1.-depth_term)); break;
        //     case 2: depth_term = 1.-(1./(1+0.1*depth_term*depth_term)); break;
        //     case 3: depth_term = (1-pow(depth_term/30., 1.618)); break;

        //     case 4: depth_term = clamp(exp(0.25*depth_term-3.), 0., 10.); break;
        //     case 5: depth_term = exp(0.25*depth_term-3.); break;
        //     case 6: depth_term = exp( -0.002 * depth_term * depth_term * depth_term ); break;
        //     case 7: depth_term = exp(-0.6*max(depth_term-3., 0.0)); break;

        //     case 8: depth_term = (sqrt(depth_term)/8.) * depth_term; break;
        //     case 9: depth_term = sqrt(depth_term/9.); break;
        //     case 10: depth_term = pow(depth_term/10., 2.); break;
        //     default: break;
        // }
        // // do a mix here, between col and the fog color, with the selected depth falloff term
        // temp.rgb = mix(temp.rgb, fog_color.rgb, depth_term);

        col.rgb += temp;
    }

    col.rgb /= float(AA*AA);
    dresult_avg /= float(AA*AA);

    dresult_avg *= depth_scale;

    // compute the depth scale term
    float depth_term;

    switch(depth_falloff)
    {
        case 0: depth_term = 2.-2.*(1./(1.-dresult_avg));
            col.rgb = mix(col.rgb, fog_color.rgb, depth_term);
            break;
        case 1: depth_term = 1.-(1./(1+0.1*dresult_avg*dresult_avg));
            col.rgb = mix(col.rgb, fog_color.rgb, depth_term);
            break;
        case 2: depth_term = (1-pow(dresult_avg/30., 1.618));
            col.rgb = mix(col.rgb, fog_color.rgb, depth_term);
            break;

        case 3: depth_term = clamp(exp(0.25*dresult_avg-3.), 0., 10.);
            col.rgb = mix(col.rgb, fog_color.rgb, depth_term);
            break;
        case 4: depth_term = exp(0.25*dresult_avg-3.);
            col.rgb = mix(col.rgb, fog_color.rgb, depth_term);
            break;
        case 5: depth_term = exp( -0.002 * dresult_avg * dresult_avg * dresult_avg );
            col.rgb = mix(col.rgb, fog_color.rgb, depth_term);
            break;
        case 6: depth_term = exp(-0.6*max(dresult_avg-3., 0.0));
            col.rgb = mix(col.rgb, fog_color.rgb, depth_term);
            break;

        case 7: depth_term = (sqrt(dresult_avg)/8.) * dresult_avg; break;
            col.rgb = mix(col.rgb, fog_color.rgb, depth_term);
            break;
        case 8: depth_term = sqrt(dresult_avg/9.); break;
            col.rgb = mix(col.rgb, fog_color.rgb, depth_term);
            break;
        case 9: depth_term = pow(dresult_avg/10., 2.); break;
            col.rgb = mix(col.rgb, fog_color.rgb, depth_term);
            break;
        case 10: col.rgb += 1./(1.+exp(-2.*(dresult_avg*0.1-2.))) * fog_color.rgb;
 // col.rgb = mix(col.rgb, fog_color.rgb, depth_term);
            break;
        case 11: depth_term = dresult_avg/MAX_DIST;
            col.rgb = mix(col.rgb, fog_color.rgb, depth_term);
            break;
        default: break;
    }

    // color stuff happens here, because the imageStore will be quantizing to 8 bit
    // tonemapping
    switch(tonemap_mode)
    {
        case 0: // None (Linear)
            break;
        case 1: // ACES (Narkowicz 2015)
            col.xyz = cheapo_aces_approx(col.xyz);
            break;
        case 2: // Unreal Engine 3
            col.xyz = pow(tonemap_unreal3(col.xyz), vec3(2.8));
            break;
        case 3: // Unreal Engine 4
            col.xyz = aces_fitted(col.xyz);
            break;
        case 4: // Uncharted 2
            col.xyz = uncharted2(col.xyz);
            break;
        case 5: // Gran Turismo
            col.xyz = tonemap_uchimura(col.xyz);
            break;
        case 6: // Modified Gran Turismo
            col.xyz = tonemap_uchimura2(col.xyz);
            break;
        case 7: // Rienhard
            col.xyz = rienhard(col.xyz);
            break;
        case 8: // Modified Rienhard
            col.xyz = rienhard2(col.xyz);
            break;
        case 9: // jt_tonemap
            col.xyz = jt_toneMap(col.xyz);
            break;
        case 10: // robobo1221s
            col.xyz = robobo1221sTonemap(col.xyz);
            break;
        case 11: // robo
            col.xyz = roboTonemap(col.xyz);
            break;
        case 12: // jodieRobo
            col.xyz = jodieRoboTonemap(col.xyz);
            break;
        case 13: // jodieRobo2
            col.xyz = jodieRobo2ElectricBoogaloo(col.xyz);
            break;
        case 14: // jodieReinhard
            col.xyz = jodieReinhardTonemap(col.xyz);
            break;
        case 15: // jodieReinhard2
            col.xyz = jodieReinhard2ElectricBoogaloo(col.xyz);
            break;
    }
    // gamma correction
    col.rgb = pow(col.rgb, vec3(1/gamma));

    imageStore(current, ivec2(gl_GlobalInvocationID.xy), uvec4( col.r*255, col.g*255, col.b*255, col.a*255 ));
}


