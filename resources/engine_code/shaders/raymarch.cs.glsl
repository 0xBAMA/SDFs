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




// tonemapping stuff
// APPROX
// --------------------------
vec3 cheapo_aces_approx(vec3 v)
{
	v *= 0.6f;
	float a = 2.51f;
	float b = 0.03f;
	float c = 2.43f;
	float d = 0.59f;
	float e = 0.14f;
	return clamp((v*(a*v+b))/(v*(c*v+d)+e), 0.0f, 1.0f);
}


// OFFICIAL
// --------------------------
mat3 aces_input_matrix = mat3(
	0.59719f, 0.35458f, 0.04823f,
	0.07600f, 0.90834f, 0.01566f,
	0.02840f, 0.13383f, 0.83777f
);

mat3 aces_output_matrix = mat3(
	1.60475f, -0.53108f, -0.07367f,
	-0.10208f,  1.10813f, -0.00605f,
	-0.00327f, -0.07276f,  1.07602f
);

vec3 mul(mat3 m, vec3 v)
{
	float x = m[0][0] * v[0] + m[0][1] * v[1] + m[0][2] * v[2];
	float y = m[1][0] * v[1] + m[1][1] * v[1] + m[1][2] * v[2];
	float z = m[2][0] * v[1] + m[2][1] * v[1] + m[2][2] * v[2];
	return vec3(x, y, z);
}

vec3 rtt_and_odt_fit(vec3 v)
{
	vec3 a = v * (v + 0.0245786f) - 0.000090537f;
	vec3 b = v * (0.983729f * v + 0.4329510f) + 0.238081f;
	return a / b;
}

vec3 aces_fitted(vec3 v)
{
	v = mul(aces_input_matrix, v);
	v = rtt_and_odt_fit(v);
	return mul(aces_output_matrix, v);
}


vec3 uncharted2(vec3 v)
{
    float A = 0.15;
    float B = 0.50;
    float C = 0.10;
    float D = 0.20;
    float E = 0.02;
    float F = 0.30;
    float W = 11.2;

    float ExposureBias = 2.0f;
    v *= ExposureBias;

    return (((v*(A*v+C*B)+D*E)/(v*(A*v+B)+D*F))-E/F)*(((W*(A*W+C*B)+D*E)/(W*(A*W+B)+D*F))-E/F);
}

vec3 rienhard(vec3 v)
{
    return v / (vec3(1.) + v);
}

vec3 rienhard2(vec3 v)
{
    const float L_white = 4.0;
    return (v * (vec3(1.) + v / (L_white * L_white))) / (1.0 + v);
}

vec3 tonemap_uchimura(vec3 v)
{
    const float P = 1.0;  // max display brightness
    const float a = 1.0;  // contrast
    const float m = 0.22; // linear section start
    const float l = 0.4;  // linear section length
    const float c = 1.33; // black
    const float b = 0.0;  // pedestal

    // Uchimura 2017, "HDR theory and practice"
    // Math: https://www.desmos.com/calculator/gslcdxvipg
    // Source: https://www.slideshare.net/nikuque/hdr-theory-and-practicce-jp
    float l0 = ((P - m) * l) / a;
    float L0 = m - m / a;
    float L1 = m + (1.0 - m) / a;
    float S0 = m + l0;
    float S1 = m + a * l0;
    float C2 = (a * P) / (P - S1);
    float CP = -C2 / P;

    vec3 w0 = 1.0 - smoothstep(0.0, m, v);
    vec3 w2 = step(m + l0, v);
    vec3 w1 = 1.0 - w0 - w2;

    vec3 T = m * pow(v / m, vec3(c)) + vec3(b);
    vec3 S = P - (P - S1) * exp(CP * (v - S0));
    vec3 L = m + a * (v - vec3(m));

    return T * w0 + L * w1 + S * w2;
}

vec3 tonemap_uchimura2(vec3 v)
{
    const float P = 1.0;  // max display brightness
    const float a = 1.7;  // contrast
    const float m = 0.1; // linear section start
    const float l = 0.0;  // linear section length
    const float c = 1.33; // black
    const float b = 0.0;  // pedestal

    float l0 = ((P - m) * l) / a;
    float L0 = m - m / a;
    float L1 = m + (1.0 - m) / a;
    float S0 = m + l0;
    float S1 = m + a * l0;
    float C2 = (a * P) / (P - S1);
    float CP = -C2 / P;

    vec3 w0 = 1.0 - smoothstep(0.0, m, v);
    vec3 w2 = step(m + l0, v);
    vec3 w1 = 1.0 - w0 - w2;

    vec3 T = m * pow(v / m, vec3(c)) + vec3(b);
    vec3 S = P - (P - S1) * exp(CP * (v - S0));
    vec3 L = m + a * (v - vec3(m));

    return T * w0 + L * w1 + S * w2;
}

vec3 tonemap_unreal3(vec3 v)
{
    return v / (v + 0.155) * 1.019;
}


#define toLum(color) dot(color, vec3(.2125, .7154, .0721) )
#define lightAjust(a,b) ((1.-b)*(pow(1.-a,vec3(b+1.))-1.)+a)/b
#define reinhard(c,l) c * (l / (1. + l) / l)
vec3 jt_toneMap(vec3 x){
    float l = toLum(x);
    x = reinhard(x,l);
    float m = max(x.r,max(x.g,x.b));
    return min(lightAjust(x/m,m),x);
}
#undef toLum
#undef lightAjust
#undef reinhard


vec3 robobo1221sTonemap(vec3 x){
	return sqrt(x / (x + 1.0f / x)) - abs(x) + x;
}

vec3 roboTonemap(vec3 c){
    return c/sqrt(1.+c*c);
}

vec3 jodieRoboTonemap(vec3 c){
    float l = dot(c, vec3(0.2126, 0.7152, 0.0722));
    vec3 tc=c/sqrt(c*c+1.);
    return mix(c/sqrt(l*l+1.),tc,tc);
}

vec3 jodieRobo2ElectricBoogaloo(const vec3 color){
    float luma = dot(color, vec3(.2126, .7152, .0722));

    // tonemap curve goes on this line
    // (I used robo here)
    vec4 rgbl = vec4(color, luma) * inversesqrt(luma*luma + 1.);

    vec3 mappedColor = rgbl.rgb;
    float mappedLuma = rgbl.a;

    float channelMax = max(max(max(
    	mappedColor.r,
    	mappedColor.g),
    	mappedColor.b),
    	1.);

    // this is just the simplified/optimised math
    // of the more human readable version below
    return (
        (mappedLuma*mappedColor-mappedColor)-
        (channelMax*mappedLuma-mappedLuma)
    )/(mappedLuma-channelMax);

    const vec3 white = vec3(1);

    // prevent clipping
    vec3 clampedColor = mappedColor/channelMax;

    // x is how much white needs to be mixed with
    // clampedColor so that its luma equals the
    // mapped luma
    //
    // mix(mappedLuma/channelMax,1.,x) = mappedLuma;
    //
    // mix is defined as
    // x*(1-a)+y*a
    // https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/mix.xhtml
    //
    // (mappedLuma/channelMax)*(1.-x)+1.*x = mappedLuma

    float x = (mappedLuma - mappedLuma*channelMax)
        /(mappedLuma - channelMax);
    return mix(clampedColor, white, x);
}

vec3 jodieReinhardTonemap(vec3 c){
    float l = dot(c, vec3(0.2126, 0.7152, 0.0722));
    vec3 tc=c/(c+1.);
    return mix(c/(l+1.),tc,tc);
}

vec3 jodieReinhard2ElectricBoogaloo(const vec3 color){
    float luma = dot(color, vec3(.2126, .7152, .0722));

    // tonemap curve goes on this line
    // (I used reinhard here)
    vec4 rgbl = vec4(color, luma) / (luma + 1.);

    vec3 mappedColor = rgbl.rgb;
    float mappedLuma = rgbl.a;

    float channelMax = max(max(max(
    	mappedColor.r,
    	mappedColor.g),
    	mappedColor.b),
    	1.);

    // this is just the simplified/optimised math
    // of the more human readable version below
    return ((mappedLuma*mappedColor-mappedColor)-(channelMax*mappedLuma-mappedLuma))/(mappedLuma-channelMax);

    const vec3 white = vec3(1);

    // prevent clipping
    vec3 clampedColor = mappedColor/channelMax;

    // x is how much white needs to be mixed with
    // clampedColor so that its luma equals the
    // mapped luma
    //
    // mix(mappedLuma/channelMax,1.,x) = mappedLuma;
    //
    // mix is defined as
    // x*(1-a)+y*a
    // https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/mix.xhtml
    //
    // (mappedLuma/channelMax)*(1.-x)+1.*x = mappedLuma

    float x = (mappedLuma - mappedLuma*channelMax)
        /(mappedLuma - channelMax);
    return mix(clampedColor, white, x);
}





//  ╔╦╗┬ ┬┬╔═╗╦    ╦ ╦┌┬┐┬┬  ┬┌┬┐┬┌─┐┌─┐
//   ║ ││││║ ╦║    ║ ║ │ ││  │ │ │├┤ └─┐
//   ╩ └┴┘┴╚═╝╩═╝  ╚═╝ ┴ ┴┴─┘┴ ┴ ┴└─┘└─┘
//
// Description : Array and textureless GLSL 2D simplex noise function.
//      Author : Ian McEwan, Ashima Arts.
//  Maintainer : stegu
//     Lastmod : 20110822 (ijm)
//     License : Copyright (C) 2011 Ashima Arts. All rights reserved.
//               Distributed under the MIT License. See LICENSE file.
//               https://github.com/ashima/webgl-noise
//               https://github.com/stegu/webgl-noise
//

// (sqrt(5) - 1)/4 = F4, used once below
#define F4 0.309016994374947451
float mod289(float x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec2  mod289(vec2 x) {return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec3  mod289(vec3 x) {return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4  mod289(vec4 x) {return x - floor(x * (1.0 / 289.0)) * 289.0;}
float permute(float x){return mod289(((x*34.0)+1.0)*x);}
vec3  permute(vec3 x) {return mod289(((x*34.0)+1.0)*x);}
vec4  permute(vec4 x) {return mod289(((x*34.0)+1.0)*x);}
float taylorInvSqrt(float r){return 1.79284291400159 - 0.85373472095314 * r;}
vec4  taylorInvSqrt(vec4 r) {return 1.79284291400159 - 0.85373472095314 * r;}
float snoise2D(vec2 v){
  const vec4 C = vec4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
                      0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
                     -0.577350269189626,  // -1.0 + 2.0 * C.x
                      0.024390243902439); // 1.0 / 41.0
  // First corner
  vec2 i  = floor(v + dot(v, C.yy) );
  vec2 x0 = v -   i + dot(i, C.xx);

  // Other corners
  vec2 i1;
  //i1.x = step( x0.y, x0.x ); // x0.x > x0.y ? 1.0 : 0.0
  //i1.y = 1.0 - i1.x;
  i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
  // x0 = x0 - 0.0 + 0.0 * C.xx ;
  // x1 = x0 - i1 + 1.0 * C.xx ;
  // x2 = x0 - 1.0 + 2.0 * C.xx ;
  vec4 x12 = x0.xyxy + C.xxzz;
  x12.xy -= i1;

  // Permutations
  i = mod289(i); // Avoid truncation effects in permutation
  vec3 p = permute(permute(i.y + vec3(0.0, i1.y, 1.0 )) + i.x + vec3(0.0, i1.x, 1.0 ));
  vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
  m = m * m;
  m = m * m;

  // Gradients: 41 points uniformly over a line, mapped onto a diamond.
  // The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)

  vec3 x = 2.0 * fract(p * C.www) - 1.0;
  vec3 h = abs(x) - 0.5;
  vec3 ox = floor(x + 0.5);
  vec3 a0 = x - ox;

  // Normalise gradients implicitly by scaling m
  // Approximation of: m *= inversesqrt( a0*a0 + h*h );
  m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );

  // Compute final noise value at P
  vec3 g;
  g.x  = a0.x  * x0.x  + h.x  * x0.y;
  g.yz = a0.yz * x12.xz + h.yz * x12.yw;
  return 130.0 * dot(m, g);
}

float snoise3D(vec3 v){
  const vec2 C = vec2(1.0 / 6.0, 1.0 / 3.0);
  const vec4 D = vec4(0.0, 0.5, 1.0, 2.0);

  // First corner
  vec3 i  = floor(v + dot(v, C.yyy) );
  vec3 x0 =   v - i + dot(i, C.xxx) ;

  // Other corners
  vec3 g = step(x0.yzx, x0.xyz);
  vec3 l = 1.0 - g;
  vec3 i1 = min( g.xyz, l.zxy );
  vec3 i2 = max( g.xyz, l.zxy );

  //   x0 = x0 - 0.0 + 0.0 * C.xxx;
  //   x1 = x0 - i1  + 1.0 * C.xxx;
  //   x2 = x0 - i2  + 2.0 * C.xxx;
  //   x3 = x0 - 1.0 + 3.0 * C.xxx;
  vec3 x1 = x0 - i1 + C.xxx;
  vec3 x2 = x0 - i2 + C.yyy; // 2.0*C.x = 1/3 = C.y
  vec3 x3 = x0 - D.yyy;      // -1.0+3.0*C.x = -0.5 = -D.y

  // Permutations
  i = mod289(i);
  vec4 p = permute( permute( permute(
             i.z + vec4(0.0, i1.z, i2.z, 1.0 ))
           + i.y + vec4(0.0, i1.y, i2.y, 1.0 ))
           + i.x + vec4(0.0, i1.x, i2.x, 1.0 ));

  // Gradients: 7x7 points over a square, mapped onto an octahedron.
  // The ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)
  float n_ = 0.142857142857; // 1.0/7.0
  vec3  ns = n_ * D.wyz - D.xzx;

  vec4 j = p - 49.0 * floor(p * ns.z * ns.z);  //  mod(p,7*7)

  vec4 x_ = floor(j * ns.z);
  vec4 y_ = floor(j - 7.0 * x_ );    // mod(j,N)

  vec4 x = x_ *ns.x + ns.yyyy;
  vec4 y = y_ *ns.x + ns.yyyy;
  vec4 h = 1.0 - abs(x) - abs(y);

  vec4 b0 = vec4( x.xy, y.xy );
  vec4 b1 = vec4( x.zw, y.zw );

  //vec4 s0 = vec4(lessThan(b0,0.0))*2.0 - 1.0;
  //vec4 s1 = vec4(lessThan(b1,0.0))*2.0 - 1.0;
  vec4 s0 = floor(b0)*2.0 + 1.0;
  vec4 s1 = floor(b1)*2.0 + 1.0;
  vec4 sh = -step(h, vec4(0.0));

  vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
  vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;

  vec3 p0 = vec3(a0.xy,h.x);
  vec3 p1 = vec3(a0.zw,h.y);
  vec3 p2 = vec3(a1.xy,h.z);
  vec3 p3 = vec3(a1.zw,h.w);

  //Normalise gradients
  vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
  p0 *= norm.x;
  p1 *= norm.y;
  p2 *= norm.z;
  p3 *= norm.w;

  // Mix final noise value
  vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
  m = m * m;
  return 42.0 * dot( m*m, vec4( dot(p0,x0), dot(p1,x1), dot(p2,x2), dot(p3,x3) ) );
}
vec4 grad4(float j, vec4 ip){
  const vec4 ones = vec4(1.0, 1.0, 1.0, -1.0);
  vec4 p,s;

  p.xyz = floor( fract (vec3(j) * ip.xyz) * 7.0) * ip.z - 1.0;
  p.w = 1.5 - dot(abs(p.xyz), ones.xyz);
  s = vec4(lessThan(p, vec4(0.0)));
  p.xyz = p.xyz + (s.xyz*2.0 - 1.0) * s.www;

  return p;
}
float snoise4D(vec4 v){
  const vec4  C = vec4( 0.138196601125011,  // (5 - sqrt(5))/20  G4
                        0.276393202250021,  // 2 * G4
                        0.414589803375032,  // 3 * G4
                       -0.447213595499958); // -1 + 4 * G4

  // First corner
  vec4 i  = floor(v + dot(v, vec4(F4)) );
  vec4 x0 = v -   i + dot(i, C.xxxx);

  // Other corners

  // Rank sorting originally contributed by Bill Licea-Kane, AMD (formerly ATI)
  vec4 i0;
  vec3 isX = step( x0.yzw, x0.xxx );
  vec3 isYZ = step( x0.zww, x0.yyz );
  //  i0.x = dot( isX, vec3( 1.0 ) );
  i0.x = isX.x + isX.y + isX.z;
  i0.yzw = 1.0 - isX;
  //  i0.y += dot( isYZ.xy, vec2( 1.0 ) );
  i0.y += isYZ.x + isYZ.y;
  i0.zw += 1.0 - isYZ.xy;
  i0.z += isYZ.z;
  i0.w += 1.0 - isYZ.z;

  // i0 now contains the unique values 0,1,2,3 in each channel
  vec4 i3 = clamp( i0, 0.0, 1.0 );
  vec4 i2 = clamp( i0-1.0, 0.0, 1.0 );
  vec4 i1 = clamp( i0-2.0, 0.0, 1.0 );

  //  x0 = x0 - 0.0 + 0.0 * C.xxxx
  //  x1 = x0 - i1  + 1.0 * C.xxxx
  //  x2 = x0 - i2  + 2.0 * C.xxxx
  //  x3 = x0 - i3  + 3.0 * C.xxxx
  //  x4 = x0 - 1.0 + 4.0 * C.xxxx
  vec4 x1 = x0 - i1 + C.xxxx;
  vec4 x2 = x0 - i2 + C.yyyy;
  vec4 x3 = x0 - i3 + C.zzzz;
  vec4 x4 = x0 + C.wwww;

  // Permutations
  i = mod289(i);
  float j0 = permute( permute( permute( permute(i.w) + i.z) + i.y) + i.x);
  vec4 j1 = permute( permute( permute( permute (
             i.w + vec4(i1.w, i2.w, i3.w, 1.0 ))
           + i.z + vec4(i1.z, i2.z, i3.z, 1.0 ))
           + i.y + vec4(i1.y, i2.y, i3.y, 1.0 ))
           + i.x + vec4(i1.x, i2.x, i3.x, 1.0 ));

  // Gradients: 7x7x6 points over a cube, mapped onto a 4-cross polytope
  // 7*7*6 = 294, which is close to the ring size 17*17 = 289.
  vec4 ip = vec4(1.0/294.0, 1.0/49.0, 1.0/7.0, 0.0) ;

  vec4 p0 = grad4(j0,   ip);
  vec4 p1 = grad4(j1.x, ip);
  vec4 p2 = grad4(j1.y, ip);
  vec4 p3 = grad4(j1.z, ip);
  vec4 p4 = grad4(j1.w, ip);

  // Normalise gradients
  vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
  p0 *= norm.x;
  p1 *= norm.y;
  p2 *= norm.z;
  p3 *= norm.w;
  p4 *= taylorInvSqrt(dot(p4,p4));

  // Mix contributions from the five corners
  vec3 m0 = max(0.6 - vec3(dot(x0,x0), dot(x1,x1), dot(x2,x2)), 0.0);
  vec2 m1 = max(0.6 - vec2(dot(x3,x3), dot(x4,x4)            ), 0.0);
  m0 = m0 * m0;
  m1 = m1 * m1;
  return 49.0 * ( dot(m0*m0, vec3( dot( p0, x0 ), dot( p1, x1 ), dot( p2, x2 )))
                + dot(m1*m1, vec2( dot( p3, x3 ), dot( p4, x4 ) ) ) ) ;
}
float fsnoise      (vec2 c){return fract(sin(dot(c, vec2(12.9898, 78.233))) * 43758.5453);}
float fsnoiseDigits(vec2 c){return fract(sin(dot(c, vec2(0.129898, 0.78233))) * 437.585453);}
vec3 hsv(float h, float s, float v){
    vec4 t = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(vec3(h) + t.xyz) * 6.0 - vec3(t.w));
    return v * mix(vec3(t.x), clamp(p - vec3(t.x), 0.0, 1.0), s);
}
mat2 rotate2D(float r){
    return mat2(cos(r), sin(r), -sin(r), cos(r));
}
mat3 rotate3D(float angle, vec3 axis){
    vec3 a = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float r = 1.0 - c;
    return mat3(
        a.x * a.x * r + c,
        a.y * a.x * r + a.z * s,
        a.z * a.x * r - a.y * s,
        a.x * a.y * r - a.z * s,
        a.y * a.y * r + c,
        a.z * a.y * r + a.x * s,
        a.x * a.z * r + a.y * s,
        a.y * a.z * r - a.x * s,
        a.z * a.z * r + c
    );
}






////////////////////////////////////////////////////////////////
//
//                           HG_SDF
//
//     GLSL LIBRARY FOR BUILDING SIGNED DISTANCE BOUNDS
//
//     version 2021-01-29
//
//     Check https://mercury.sexy/hg_sdf for updates
//     and usage examples. Send feedback to spheretracing@mercury.sexy.
//
//     Brought to you by MERCURY https://mercury.sexy
//
//
//
// Released as Creative Commons Attribution-NonCommercial (CC BY-NC)
//
////////////////////////////////////////////////////////////////
//
// How to use this:
//
// 1. Build some system to #include glsl files in each other.
//   Include this one at the very start. Or just paste everywhere.
// 2. Build a sphere tracer. See those papers:
//   * "Sphere Tracing" https://link.springer.com/article/10.1007%2Fs003710050084
//   * "Enhanced Sphere Tracing" http://diglib.eg.org/handle/10.2312/stag.20141233.001-008
//   * "Improved Ray Casting of Procedural Distance Bounds" https://www.bibsonomy.org/bibtex/258e85442234c3ace18ba4d89de94e57d
//   The Raymnarching Toolbox Thread on pouet can be helpful as well
//   http://www.pouet.net/topic.php?which=7931&page=1
//   and contains links to many more resources.
// 3. Use the tools in this library to build your distance bound f().
// 4. ???
// 5. Win a compo.
//
// (6. Buy us a beer or a good vodka or something, if you like.)
//
////////////////////////////////////////////////////////////////
//
// Table of Contents:
//
// * Helper functions and macros
// * Collection of some primitive objects
// * Domain Manipulation operators
// * Object combination operators
//
////////////////////////////////////////////////////////////////
//
// Why use this?
//
// The point of this lib is that everything is structured according
// to patterns that we ended up using when building geometry.
// It makes it more easy to write code that is reusable and that somebody
// else can actually understand. Especially code on Shadertoy (which seems
// to be what everybody else is looking at for "inspiration") tends to be
// really ugly. So we were forced to do something about the situation and
// release this lib ;)
//
// Everything in here can probably be done in some better way.
// Please experiment. We'd love some feedback, especially if you
// use it in a scene production.
//
// The main patterns for building geometry this way are:
// * Stay Lipschitz continuous. That means: don't have any distance
//   gradient larger than 1. Try to be as close to 1 as possible -
//   Distances are euclidean distances, don't fudge around.
//   Underestimating distances will happen. That's why calling
//   it a "distance bound" is more correct. Don't ever multiply
//   distances by some value to "fix" a Lipschitz continuity
//   violation. The invariant is: each fSomething() function returns
//   a correct distance bound.
// * Use very few primitives and combine them as building blocks
//   using combine opertors that preserve the invariant.
// * Multiply objects by repeating the domain (space).
//   If you are using a loop inside your distance function, you are
//   probably doing it wrong (or you are building boring fractals).
// * At right-angle intersections between objects, build a new local
//   coordinate system from the two distances to combine them in
//   interesting ways.
// * As usual, there are always times when it is best to not follow
//   specific patterns.
//
////////////////////////////////////////////////////////////////
//
// FAQ
//
// Q: Why is there no sphere tracing code in this lib?
// A: Because our system is way too complex and always changing.
//    This is the constant part. Also we'd like everyone to
//    explore for themselves.
//
// Q: This does not work when I paste it into Shadertoy!!!!
// A: Yes. It is GLSL, not GLSL ES. We like real OpenGL
//    because it has way more features and is more likely
//    to work compared to browser-based WebGL. We recommend
//    you consider using OpenGL for your productions. Most
//    of this can be ported easily though.
//
// Q: How do I material?
// A: We recommend something like this:
//    Write a material ID, the distance and the local coordinate
//    p into some global variables whenever an object's distance is
//    smaller than the stored distance. Then, at the end, evaluate
//    the material to get color, roughness, etc., and do the shading.
//
// Q: I found an error. Or I made some function that would fit in
//    in this lib. Or I have some suggestion.
// A: Awesome! Drop us a mail at spheretracing@mercury.sexy.
//
// Q: Why is this not on github?
// A: Because we were too lazy. If we get bugged about it enough,
//    we'll do it.
//
// Q: Your license sucks for me.
// A: Oh. What should we change it to?
//
// Q: I have trouble understanding what is going on with my distances.
// A: Some visualization of the distance field helps. Try drawing a
//    plane that you can sweep through your scene with some color
//    representation of the distance field at each point and/or iso
//    lines at regular intervals. Visualizing the length of the
//    gradient (or better: how much it deviates from being equal to 1)
//    is immensely helpful for understanding which parts of the
//    distance field are broken.
//
////////////////////////////////////////////////////////////////






////////////////////////////////////////////////////////////////
//
//             HELPER FUNCTIONS/MACROS
//
////////////////////////////////////////////////////////////////

#define PI 3.14159265
#define TAU (2*PI)
#define PHI (sqrt(5)*0.5 + 0.5)

// Clamp to [0,1] - this operation is free under certain circumstances.
// For further information see
// http://www.humus.name/Articles/Persson_LowLevelThinking.pdf and
// http://www.humus.name/Articles/Persson_LowlevelShaderOptimization.pdf
#define saturate(x) clamp(x, 0, 1)

// Sign function that doesn't return 0
float sgn(float x) {
	return (x<0)?-1:1;
}

vec2 sgn(vec2 v) {
	return vec2((v.x<0)?-1:1, (v.y<0)?-1:1);
}

float square (float x) {
	return x*x;
}

vec2 square (vec2 x) {
	return x*x;
}

vec3 square (vec3 x) {
	return x*x;
}

float lengthSqr(vec3 x) {
	return dot(x, x);
}


// Maximum/minumum elements of a vector
float vmax(vec2 v) {
	return max(v.x, v.y);
}

float vmax(vec3 v) {
	return max(max(v.x, v.y), v.z);
}

float vmax(vec4 v) {
	return max(max(v.x, v.y), max(v.z, v.w));
}

float vmin(vec2 v) {
	return min(v.x, v.y);
}

float vmin(vec3 v) {
	return min(min(v.x, v.y), v.z);
}

float vmin(vec4 v) {
	return min(min(v.x, v.y), min(v.z, v.w));
}




////////////////////////////////////////////////////////////////
//
//             PRIMITIVE DISTANCE FUNCTIONS
//
////////////////////////////////////////////////////////////////
//
// Conventions:
//
// Everything that is a distance function is called fSomething.
// The first argument is always a point in 2 or 3-space called <p>.
// Unless otherwise noted, (if the object has an intrinsic "up"
// side or direction) the y axis is "up" and the object is
// centered at the origin.
//
////////////////////////////////////////////////////////////////

float fSphere(vec3 p, float r) {
	return length(p) - r;
}

// Plane with normal n (n is normalized) at some distance from the origin
float fPlane(vec3 p, vec3 n, float distanceFromOrigin) {
	return dot(p, n) + distanceFromOrigin;
}

// Cheap Box: distance to corners is overestimated
float fBoxCheap(vec3 p, vec3 b) { //cheap box
	return vmax(abs(p) - b);
}

// Box: correct distance to corners
float fBox(vec3 p, vec3 b) {
	vec3 d = abs(p) - b;
	return length(max(d, vec3(0))) + vmax(min(d, vec3(0)));
}

// Same as above, but in two dimensions (an endless box)
float fBox2Cheap(vec2 p, vec2 b) {
	return vmax(abs(p)-b);
}

float fBox2(vec2 p, vec2 b) {
	vec2 d = abs(p) - b;
	return length(max(d, vec2(0))) + vmax(min(d, vec2(0)));
}


// Endless "corner"
float fCorner (vec2 p) {
	return length(max(p, vec2(0))) + vmax(min(p, vec2(0)));
}

// Blobby ball object. You've probably seen it somewhere. This is not a correct distance bound, beware.
float fBlob(vec3 p) {
	p = abs(p);
	if (p.x < max(p.y, p.z)) p = p.yzx;
	if (p.x < max(p.y, p.z)) p = p.yzx;
	float b = max(max(max(
		dot(p, normalize(vec3(1, 1, 1))),
		dot(p.xz, normalize(vec2(PHI+1, 1)))),
		dot(p.yx, normalize(vec2(1, PHI)))),
		dot(p.xz, normalize(vec2(1, PHI))));
	float l = length(p);
	return l - 1.5 - 0.2 * (1.5 / 2)* cos(min(sqrt(1.01 - b / l)*(PI / 0.25), PI));
}

// Cylinder standing upright on the xz plane
float fCylinder(vec3 p, float r, float height) {
	float d = length(p.xz) - r;
	d = max(d, abs(p.y) - height);
	return d;
}

// Capsule: A Cylinder with round caps on both sides
float fCapsule(vec3 p, float r, float c) {
	return mix(length(p.xz) - r, length(vec3(p.x, abs(p.y) - c, p.z)) - r, step(c, abs(p.y)));
}

// Distance to line segment between <a> and <b>, used for fCapsule() version 2below
float fLineSegment(vec3 p, vec3 a, vec3 b) {
	vec3 ab = b - a;
	float t = saturate(dot(p - a, ab) / dot(ab, ab));
	return length((ab*t + a) - p);
}

// Capsule version 2: between two end points <a> and <b> with radius r
float fCapsule(vec3 p, vec3 a, vec3 b, float r) {
	return fLineSegment(p, a, b) - r;
}

// Torus in the XZ-plane
float fTorus(vec3 p, float smallRadius, float largeRadius) {
	return length(vec2(length(p.xz) - largeRadius, p.y)) - smallRadius;
}

// A circle line. Can also be used to make a torus by subtracting the smaller radius of the torus.
float fCircle(vec3 p, float r) {
	float l = length(p.xz) - r;
	return length(vec2(p.y, l));
}

// A circular disc with no thickness (i.e. a cylinder with no height).
// Subtract some value to make a flat disc with rounded edge.
float fDisc(vec3 p, float r) {
	float l = length(p.xz) - r;
	return l < 0 ? abs(p.y) : length(vec2(p.y, l));
}

// Hexagonal prism, circumcircle variant
float fHexagonCircumcircle(vec3 p, vec2 h) {
	vec3 q = abs(p);
	return max(q.y - h.y, max(q.x*sqrt(3)*0.5 + q.z*0.5, q.z) - h.x);
	//this is mathematically equivalent to this line, but less efficient:
	//return max(q.y - h.y, max(dot(vec2(cos(PI/3), sin(PI/3)), q.zx), q.z) - h.x);
}

// Hexagonal prism, incircle variant
float fHexagonIncircle(vec3 p, vec2 h) {
	return fHexagonCircumcircle(p, vec2(h.x*sqrt(3)*0.5, h.y));
}

// Cone with correct distances to tip and base circle. Y is up, 0 is in the middle of the base.
float fCone(vec3 p, float radius, float height) {
	vec2 q = vec2(length(p.xz), p.y);
	vec2 tip = q - vec2(0, height);
	vec2 mantleDir = normalize(vec2(height, radius));
	float mantle = dot(tip, mantleDir);
	float d = max(mantle, -q.y);
	float projected = dot(tip, vec2(mantleDir.y, -mantleDir.x));

	// distance to tip
	if ((q.y > height) && (projected < 0)) {
		d = max(d, length(tip));
	}

	// distance to base ring
	if ((q.x > radius) && (projected > length(vec2(height, radius)))) {
		d = max(d, length(q - vec2(radius, 0)));
	}
	return d;
}

//
// "Generalized Distance Functions" by Akleman and Chen.
// see the Paper at https://www.viz.tamu.edu/faculty/ergun/research/implicitmodeling/papers/sm99.pdf
//
// This set of constants is used to construct a large variety of geometric primitives.
// Indices are shifted by 1 compared to the paper because we start counting at Zero.
// Some of those are slow whenever a driver decides to not unroll the loop,
// which seems to happen for fIcosahedron und fTruncatedIcosahedron on nvidia 350.12 at least.
// Specialized implementations can well be faster in all cases.
//

const vec3 GDFVectors[19] = vec3[](
	normalize(vec3(1, 0, 0)),
	normalize(vec3(0, 1, 0)),
	normalize(vec3(0, 0, 1)),

	normalize(vec3(1, 1, 1 )),
	normalize(vec3(-1, 1, 1)),
	normalize(vec3(1, -1, 1)),
	normalize(vec3(1, 1, -1)),

	normalize(vec3(0, 1, PHI+1)),
	normalize(vec3(0, -1, PHI+1)),
	normalize(vec3(PHI+1, 0, 1)),
	normalize(vec3(-PHI-1, 0, 1)),
	normalize(vec3(1, PHI+1, 0)),
	normalize(vec3(-1, PHI+1, 0)),

	normalize(vec3(0, PHI, 1)),
	normalize(vec3(0, -PHI, 1)),
	normalize(vec3(1, 0, PHI)),
	normalize(vec3(-1, 0, PHI)),
	normalize(vec3(PHI, 1, 0)),
	normalize(vec3(-PHI, 1, 0))
);

// Version with variable exponent.
// This is slow and does not produce correct distances, but allows for bulging of objects.
float fGDF(vec3 p, float r, float e, int begin, int end) {
	float d = 0;
	for (int i = begin; i <= end; ++i)
		d += pow(abs(dot(p, GDFVectors[i])), e);
	return pow(d, 1/e) - r;
}

// Version with without exponent, creates objects with sharp edges and flat faces
float fGDF(vec3 p, float r, int begin, int end) {
	float d = 0;
	for (int i = begin; i <= end; ++i)
		d = max(d, abs(dot(p, GDFVectors[i])));
	return d - r;
}

// Primitives follow:

float fOctahedron(vec3 p, float r, float e) {
	return fGDF(p, r, e, 3, 6);
}

float fDodecahedron(vec3 p, float r, float e) {
	return fGDF(p, r, e, 13, 18);
}

float fIcosahedron(vec3 p, float r, float e) {
	return fGDF(p, r, e, 3, 12);
}

float fTruncatedOctahedron(vec3 p, float r, float e) {
	return fGDF(p, r, e, 0, 6);
}

float fTruncatedIcosahedron(vec3 p, float r, float e) {
	return fGDF(p, r, e, 3, 18);
}

float fOctahedron(vec3 p, float r) {
	return fGDF(p, r, 3, 6);
}

float fDodecahedron(vec3 p, float r) {
	return fGDF(p, r, 13, 18);
}

float fIcosahedron(vec3 p, float r) {
	return fGDF(p, r, 3, 12);
}

float fTruncatedOctahedron(vec3 p, float r) {
	return fGDF(p, r, 0, 6);
}

float fTruncatedIcosahedron(vec3 p, float r) {
	return fGDF(p, r, 3, 18);
}


////////////////////////////////////////////////////////////////
//
//                DOMAIN MANIPULATION OPERATORS
//
////////////////////////////////////////////////////////////////
//
// Conventions:
//
// Everything that modifies the domain is named pSomething.
//
// Many operate only on a subset of the three dimensions. For those,
// you must choose the dimensions that you want manipulated
// by supplying e.g. <p.x> or <p.zx>
//
// <inout p> is always the first argument and modified in place.
//
// Many of the operators partition space into cells. An identifier
// or cell index is returned, if possible. This return value is
// intended to be optionally used e.g. as a random seed to change
// parameters of the distance functions inside the cells.
//
// Unless stated otherwise, for cell index 0, <p> is unchanged and cells
// are centered on the origin so objects don't have to be moved to fit.
//
//
////////////////////////////////////////////////////////////////



// Rotate around a coordinate axis (i.e. in a plane perpendicular to that axis) by angle <a>.
// Read like this: R(p.xz, a) rotates "x towards z".
// This is fast if <a> is a compile-time constant and slower (but still practical) if not.
void pR(inout vec2 p, float a) {
	p = cos(a)*p + sin(a)*vec2(p.y, -p.x);
}

// Shortcut for 45-degrees rotation
void pR45(inout vec2 p) {
	p = (p + vec2(p.y, -p.x))*sqrt(0.5);
}

// Repeat space along one axis. Use like this to repeat along the x axis:
// <float cell = pMod1(p.x,5);> - using the return value is optional.
float pMod1(inout float p, float size) {
	float halfsize = size*0.5;
	float c = floor((p + halfsize)/size);
	p = mod(p + halfsize, size) - halfsize;
	return c;
}

// Same, but mirror every second cell so they match at the boundaries
float pModMirror1(inout float p, float size) {
	float halfsize = size*0.5;
	float c = floor((p + halfsize)/size);
	p = mod(p + halfsize,size) - halfsize;
	p *= mod(c, 2.0)*2 - 1;
	return c;
}

// Repeat the domain only in positive direction. Everything in the negative half-space is unchanged.
float pModSingle1(inout float p, float size) {
	float halfsize = size*0.5;
	float c = floor((p + halfsize)/size);
	if (p >= 0)
		p = mod(p + halfsize, size) - halfsize;
	return c;
}

// Repeat only a few times: from indices <start> to <stop> (similar to above, but more flexible)
float pModInterval1(inout float p, float size, float start, float stop) {
	float halfsize = size*0.5;
	float c = floor((p + halfsize)/size);
	p = mod(p+halfsize, size) - halfsize;
	if (c > stop) { //yes, this might not be the best thing numerically.
		p += size*(c - stop);
		c = stop;
	}
	if (c <start) {
		p += size*(c - start);
		c = start;
	}
	return c;
}


// Repeat around the origin by a fixed angle.
// For easier use, num of repetitions is use to specify the angle.
float pModPolar(inout vec2 p, float repetitions) {
	float angle = 2*PI/repetitions;
	float a = atan(p.y, p.x) + angle/2.;
	float r = length(p);
	float c = floor(a/angle);
	a = mod(a,angle) - angle/2.;
	p = vec2(cos(a), sin(a))*r;
	// For an odd number of repetitions, fix cell index of the cell in -x direction
	// (cell index would be e.g. -5 and 5 in the two halves of the cell):
	if (abs(c) >= (repetitions/2)) c = abs(c);
	return c;
}

// Repeat in two dimensions
vec2 pMod2(inout vec2 p, vec2 size) {
	vec2 c = floor((p + size*0.5)/size);
	p = mod(p + size*0.5,size) - size*0.5;
	return c;
}

// Same, but mirror every second cell so all boundaries match
vec2 pModMirror2(inout vec2 p, vec2 size) {
	vec2 halfsize = size*0.5;
	vec2 c = floor((p + halfsize)/size);
	p = mod(p + halfsize, size) - halfsize;
	p *= mod(c,vec2(2))*2 - vec2(1);
	return c;
}

// Same, but mirror every second cell at the diagonal as well
vec2 pModGrid2(inout vec2 p, vec2 size) {
	vec2 c = floor((p + size*0.5)/size);
	p = mod(p + size*0.5, size) - size*0.5;
	p *= mod(c,vec2(2))*2 - vec2(1);
	p -= size/2;
	if (p.x > p.y) p.xy = p.yx;
	return floor(c/2);
}

// Repeat in three dimensions
vec3 pMod3(inout vec3 p, vec3 size) {
	vec3 c = floor((p + size*0.5)/size);
	p = mod(p + size*0.5, size) - size*0.5;
	return c;
}

// Mirror at an axis-aligned plane which is at a specified distance <dist> from the origin.
float pMirror (inout float p, float dist) {
	float s = sgn(p);
	p = abs(p)-dist;
	return s;
}

// Mirror in both dimensions and at the diagonal, yielding one eighth of the space.
// translate by dist before mirroring.
vec2 pMirrorOctant (inout vec2 p, vec2 dist) {
	vec2 s = sgn(p);
	pMirror(p.x, dist.x);
	pMirror(p.y, dist.y);
	if (p.y > p.x)
		p.xy = p.yx;
	return s;
}

// Reflect space at a plane
float pReflect(inout vec3 p, vec3 planeNormal, float offset) {
	float t = dot(p, planeNormal)+offset;
	if (t < 0) {
		p = p - (2*t)*planeNormal;
	}
	return sgn(t);
}


////////////////////////////////////////////////////////////////
//
//             OBJECT COMBINATION OPERATORS
//
////////////////////////////////////////////////////////////////
//
// We usually need the following boolean operators to combine two objects:
// Union: OR(a,b)
// Intersection: AND(a,b)
// Difference: AND(a,!b)
// (a and b being the distances to the objects).
//
// The trivial implementations are min(a,b) for union, max(a,b) for intersection
// and max(a,-b) for difference. To combine objects in more interesting ways to
// produce rounded edges, chamfers, stairs, etc. instead of plain sharp edges we
// can use combination operators. It is common to use some kind of "smooth minimum"
// instead of min(), but we don't like that because it does not preserve Lipschitz
// continuity in many cases.
//
// Naming convention: since they return a distance, they are called fOpSomething.
// The different flavours usually implement all the boolean operators above
// and are called fOpUnionRound, fOpIntersectionRound, etc.
//
// The basic idea: Assume the object surfaces intersect at a right angle. The two
// distances <a> and <b> constitute a new local two-dimensional coordinate system
// with the actual intersection as the origin. In this coordinate system, we can
// evaluate any 2D distance function we want in order to shape the edge.
//
// The operators below are just those that we found useful or interesting and should
// be seen as examples. There are infinitely more possible operators.
//
// They are designed to actually produce correct distances or distance bounds, unlike
// popular "smooth minimum" operators, on the condition that the gradients of the two
// SDFs are at right angles. When they are off by more than 30 degrees or so, the
// Lipschitz condition will no longer hold (i.e. you might get artifacts). The worst
// case is parallel surfaces that are close to each other.
//
// Most have a float argument <r> to specify the radius of the feature they represent.
// This should be much smaller than the object size.
//
// Some of them have checks like "if ((-a < r) && (-b < r))" that restrict
// their influence (and computation cost) to a certain area. You might
// want to lift that restriction or enforce it. We have left it as comments
// in some cases.
//
// usage example:
//
// float fTwoBoxes(vec3 p) {
//   float box0 = fBox(p, vec3(1));
//   float box1 = fBox(p-vec3(1), vec3(1));
//   return fOpUnionChamfer(box0, box1, 0.2);
// }
//
////////////////////////////////////////////////////////////////


// The "Chamfer" flavour makes a 45-degree chamfered edge (the diagonal of a square of size <r>):
float fOpUnionChamfer(float a, float b, float r) {
	return min(min(a, b), (a - r + b)*sqrt(0.5));
}

// Intersection has to deal with what is normally the inside of the resulting object
// when using union, which we normally don't care about too much. Thus, intersection
// implementations sometimes differ from union implementations.
float fOpIntersectionChamfer(float a, float b, float r) {
	return max(max(a, b), (a + r + b)*sqrt(0.5));
}

// Difference can be built from Intersection or Union:
float fOpDifferenceChamfer (float a, float b, float r) {
	return fOpIntersectionChamfer(a, -b, r);
}

// The "Round" variant uses a quarter-circle to join the two objects smoothly:
float fOpUnionRound(float a, float b, float r) {
	vec2 u = max(vec2(r - a,r - b), vec2(0));
	return max(r, min (a, b)) - length(u);
}

float fOpIntersectionRound(float a, float b, float r) {
	vec2 u = max(vec2(r + a,r + b), vec2(0));
	return min(-r, max (a, b)) + length(u);
}

float fOpDifferenceRound (float a, float b, float r) {
	return fOpIntersectionRound(a, -b, r);
}


// The "Columns" flavour makes n-1 circular columns at a 45 degree angle:
float fOpUnionColumns(float a, float b, float r, float n) {
	if ((a < r) && (b < r)) {
		vec2 p = vec2(a, b);
		float columnradius = r*sqrt(2)/((n-1)*2+sqrt(2));
		pR45(p);
		p.x -= sqrt(2)/2*r;
		p.x += columnradius*sqrt(2);
		if (mod(n,2) == 1) {
			p.y += columnradius;
		}
		// At this point, we have turned 45 degrees and moved at a point on the
		// diagonal that we want to place the columns on.
		// Now, repeat the domain along this direction and place a circle.
		pMod1(p.y, columnradius*2);
		float result = length(p) - columnradius;
		result = min(result, p.x);
		result = min(result, a);
		return min(result, b);
	} else {
		return min(a, b);
	}
}

float fOpDifferenceColumns(float a, float b, float r, float n) {
	a = -a;
	float m = min(a, b);
	//avoid the expensive computation where not needed (produces discontinuity though)
	if ((a < r) && (b < r)) {
		vec2 p = vec2(a, b);
		float columnradius = r*sqrt(2)/n/2.0;
		columnradius = r*sqrt(2)/((n-1)*2+sqrt(2));

		pR45(p);
		p.y += columnradius;
		p.x -= sqrt(2)/2*r;
		p.x += -columnradius*sqrt(2)/2;

		if (mod(n,2) == 1) {
			p.y += columnradius;
		}
		pMod1(p.y,columnradius*2);

		float result = -length(p) + columnradius;
		result = max(result, p.x);
		result = min(result, a);
		return -min(result, b);
	} else {
		return -m;
	}
}

float fOpIntersectionColumns(float a, float b, float r, float n) {
	return fOpDifferenceColumns(a,-b,r, n);
}

// The "Stairs" flavour produces n-1 steps of a staircase:
// much less stupid version by paniq
float fOpUnionStairs(float a, float b, float r, float n) {
	float s = r/n;
	float u = b-r;
	return min(min(a,b), 0.5 * (u + a + abs ((mod (u - a + s, 2 * s)) - s)));
}

// We can just call Union since stairs are symmetric.
float fOpIntersectionStairs(float a, float b, float r, float n) {
	return -fOpUnionStairs(-a, -b, r, n);
}

float fOpDifferenceStairs(float a, float b, float r, float n) {
	return -fOpUnionStairs(-a, b, r, n);
}


// Similar to fOpUnionRound, but more lipschitz-y at acute angles
// (and less so at 90 degrees). Useful when fudging around too much
// by MediaMolecule, from Alex Evans' siggraph slides
float fOpUnionSoft(float a, float b, float r) {
	float e = max(r - abs(a - b), 0);
	return min(a, b) - e*e*0.25/r;
}


// produces a cylindical pipe that runs along the intersection.
// No objects remain, only the pipe. This is not a boolean operator.
float fOpPipe(float a, float b, float r) {
	return length(vec2(a, b)) - r;
}

// first object gets a v-shaped engraving where it intersect the second
float fOpEngrave(float a, float b, float r) {
	return max(a, (a + r - abs(b))*sqrt(0.5));
}

// first object gets a capenter-style groove cut out
float fOpGroove(float a, float b, float ra, float rb) {
	return max(a, min(a + ra, rb - abs(b)));
}

// first object gets a capenter-style tongue attached
float fOpTongue(float a, float b, float ra, float rb) {
	return min(a, max(a - ra, abs(b) - rb));
}

//  ╔═╗┌┐┌┌┬┐  ╦ ╦╔═╗    ╔═╗╔╦╗╔═╗  ╔═╗┌─┐┌┬┐┌─┐
//  ║╣ │││ ││  ╠═╣║ ╦    ╚═╗ ║║╠╣   ║  │ │ ││├┤
//  ╚═╝┘└┘─┴┘  ╩ ╩╚═╝────╚═╝═╩╝╚    ╚═╝└─┘─┴┘└─┘


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

vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
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














// by gaz - hard crash on desktop
float fractal_de123(vec3 p){
    float i,g,e,s,l;
    vec3 q;
    s=2.;
    p=abs(mod(p-1.,2.)-1.)-1.;
    for(int j=0;j<8;j++)
        p=1.-abs(abs(abs(p-5.)-2.)-2.),
        p=p*(l=-1.4/dot(p,p))-vec3(.2),
        s*=abs(l);
    return length(p.xy)/s;
}






// by gaz - hard crash on desktop
float fractal_de129(vec3 p){
    float i,g,e,s,l;
    vec3 q;
    q=p;
    s=1.;
    for(int j=0;j++<4;)
        p=mod(p-1.,2.)-1.,
        l=2./dot(p,p),
        p*=l,
        s*=l;
    return length(p.xy)/s;
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



float de(vec3 p){

    return JosKleinian(p);

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
        vec3 rd = normalize(aspect_ratio*pixcoord.x*basis_x + pixcoord.y*basis_y + (1./fov)*basis_z);

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
