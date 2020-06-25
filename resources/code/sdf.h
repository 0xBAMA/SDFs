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
	
	void create_window();
	void draw_everything();
	
	void quit();
	
	bool pquit;
		
};

#endif
