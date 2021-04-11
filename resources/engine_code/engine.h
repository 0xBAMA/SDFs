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

// OpenGL Handles
    GLuint display_texture;
    GLuint display_shader;
	GLuint display_vao;
	GLuint display_vbo;

	// dither patterns
	GLuint dither_bayer;
	GLuint dither_blue;

	// compute shaders
	GLuint dither_shader;
	GLuint blue_cycle_shader;
	GLuint raymarch_shader;

// raymarcher state
	// rotation
	float rotation_about_x = 0.69;
	float rotation_about_y = -2.61;
	float rotation_about_z = 0.;

	// light colors
	glm::vec3 lightCol1 = glm::vec3(115./255.,  28./255.,  28./255.);
	glm::vec3 lightCol2 = glm::vec3( 30./255., 150./255.,  82./255.);
	glm::vec3 lightCol3 = glm::vec3( 72./255.,  18./255., 122./255.);

	// light positions
	glm::vec3 lightPos1 = glm::vec3(0,0,0);
	glm::vec3 lightPos2 = glm::vec3(0,0,0);
	glm::vec3 lightPos3 = glm::vec3(0,0,0);

	// position
	glm::vec3 position = glm::vec3(2.95, 2.5, 2.5);


// main loop functions
	void create_window();
	void gl_setup();
	void draw_everything();
	void start_imgui();
	void end_imgui();
	void control_window();

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
