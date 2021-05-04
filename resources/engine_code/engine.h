#ifndef ENGINE
#define ENGINE

#include "includes.h"

// These defines are used to simplify the ImGui::Combo things in engine_utils.cc
 
// colorspace
#define RGB       0
#define SRGB      1
#define XYZ       2
#define XYY       3
#define HSV       4
#define HSL       5
#define HCY       6
#define YPBPR     7
#define YPBPR601  8
#define YCBCR1    9
#define YCBCR2    10
#define YCCBCCRC  11
#define YCOCG     12
#define BCH       13
#define CHROMAMAX 14
#define OKLAB     15

// dither pattern
#define BAYER             1
#define STATIC_MONO_BLUE  2
#define STATIC_RGB_BLUE   3
#define CYCLED_MONO_BLUE  4
#define CYCLED_RGB_BLUE   5
#define UNIFORM           6
#define INTERLEAVED_GRAD  7
#define VLACHOS           8
#define TRIANGLE_VLACHOS  9
#define TRIANGLE_MONO     10
#define TRIANGLE_RGB      11

// dither methodology
#define BITCRUSH      0
#define EXPONENTIAL   1

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
	float rotation_about_x = 0.;
	float rotation_about_y = 0.;
	float rotation_about_z = 0.;

	// base color
	glm::vec3 basic_diffuse = glm::vec3(45./255., 45./255., 45./255.);

	void animate_lights(float t);
		
	// light colors
	glm::vec3 lightCol1d = glm::vec3( 0.6f, 0.6f, 0.6f);
	glm::vec3 lightCol2d = glm::vec3( 0.75f, 0.3f, 0.0f);
	glm::vec3 lightCol3d = glm::vec3( 0.1f, 0.35f, 0.65f);

	// light positions
	glm::vec3 lightPos1 = glm::vec3( 2.3, 1, 1);
	glm::vec3 lightPos2 = glm::vec3( 1, 2.3, 1);
	glm::vec3 lightPos3 = glm::vec3( 1, 1, 2.3);

	// position
	glm::vec3 position = glm::vec3(1., 1., 1.);

	glm::vec3 basis_x, basis_y, basis_z;

	float gamma_correction = 0.675;
	int current_tmode = 6;
    int current_colorspace = CHROMAMAX;
    int current_noise_func = BAYER;
    int current_dither_mode = EXPONENTIAL;

	int num_bits = 4; 
		
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
