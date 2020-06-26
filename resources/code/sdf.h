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

    GLuint bitcrush_dither_shader;

	void create_window();
	void gl_setup();
	void draw_everything();
	
	void quit();
	
	bool pquit;
		
};

#endif
