#ifndef SDF
#define SDF

#include "includes.h"

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

    GLuint bitcrush_dither_shader;
    bool dither;

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
