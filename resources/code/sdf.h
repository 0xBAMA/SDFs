#ifndef SDF
#define SDF

#include "includes.h"

enum dithertype
{
NONE  = 0,
RGB   = 1,
HSL   = 2,
HSV   = 3,
YUV   = 4,
sRGB  = 5,
XYZ   = 6,
xyY   = 7,
HCY   = 8,
YCbCr = 9
};

class sdf
{
public:

	sdf();
	~sdf();
	
private:

	SDL_Window * window;
	SDL_GLContext GLcontext;
	
	ImVec4 clear_color;
	
    GLuint display_shader;
    GLuint display_vao;
    GLuint display_vbo;
    GLuint display_image2D;

    GLuint raymarch_shader;
    bool animate_lighting;

    GLuint bitcrush_dither_shaderRGB;
    GLuint bitcrush_dither_shaderHSV;
    GLuint bitcrush_dither_shaderHSL;
    GLuint bitcrush_dither_shaderYUV;
    GLuint bitcrush_dither_shadersRGB;
    GLuint bitcrush_dither_shaderXYZ;
    GLuint bitcrush_dither_shaderxyY;
    GLuint bitcrush_dither_shaderHCY;
    GLuint bitcrush_dither_shaderYCbCr;
    dithertype dither;

    float rotation_about_y;
    float rotation_about_x;
    float rotation_about_z;

	void create_window();
	void gl_setup();
	void draw_everything();
	
	void quit();
	
	bool pquit;
		
};

#endif
