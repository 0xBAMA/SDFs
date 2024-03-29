#ifndef INCLUDES
#define INCLUDES

#include <stdio.h>

// stl includes
#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstdlib>
#include <ctime>
#include <deque>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <numeric>
#include <random>
#include <sstream>
#include <string>
#include <vector>
//#include <filesystem> //c++20 support not quite universal yet

// iostream aliases
using std::cerr;
using std::cin;
using std::cout;

using std::endl;
using std::flush;

// pi definition
constexpr double pi = 3.14159265358979323846;

// vector math library GLM
#define GLM_FORCE_SWIZZLE
#define GLM_SWIZZLE_XYZW
#include "../glm/glm.hpp"                  //general vector types
#include "../glm/gtc/matrix_transform.hpp" // for glm::ortho
#include "../glm/gtc/type_ptr.hpp"         //to send matricies gpu-side
#include "../glm/gtx/rotate_vector.hpp"
#include "../glm/gtx/transform.hpp"
#include "../glm/gtx/quaternion.hpp"
#include "../glm/gtx/string_cast.hpp"

// not sure as to the utility of this
#define GLX_GLEXT_PROTOTYPES

// GUI library (dear ImGUI)
#include "../ocornut_imgui/TextEditor.h"
#include "../ocornut_imgui/imgui.h"
#include "../ocornut_imgui/imgui_impl_opengl3.h"
#include "../ocornut_imgui/imgui_impl_sdl.h"

// OpenGL Loader
#include "../ocornut_imgui/gl3w.h"

// SDL includes - windowing, gl context, system info
#include <SDL2/SDL.h>
// allows you to run OpenGL inside of SDL2
#include <SDL2/SDL_opengl.h>

// png loading library - very powerful
#include "../lodev_lodePNG/lodepng.h"

// shader #include prepreocessor
#include "shaders/lib/stb_include.h"

// shader compilation wrapper
#include "shaders/lib/shader.h"

// up to 3d perlin noise generation
#include "../perlin/perlin.h"

// blue noise
#include "../kajott_bluenoise/bluenoise.h"

// diamond square heightmap generation
#include "../mafford_diamond_square/diamond_square.h"

// Brent Werness' Voxel Automata Terrain
#include "../VAT/VAT.h"

// Niels Lohmann - JSON for Modern C++
#include "../nlohmann_JSON/json.hpp"
using json = nlohmann::json;

// #define WIDTH 720
#define WIDTH 640
#define HEIGHT 480

// #define WIDTH 2048
// #define HEIGHT 2048


#endif
