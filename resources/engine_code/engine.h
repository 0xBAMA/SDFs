#ifndef ENGINE
#define ENGINE

#include "includes.h"

class engine
{
public:

	engine();
	~engine();

private:

	SDL_Window * window;
	SDL_GLContext GLcontext;

	ImVec4 clear_color;
	int total_screen_width, total_screen_height;

    GLuint display_texture;
    GLuint display_shader;
	GLuint display_vao;
	GLuint display_vbo;

	// dither patterns
	GLuint dither_bayer;
	GLuint dither_blue;

	// compute shaders
	GLuint dither_shader;
	GLuint raymarch_shader;

	// main functions
	void create_window();
	void gl_setup();
	void draw_everything();

	// to confirm quit
	bool quitconfirm = false;
	void quit_conf(bool *open);

	// main loop control
	void quit();
	bool pquit = false;

public:
// OBJ data (per mesh)
	void load_OBJ(std::string filename);

	// this may vary in length
	std::vector<glm::vec4> vertices;
	std::vector<glm::vec3> normals;
	std::vector<glm::vec3> texcoords;

	// these should all be the same length, the number of triangles
	std::vector<glm::ivec3> triangle_indices;
	std::vector<glm::ivec3> normal_indices;
	std::vector<glm::ivec3> texcoord_indices;
		
};

#endif
