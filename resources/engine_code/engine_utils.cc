#include "engine.h"
// This contains the lower level code

// TinyOBJLoader - This has to be included in a .cc file, so it's here for right
// now
#define TINYOBJLOADER_IMPLEMENTATION
// #define TINYOBJLOADER_USE_DOUBLE
#include "../TinyOBJLoader/tiny_obj_loader.h"
// tinyobj callbacks
//  user_data is passed in as void, then cast as 'engine' class to push
//  vertices, normals, texcoords, index, material info
void vertex_cb(void *user_data, float x, float y, float z, float w) {
  engine *t = reinterpret_cast<engine *>(user_data);

  t->vertices.push_back(glm::vec4(x, y, z, w));
}

void normal_cb(void *user_data, float x, float y, float z) {
  engine *t = reinterpret_cast<engine *>(user_data);

  t->normals.push_back(glm::vec3(x, y, z));
}

void texcoord_cb(void *user_data, float x, float y, float z) {
  engine *t = reinterpret_cast<engine *>(user_data);

  t->texcoords.push_back(glm::vec3(x, y, z));
}

void index_cb(void *user_data, tinyobj::index_t *indices, int num_indices) {
  engine *t = reinterpret_cast<engine *>(user_data);

  if (num_indices == 3) // this is a triangle
  {
    // OBJ uses 1-indexing, convert to 0-indexing
    t->triangle_indices.push_back(glm::ivec3(indices[0].vertex_index - 1,
                                             indices[1].vertex_index - 1,
                                             indices[2].vertex_index - 1));
    t->normal_indices.push_back(glm::ivec3(indices[0].normal_index - 1,
                                           indices[1].normal_index - 1,
                                           indices[2].normal_index - 1));
    t->texcoord_indices.push_back(glm::ivec3(indices[0].texcoord_index - 1,
                                             indices[1].texcoord_index - 1,
                                             indices[2].texcoord_index - 1));
  }

  // lines, points have a different number of indicies
  //  might want to handle these
}

void usemtl_cb(void *user_data, const char *name, int material_idx) {
  engine *t = reinterpret_cast<engine *>(user_data);
  (void)t;
}

void mtllib_cb(void *user_data, const tinyobj::material_t *materials,
               int num_materials) {
  engine *t = reinterpret_cast<engine *>(user_data);
  (void)t;
}

void group_cb(void *user_data, const char **names, int num_names) {
  engine *t = reinterpret_cast<engine *>(user_data);
  (void)t;
}

void object_cb(void *user_data, const char *name) {
  engine *t = reinterpret_cast<engine *>(user_data);
  (void)t;
}

// this is where the callbacks are used
void engine::load_OBJ(std::string filename) {
  tinyobj::callback_t cb;
  cb.vertex_cb = vertex_cb;
  cb.normal_cb = normal_cb;
  cb.texcoord_cb = texcoord_cb;
  cb.index_cb = index_cb;
  cb.usemtl_cb = usemtl_cb;
  cb.mtllib_cb = mtllib_cb;
  cb.group_cb = group_cb;
  cb.object_cb = object_cb;

  std::string warn;
  std::string err;

  std::ifstream ifs(filename.c_str());
  tinyobj::MaterialFileReader mtlReader(".");

  bool ret =
      tinyobj::LoadObjWithCallback(ifs, cb, this, &mtlReader, &warn, &err);

  if (!warn.empty()) {
    std::cout << "WARN: " << warn << std::endl;
  }

  if (!err.empty()) {
    std::cerr << err << std::endl;
  }

  if (!ret) {
    std::cerr << "Failed to parse .obj" << std::endl;
  }

  cout << "vertex list length: " << vertices.size() << endl;
  cout << "normal list length: " << normals.size() << endl;
  cout << "texcoord list length: " << texcoords.size() << endl;

  cout << "vertex index list length: " << triangle_indices.size() << endl;
  cout << "normal index length: " << normal_indices.size() << endl;
  cout << "texcoord index length: " << texcoord_indices.size() << endl;
}

void engine::create_window() {
  if (SDL_Init(SDL_INIT_EVERYTHING) != 0) {
    printf("Error: %s\n", SDL_GetError());
  }

  SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
  SDL_GL_SetAttribute(SDL_GL_ACCELERATED_VISUAL, 1);
  SDL_GL_SetAttribute(SDL_GL_RED_SIZE, 8);
  SDL_GL_SetAttribute(SDL_GL_GREEN_SIZE, 8);
  SDL_GL_SetAttribute(SDL_GL_BLUE_SIZE, 8);
  SDL_GL_SetAttribute(SDL_GL_ALPHA_SIZE, 8);

  // depth testing not relevant
  // SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);
  // SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, 8);

  // multisampling not relevant
  // SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, 1);
  // SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 8);

  // this is how you query the screen resolution
  SDL_DisplayMode dm;
  SDL_GetDesktopDisplayMode(0, &dm);

  // pulling these out because I'm going to try to span the whole screen with
  // the window, in a way that's flexible on different resolution screens
  total_screen_width = dm.w;
  total_screen_height = dm.h;

  cout << "creating window...";

  window = SDL_CreateWindow(
      "Raymarcher", 0, 0, WIDTH*2, HEIGHT*2,
      SDL_WINDOW_OPENGL | SDL_WINDOW_HIDDEN | SDL_WINDOW_RESIZABLE);
  SDL_ShowWindow(window);

  cout << "done." << endl;

  cout << "setting up OpenGL context...";
  // OpenGL 4.3 + GLSL version 430
  const char *glsl_version = "#version 430";
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_FLAGS, 0);
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 4);
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
  GLcontext = SDL_GL_CreateContext(window);

  SDL_GL_MakeCurrent(window, GLcontext);
  SDL_GL_SetSwapInterval(1); // Enable vsync
  // SDL_GL_SetSwapInterval(0); // explicitly disable vsync

  if (gl3wInit() != 0)
    fprintf(stderr, "Failed to initialize OpenGL loader!\n");

  // depth testing not relevant
  // glEnable(GL_DEPTH_TEST);
  // glEnable(GL_LINE_SMOOTH);

  glPointSize(3.0);
  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

  // Setup Dear ImGui context
  IMGUI_CHECKVERSION();
  ImGui::CreateContext();
  ImGuiIO &io = ImGui::GetIO();
  (void)io; // void cast prevents unused variable warning

  // enable docking
  io.ConfigFlags |= ImGuiConfigFlags_DockingEnable;

  // adds a font, as default
  // io.Fonts->AddFontFromFileTTF("resources/fonts/star_trek/titles/Jefferies.ttf",
  // 15);
  // io.Fonts->AddFontFromFileTTF("resources/fonts/star_trek/titles/TNG_Title.ttf",
  // 16);

  ImGui::StyleColorsDark();

  // Setup Platform/Renderer bindings
  ImGui_ImplSDL2_InitForOpenGL(window, GLcontext);
  ImGui_ImplOpenGL3_Init(glsl_version);

  clear_color = ImVec4(75.0f / 255.0f, 75.0f / 255.0f, 75.0f / 255.0f, 1.0f); // initial value for clear color

  // really excited by the fact imgui has an hsv picker to set this
  glClearColor(clear_color.x, clear_color.y, clear_color.z, clear_color.w);
  glClear(GL_COLOR_BUFFER_BIT);
  SDL_GL_SwapWindow(window);

  cout << "done." << endl;

  ImVec4 *colors = ImGui::GetStyle().Colors;
  colors[ImGuiCol_Text] = ImVec4(0.67f, 0.50f, 0.16f, 1.00f);
  colors[ImGuiCol_TextDisabled] = ImVec4(0.33f, 0.27f, 0.16f, 1.00f);
  colors[ImGuiCol_WindowBg] = ImVec4(0.10f, 0.05f, 0.00f, 0.85f);
  colors[ImGuiCol_ChildBg] = ImVec4(0.23f, 0.17f, 0.02f, 0.05f);
  colors[ImGuiCol_PopupBg] = ImVec4(0.30f, 0.12f, 0.06f, 0.94f);
  colors[ImGuiCol_Border] = ImVec4(0.25f, 0.18f, 0.09f, 0.33f);
  colors[ImGuiCol_BorderShadow] = ImVec4(0.33f, 0.15f, 0.02f, 0.17f);
  colors[ImGuiCol_FrameBg] = ImVec4(0.561f, 0.082f, 0.04f, 0.17f);
  colors[ImGuiCol_FrameBgHovered] = ImVec4(0.19f, 0.09f, 0.02f, 0.17f);
  colors[ImGuiCol_FrameBgActive] = ImVec4(0.25f, 0.12f, 0.01f, 0.78f);
  colors[ImGuiCol_TitleBg] = ImVec4(0.25f, 0.12f, 0.01f, 1.00f);
  colors[ImGuiCol_TitleBgActive] = ImVec4(0.33f, 0.15f, 0.02f, 1.00f);
  colors[ImGuiCol_TitleBgCollapsed] = ImVec4(0.25f, 0.12f, 0.01f, 1.00f);
  colors[ImGuiCol_MenuBarBg] = ImVec4(0.14f, 0.07f, 0.02f, 1.00f);
  colors[ImGuiCol_ScrollbarBg] = ImVec4(0.13f, 0.10f, 0.08f, 0.53f);
  colors[ImGuiCol_ScrollbarGrab] = ImVec4(0.25f, 0.12f, 0.01f, 0.78f);
  colors[ImGuiCol_ScrollbarGrabHovered] = ImVec4(0.33f, 0.15f, 0.02f, 1.00f);
  colors[ImGuiCol_ScrollbarGrabActive] = ImVec4(0.25f, 0.12f, 0.01f, 0.78f);
  colors[ImGuiCol_CheckMark] = ImVec4(0.69f, 0.45f, 0.11f, 1.00f);
  colors[ImGuiCol_SliderGrab] = ImVec4(0.28f, 0.18f, 0.06f, 1.00f);
  colors[ImGuiCol_SliderGrabActive] = ImVec4(0.36f, 0.22f, 0.06f, 1.00f);
  colors[ImGuiCol_Button] = ImVec4(0.25f, 0.12f, 0.01f, 0.78f);
  colors[ImGuiCol_ButtonHovered] = ImVec4(0.33f, 0.15f, 0.02f, 1.00f);
  colors[ImGuiCol_ButtonActive] = ImVec4(0.25f, 0.12f, 0.01f, 0.78f);
  colors[ImGuiCol_Header] = ImVec4(0.25f, 0.12f, 0.01f, 0.78f);
  colors[ImGuiCol_HeaderHovered] = ImVec4(0.33f, 0.15f, 0.02f, 1.00f);
  colors[ImGuiCol_HeaderActive] = ImVec4(0.25f, 0.12f, 0.01f, 0.78f);
  colors[ImGuiCol_Separator] = ImVec4(0.28f, 0.18f, 0.06f, 0.37f);
  colors[ImGuiCol_SeparatorHovered] = ImVec4(0.33f, 0.15f, 0.02f, 0.17f);
  colors[ImGuiCol_SeparatorActive] = ImVec4(0.42f, 0.18f, 0.06f, 0.17f);
  colors[ImGuiCol_ResizeGrip] = ImVec4(0.25f, 0.12f, 0.01f, 0.78f);
  colors[ImGuiCol_ResizeGripHovered] = ImVec4(0.33f, 0.15f, 0.02f, 1.00f);
  colors[ImGuiCol_ResizeGripActive] = ImVec4(0.25f, 0.12f, 0.01f, 0.78f);
  colors[ImGuiCol_Tab] = ImVec4(0.25f, 0.12f, 0.01f, 0.78f);
  colors[ImGuiCol_TabHovered] = ImVec4(0.33f, 0.15f, 0.02f, 1.00f);
  colors[ImGuiCol_TabActive] = ImVec4(0.34f, 0.14f, 0.01f, 1.00f);
  colors[ImGuiCol_TabUnfocused] = ImVec4(0.33f, 0.15f, 0.02f, 1.00f);
  colors[ImGuiCol_TabUnfocusedActive] = ImVec4(0.42f, 0.18f, 0.06f, 1.00f);
  colors[ImGuiCol_PlotLines] = ImVec4(0.61f, 0.61f, 0.61f, 1.00f);
  colors[ImGuiCol_PlotLinesHovered] = ImVec4(1.00f, 0.43f, 0.35f, 1.00f);
  colors[ImGuiCol_PlotHistogram] = ImVec4(0.90f, 0.70f, 0.00f, 1.00f);
  colors[ImGuiCol_PlotHistogramHovered] = ImVec4(1.00f, 0.60f, 0.00f, 1.00f);
  colors[ImGuiCol_TextSelectedBg] = ImVec4(0.06f, 0.03f, 0.01f, 0.78f);
  colors[ImGuiCol_DragDropTarget] = ImVec4(0.64f, 0.42f, 0.09f, 0.90f);
  colors[ImGuiCol_NavHighlight] = ImVec4(0.64f, 0.42f, 0.09f, 0.90f);
  colors[ImGuiCol_NavWindowingHighlight] = ImVec4(1.00f, 1.00f, 1.00f, 0.70f);
  colors[ImGuiCol_NavWindowingDimBg] = ImVec4(0.80f, 0.80f, 0.80f, 0.20f);
  colors[ImGuiCol_ModalWindowDimBg] = ImVec4(0.80f, 0.80f, 0.80f, 0.35f);

  ImGuiStyle &style = ImGui::GetStyle();

  style.TabRounding = 2;
  style.FrameRounding = 2;
  style.WindowPadding.x = 0;
  style.WindowPadding.y = 0;
  style.FramePadding.x = 1;
  style.FramePadding.y = 0;
  style.IndentSpacing = 8;
  style.WindowRounding = 3;
  style.ScrollbarSize = 10;

}

void engine::quit_conf(bool *open) {
  if (*open) {
    ImGuiWindowFlags flags = ImGuiWindowFlags_NoDecoration;

    // create centered window
    ImGui::SetNextWindowPos(
        ImVec2((WIDTH*1.5) - 115, (HEIGHT*1.5) - 20));
    ImGui::SetNextWindowSize(ImVec2(230, 35));
    ImGui::Begin("quit", open, flags);

    ImGui::Text("  Are you sure you want to quit?  ");

    ImGui::Text("    ");
    ImGui::SameLine();

    // button to cancel -> set this window's bool to false
    if (ImGui::Button(" Cancel "))
      *open = false;

    ImGui::SameLine();
    ImGui::Text("    ");
    ImGui::SameLine();

    // button to quit -> set pquit to true
    if (ImGui::Button("  Quit  "))
      pquit = true;

    ImGui::End();
  }
}

void engine::gl_setup() {
  // some info on your current platform
  const GLubyte *renderer = glGetString(GL_RENDERER); // get renderer string
  const GLubyte *version = glGetString(GL_VERSION);   // version as a string
  printf("Renderer: %s\n", renderer);
  printf("OpenGL version supported %s\n\n\n", version);

//  ╔╦╗┬─┐┬┌─┐┌┐┌┌─┐┬  ┌─┐  ╔═╗┌─┐┌─┐┌┬┐┌─┐┌┬┐┬─┐┬ ┬
//   ║ ├┬┘│├─┤││││ ┬│  ├┤   ║ ╦├┤ │ ││││├┤  │ ├┬┘└┬┘
//   ╩ ┴└─┴┴ ┴┘└┘└─┘┴─┘└─┘  ╚═╝└─┘└─┘┴ ┴└─┘ ┴ ┴└─ ┴
  std::vector<glm::vec3> points;
  points.clear();

  // based on this, one triangle is significantly faster than two
  // https://michaldrobot.com/2014/04/01/gcn-execution-patterns-in-full-screen-passes/
  // main idea is that there is coherency along the diagonal
  points.push_back(glm::vec3(-1, -1, 0.5)); // A
  points.push_back(glm::vec3(3, -1, 0.5));  // B
  points.push_back(glm::vec3(-1, 3, 0.5));  // C

//  ╔╦╗┌─┐┬┌┐┌  ╔═╗┬ ┬┌─┐┌┬┐┌─┐┬─┐   ┬   ╔╗ ┬ ┬┌─┐┌─┐┌─┐┬─┐┌─┐
//  ║║║├─┤││││  ╚═╗├─┤├─┤ ││├┤ ├┬┘  ┌┼─  ╠╩╗│ │├┤ ├┤ ├┤ ├┬┘└─┐
//  ╩ ╩┴ ┴┴┘└┘  ╚═╝┴ ┴┴ ┴─┴┘└─┘┴└─  └┘   ╚═╝└─┘└  └  └─┘┴└─└─┘
  {// create the shader for the triangles to cover the screen
    display_shader = Shader("resources/engine_code/shaders/blit.vs.glsl", "resources/engine_code/shaders/blit.fs.glsl").Program;

    // vao, vbo
    glGenVertexArrays(1, &display_vao);
    glBindVertexArray(display_vao);
    glGenBuffers(1, &display_vbo);
    glBindBuffer(GL_ARRAY_BUFFER, display_vbo);

    // buffer the data
    glBufferData(GL_ARRAY_BUFFER, sizeof(glm::vec3) * points.size(), &points[0], GL_DYNAMIC_DRAW);

    // set up the attribute pointer
    GLuint points_attrib = glGetAttribLocation(display_shader, "vPosition");
    glEnableVertexAttribArray(points_attrib);
    glVertexAttribPointer(points_attrib, 3, GL_FLOAT, GL_FALSE, 0, 0);
  }

//  ╦═╗┌─┐┌┐┌┌┬┐┌─┐┬─┐  ╔╦╗┌─┐─┐ ┬┌┬┐┬ ┬┬─┐┌─┐
//  ╠╦╝├┤ │││ ││├┤ ├┬┘   ║ ├┤ ┌┴┬┘ │ │ │├┬┘├┤
//  ╩╚═└─┘┘└┘─┴┘└─┘┴└─   ╩ └─┘┴ └─ ┴ └─┘┴└─└─┘
  {// initialize image data for the render texture
    std::vector<uint8_t> image_data;
    image_data.resize(WIDTH * HEIGHT * 4, 0);

    // create the render texture used in the compute shaders
    glGenTextures(1, &display_texture);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_RECTANGLE, display_texture);
    // glTexImage2D(GL_TEXTURE_RECTANGLE, 0, GL_RGBA8, WIDTH, HEIGHT, 0, GL_RGBA, GL_UNSIGNED_BYTE, &image_data[0]);
    glTexImage2D(GL_TEXTURE_RECTANGLE, 0, GL_RGBA8UI, WIDTH, HEIGHT, 0, GL_RGBA_INTEGER, GL_UNSIGNED_BYTE, &image_data[0]);
    glBindImageTexture(0, display_texture, 0, GL_FALSE, 0, GL_READ_WRITE, GL_RGBA8UI);
  }

//  ╔╦╗┬┌┬┐┬ ┬┌─┐┬─┐  ╔╦╗┌─┐─┐ ┬┌┬┐┬ ┬┬─┐┌─┐┌─┐
//   ║║│ │ ├─┤├┤ ├┬┘   ║ ├┤ ┌┴┬┘ │ │ │├┬┘├┤ └─┐
//  ═╩╝┴ ┴ ┴ ┴└─┘┴└─   ╩ └─┘┴ └─ ┴ └─┘┴└─└─┘└─┘
  std::vector<uint8_t> pattern;
  //  bayer dither pattern, from https://www.anisopteragames.com/how-to-fix-color-banding-with-dithering/

  {// scoped because why not
    std::vector<uint8_t> bayerpattern = {
     0, 32,  8, 40,  2, 34, 10, 42,   /* 8x8 Bayer ordered dithering  */
    48, 16, 56, 24, 50, 18, 58, 26,  /* pattern.  Each input pixel   */
    12, 44,  4, 36, 14, 46,  6, 38,  /* starts scaled to the 0..63 range */
    60, 28, 52, 20, 62, 30, 54, 22,  /* before looking in this table */
     3, 35, 11, 43,  1, 33,  9, 41,   /* to determine the action.     */
    51, 19, 59, 27, 49, 17, 57, 25,
    15, 47,  7, 39, 13, 45,  5, 37,
    63, 31, 55, 23, 61, 29, 53, 21 };


    for(auto x : bayerpattern)
    { // use the whole range 0-255, so I don't have to abuse the existing blue noise algorithm to match ranges
      pattern.push_back(x * 4);
      pattern.push_back(x * 4);
      pattern.push_back(x * 4);
    }

    // send it - known 8x8 dimension
    glGenTextures(1, &dither_bayer);
    glActiveTexture(GL_TEXTURE0+1);
    glBindTexture(GL_TEXTURE_2D, dither_bayer);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB8, 8, 8, 0, GL_RGB, GL_UNSIGNED_BYTE, &pattern[0]);
  }

  pattern.clear(); // zero out

  {//  blue noise dither pattern, adapted from https://gist.github.com/kajott/d9f9bb93043040bfe2f48f4f499903d8
    // values in the range 0-255
    std::vector<uint8_t> bluepatternbig = gen_blue_noise();

    #define map(x,y) bluepatternbig[x+(128*y)]

    for(size_t x = 0; x < 64; x++)
      for(size_t y = 0; y < 64; y++)
      {
        pattern.push_back(map(x,y));
        pattern.push_back(map(x+64,y));
        pattern.push_back(map(x+64,y+64));
      }

    #undef map

    // send it - variable size possible, but starting off just using 64x64 dimension
    glGenTextures(1, &dither_blue);
    glActiveTexture(GL_TEXTURE0+2);
    glBindTexture(GL_TEXTURE_2D, dither_blue);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB8, 64, 64, 0, GL_RGB, GL_UNSIGNED_BYTE, &pattern[0]);
  }

//  ╔═╗┌─┐┌┬┐┌─┐┬ ┬┌┬┐┌─┐  ╔═╗┬ ┬┌─┐┌┬┐┌─┐┬─┐┌─┐
//  ║  │ ││││├─┘│ │ │ ├┤   ╚═╗├─┤├─┤ ││├┤ ├┬┘└─┐
//  ╚═╝└─┘┴ ┴┴  └─┘ ┴ └─┘  ╚═╝┴ ┴┴ ┴─┴┘└─┘┴└─└─┘
  {// raymarch shader
    cout << "compiling raymarch shader... " << std::flush;
    raymarch_shader = CShader("resources/engine_code/shaders/raymarch.cs.glsl").Program;
    cout << "done." << endl << std::flush;

    // monolithicc dither shader
    // contains all color space conversions, and the bitcrush logic
    cout << "compiling dither shader... " << std::flush;
    dither_shader = CShader("resources/engine_code/shaders/dither.cs.glsl").Program;
    cout << "done." << endl << std::flush;
  }
}

static void HelpMarker(const char *desc) {
  ImGui::TextDisabled("(?)");
  if (ImGui::IsItemHovered()) {
    ImGui::BeginTooltip();
    ImGui::PushTextWrapPos(ImGui::GetFontSize() * 35.0f);
    ImGui::TextUnformatted(desc);
    ImGui::PopTextWrapPos();
    ImGui::EndTooltip();
  }
}

void engine::start_imgui()
{
  ImGui_ImplOpenGL3_NewFrame();
  ImGui_ImplSDL2_NewFrame(window);
  ImGui::NewFrame();
}

void engine::end_imgui()
{
  ImGui::Render();
  ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData()); // put imgui data into the framebuffer
}


void engine::control_window()
{


  ImGui::Begin("Controls", NULL, 0);
  ImGui::BeginTabBar("", ImGuiTabBarFlags_TabListPopupButton | ImGuiTabBarFlags_FittingPolicyScroll );

  if(ImGui::BeginTabItem("Controls"))
  {
    ImGui::Text("");
    ImGui::ColorEdit3("Clear Color", (float*)&clear_color);
    ImGui::Text("");
    ImGui::Text("Lights");
    ImGui::ColorEdit3("Light 1 Color", (float*)&lightCol1);
    ImGui::ColorEdit3("Light 2 Color", (float*)&lightCol2);
    ImGui::ColorEdit3("Light 3 Color", (float*)&lightCol3);
    ImGui::EndTabItem();
  }

  if(ImGui::BeginTabItem("Dither Patterns"))
  {
    ImGui::Text(" BAYER PATTERN");
    ImGui::SameLine();
    HelpMarker("This is used for ordered dithering. It is a static dither pattern, with identifiable artifacts.");
    ImGui::Text("  ");
    ImGui::SameLine();
    ImGui::Image((ImTextureID)(intptr_t)dither_bayer, ImVec2(256,256));

    ImGui::Text(" BLUE NOISE PATTERN");
    ImGui::SameLine();
    HelpMarker("This uses blue noise generated during the initialization, and the use in the shader is cycled over time using the golden ratio.");
    ImGui::Text("  ");
    ImGui::SameLine();
    ImGui::Image((ImTextureID)(intptr_t)dither_blue, ImVec2(256,256));

    ImGui::EndTabItem();
  }

  ImGui::End();
}

void engine::draw_everything() {
  //  ╦ ╦┌─┐┌┬┐┌─┐┌┬┐┌─┐  ╔═╗┌┬┐┌─┐┌┬┐┌─┐
  //  ║ ║├─┘ ││├─┤ │ ├┤   ╚═╗ │ ├─┤ │ ├┤
  //  ╚═╝┴  ─┴┘┴ ┴ ┴ └─┘  ╚═╝ ┴ ┴ ┴ ┴ └─┘
  // update rotation matrix
  glm::quat rotationx = glm::angleAxis(rotation_about_x, glm::vec3(1,0,0));
  glm::quat rotationy = glm::angleAxis(rotation_about_y, glm::vec3(0,1,0));
  /* glm::quat rotationz = glm::angleAxis(rotation_about_z, glm::vec3(0,0,1)); */
  glm::mat4 rotation = glm::toMat4(rotationy * rotationx);

  // create the basis vectors
  glm::vec3 basis_x = (rotation*glm::vec4(1,0,0,0)).xyz();
  glm::vec3 basis_y = (rotation*glm::vec4(0,1,0,0)).xyz();
  glm::vec3 basis_z = (rotation*glm::vec4(0,0,1,0)).xyz();

  //  ╦═╗┌─┐┬ ┬┌┬┐┌─┐┬─┐┌─┐┬ ┬
  //  ╠╦╝├─┤└┬┘│││├─┤├┬┘│  ├─┤
  //  ╩╚═┴ ┴ ┴ ┴ ┴┴ ┴┴└─└─┘┴ ┴
  // using the raymarch shader
  glUseProgram(raymarch_shader);

  // send basis vectors to the raymarch shader
  glUniform3f(glGetUniformLocation(raymarch_shader, "basis_x"), basis_x.x, basis_x.y, basis_x.z);
  glUniform3f(glGetUniformLocation(raymarch_shader, "basis_y"), basis_y.x, basis_y.y, basis_y.z);
  glUniform3f(glGetUniformLocation(raymarch_shader, "basis_z"), basis_z.x, basis_z.y, basis_z.z);

  // send light information to the raymarch shader
  glUniform3f(glGetUniformLocation(raymarch_shader, "lightCol1"), lightCol1.x, lightCol1.y, lightCol1.z);
  glUniform3f(glGetUniformLocation(raymarch_shader, "lightCol2"), lightCol2.x, lightCol2.y, lightCol2.z);
  glUniform3f(glGetUniformLocation(raymarch_shader, "lightCol3"), lightCol3.x, lightCol3.y, lightCol3.z);

  // send position to the raymarch shader
  glUniform3f(glGetUniformLocation(raymarch_shader, "ray_origin"), position.x, position.y, position.z);

  // send a quantitiy representing time
  glUniform1f(glGetUniformLocation(raymarch_shader, "time"), SDL_GetTicks() * 0.001);

  // invoke the shader on the GPU
  glDispatchCompute( WIDTH/8, HEIGHT/8, 1 ); //workgroup is 8x8x1, so divide each x and y by 8

  // sync to ensure the raymarched image is in the texture
  glMemoryBarrier( GL_SHADER_IMAGE_ACCESS_BARRIER_BIT );

  //  ╔╦╗┬┌┬┐┬ ┬┌─┐┬─┐
  //   ║║│ │ ├─┤├┤ ├┬┘
  //  ═╩╝┴ ┴ ┴ ┴└─┘┴└─
  // invoke the dither shader
  //  - needs to know mode, and also frame number to cycle the blue noise

  // sync to ensure the dithered image is in the texture
  glMemoryBarrier( GL_SHADER_IMAGE_ACCESS_BARRIER_BIT );

  //  ╔╦╗┬┌─┐┌─┐┬  ┌─┐┬ ┬
  //   ║║│└─┐├─┘│  ├─┤└┬┘
  //  ═╩╝┴└─┘┴  ┴─┘┴ ┴ ┴
  // texture display
  glUseProgram(display_shader);
  glBindVertexArray(display_vao);
  glBindBuffer(GL_ARRAY_BUFFER, display_vbo);

  // clear the screen - fog color? opacity falloff with depth?
  glClearColor(clear_color.x, clear_color.y, clear_color.z, clear_color.w); // from hsv picker
  glClear(GL_COLOR_BUFFER_BIT); // clear the background

  // screen dimension query - first frame has erroneous values
  ImGuiIO &io = ImGui::GetIO();
  if(io.DisplaySize.x != -1)
    glViewport( 0, 0, io.DisplaySize.x, io.DisplaySize.y);
  glUniform2f(glGetUniformLocation(display_shader, "resolution"), io.DisplaySize.x, io.DisplaySize.y);

  // blit dithered raymarch result to the screen
  glDrawArrays(GL_TRIANGLES, 0, 3);

  //  ╦┌┬┐╔═╗┬ ┬┬
  //  ║│││║ ╦│ ││
  //  ╩┴ ┴╚═╝└─┘┴
  start_imgui(); // Start the Dear ImGui frame
  {// in this scope, everything related to imgui happens
    quit_conf(&quitconfirm); // show quit confirm window, if relevant
    control_window(); // do the controls window
  }
  end_imgui(); // put ImGui stuff in the back buffer


  // swap the double buffers to present everything for this frame
  SDL_GL_SwapWindow(window);

  //  ╔═╗┬  ┬┌─┐┌┐┌┌┬┐┌─┐
  //  ║╣ └┐┌┘├┤ │││ │ └─┐
  //  ╚═╝ └┘ └─┘┘└┘ ┴ └─┘
  SDL_Event event;
  while (SDL_PollEvent(&event)) {  // handle events
    ImGui_ImplSDL2_ProcessEvent(&event);
    if (event.type == SDL_QUIT)
      pquit = true;

    if (event.type == SDL_WINDOWEVENT &&
        event.window.event == SDL_WINDOWEVENT_CLOSE &&
        event.window.windowID == SDL_GetWindowID(window))
      pquit = true;

    if ((event.type == SDL_KEYUP && event.key.keysym.sym == SDLK_ESCAPE) ||
        (event.type == SDL_MOUSEBUTTONDOWN &&
         event.button.button ==
             SDL_BUTTON_X1)) // x1 is browser back on the mouse
      quitconfirm = !quitconfirm;

    if (event.type == SDL_KEYUP && event.key.keysym.sym == SDLK_ESCAPE &&
        SDL_GetModState() & KMOD_SHIFT)
      pquit = true; // force quit

    if(!ImGui::GetIO().WantCaptureKeyboard)
    {// imgui doesn't want the input, so we should use it

      if(event.type == SDL_KEYDOWN && event.key.keysym.sym == SDLK_f)
      {
        cout << endl;
        cout << "position: " << to_string(position) << endl;
        cout << "rotation: " << rotation_about_x << " " << rotation_about_y << " " << rotation_about_z << endl;
      }

      if(event.type == SDL_KEYDOWN && event.key.keysym.sym == SDLK_w)
        rotation_about_x -= 0.03;

      if(event.type == SDL_KEYDOWN && event.key.keysym.sym == SDLK_s)
        rotation_about_x += 0.03;

      if(event.type == SDL_KEYDOWN && event.key.keysym.sym == SDLK_a)
        rotation_about_y -= 0.03;

      if(event.type == SDL_KEYDOWN && event.key.keysym.sym == SDLK_d)
        rotation_about_y += 0.03;

      if(event.type == SDL_KEYDOWN && event.key.keysym.sym == SDLK_e)
        rotation_about_z -= 0.03;

      if(event.type == SDL_KEYDOWN && event.key.keysym.sym == SDLK_q)
        rotation_about_z += 0.03;


      if(event.type == SDL_KEYDOWN && event.key.keysym.sym == SDLK_UP)
        position += 0.07f * basis_z;

      if(event.type == SDL_KEYDOWN && event.key.keysym.sym == SDLK_DOWN)
        position -= 0.07f * basis_z;

      if(event.type == SDL_KEYDOWN && event.key.keysym.sym == SDLK_RIGHT)
        position += 0.07f * basis_x;

      if(event.type == SDL_KEYDOWN && event.key.keysym.sym == SDLK_LEFT)
        position -= 0.07f * basis_x;

      if(event.type == SDL_KEYDOWN && event.key.keysym.sym == SDLK_PAGEUP)
        position += 0.07f * basis_y;

      if(event.type == SDL_KEYDOWN && event.key.keysym.sym == SDLK_PAGEDOWN)
        position -= 0.07f * basis_y;
    }
  }
}

void engine::quit() {
  // shutdown everything
  ImGui_ImplOpenGL3_Shutdown();
  ImGui_ImplSDL2_Shutdown();
  ImGui::DestroyContext();

  // destroy window
  SDL_GL_DeleteContext(GLcontext);
  SDL_DestroyWindow(window);
  SDL_Quit();

  cout << "goodbye." << endl;
}
