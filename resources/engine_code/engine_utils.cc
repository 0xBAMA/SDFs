#define STB_INCLUDE_IMPLEMENTATION
#define STB_INCLUDE_LINE_GLSL
#include "engine.h"
// This contains the lower level code

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
      "Raymarcher", 0, 0, WIDTH*3, HEIGHT*3,
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

  clear_color = ImVec4(196./255., 68./255., 14./255., 1.0f); // initial value for clear color

  // really excited by the fact imgui has an hsv picker to set this
  glClearColor(clear_color.x, clear_color.y, clear_color.z, clear_color.w);
  glClear(GL_COLOR_BUFFER_BIT);
  SDL_GL_SwapWindow(window);

  cout << "done." << endl;

  ImVec4 *colors = ImGui::GetStyle().Colors;
  colors[ImGuiCol_Text] = ImVec4(0.67f, 0.50f, 0.16f, 1.00f);
  colors[ImGuiCol_TextDisabled] = ImVec4(0.33f, 0.27f, 0.16f, 1.00f);
  colors[ImGuiCol_WindowBg] = ImVec4(0.10f, 0.05f, 0.00f, 1.00f);
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

	// texture buffer breakdown:
		// 0: render texture - holds result of raycast + dither steps
		// 1: bayer dither texture
		// 2: blue noise dither texture

	// todo - 3x single channel, for atomics:
		// GLuint RGBParadeAccumulators[ 3 ];
		// 3: red parade histogram graph
		// 4: green parade histogram graph
		// 5: blue parade histogram graph

	// todo - image buffer to read and combine to display - 3 channel
		// GLuint RGBParadePresentTex;
		// 6: composite parade graph

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


    for(auto x : bayerpattern)   // use the whole range 0-255, so I don't have to abuse the existing blue noise algorithm to match ranges
      pattern.push_back(x * 4); // bump up by two bits to make this happen


    // send it - known 8x8 dimension
    glGenTextures(1, &dither_bayer);
    glActiveTexture(GL_TEXTURE0+1);
    glBindTexture(GL_TEXTURE_2D, dither_bayer);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_R8, 8, 8, 0, GL_RED, GL_UNSIGNED_BYTE, &pattern[0]);
    // glBindImageTexture(1, dither_bayer, 0, GL_FALSE, 0, GL_READ_WRITE, GL_RGBA8UI);
  }

  pattern.clear(); // zero out

  {//  blue noise dither pattern, adapted from https://gist.github.com/kajott/d9f9bb93043040bfe2f48f4f499903d8
    // values in the range 0-255
    std::vector<uint8_t> bluepattern = gen_blue_noise();
    #define map(x,y) bluepattern[x+(64*y)]

    for(size_t x = 0; x < 64; x++)
    for(size_t y = 0; y < 64; y++)
        pattern.push_back(map(x,y));

    #undef map

    // send it - variable size possible in the header, but right now I'm hard coding 64x64
    glGenTextures(1, &dither_blue);
    glActiveTexture(GL_TEXTURE0+2);
    glBindTexture(GL_TEXTURE_2D, dither_blue);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_R8, 64, 64, 0, GL_RED, GL_UNSIGNED_BYTE, &pattern[0]);
    // glBindImageTexture(2, dither_blue, 0, GL_FALSE, 0, GL_READ_WRITE, GL_RGBA8UI);
  }


	std::vector< uint8_t > imageData;
	imageData.resize( WIDTH * HEIGHT * 4, 255 );

	// RGBParadeAccumulators[ 3 ]
	// 3x 1-channel [ buffers 3, 4, 5 ]
	glGenTextures( 3, &RGBParadeAccumulators[ 0 ] );
	glActiveTexture( GL_TEXTURE0 + 3 );
	glBindTexture( GL_TEXTURE_2D, RGBParadeAccumulators[ 0 ] );
	glTexImage2D( GL_TEXTURE_2D, 0, GL_R32UI, WIDTH, 256, 0,  GL_RED_INTEGER, GL_UNSIGNED_INT, NULL );
	glBindImageTexture( 3, RGBParadeAccumulators[ 0 ], 0, GL_FALSE, 0, GL_READ_WRITE, GL_R32UI );

	glActiveTexture( GL_TEXTURE0 + 4 );
	glBindTexture( GL_TEXTURE_2D, RGBParadeAccumulators[ 1 ] );
	glTexImage2D( GL_TEXTURE_2D, 0, GL_R32UI, WIDTH, 256, 0,  GL_RED_INTEGER, GL_UNSIGNED_INT, NULL );
	glBindImageTexture( 4, RGBParadeAccumulators[ 1 ], 0, GL_FALSE, 0, GL_READ_WRITE, GL_R32UI );

	glActiveTexture( GL_TEXTURE0 + 5 );
	glBindTexture( GL_TEXTURE_2D, RGBParadeAccumulators[ 2 ] );
	glTexImage2D( GL_TEXTURE_2D, 0, GL_R32UI, WIDTH, 256, 0,  GL_RED_INTEGER, GL_UNSIGNED_INT, NULL );
	glBindImageTexture( 5, RGBParadeAccumulators[ 2 ], 0, GL_FALSE, 0, GL_READ_WRITE, GL_R32UI );


	// RGBParadePresentTex
	// 1x 3-channel [ buffer 6 ]
	glGenTextures( 1, &RGBParadePresentTex ); // using dual texture/image interface - image for write, tex for filtered read
	glActiveTexture( GL_TEXTURE0 + 6 );
	glBindTexture( GL_TEXTURE_RECTANGLE, RGBParadePresentTex );
	glTexParameteri( GL_TEXTURE_RECTANGLE, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
	glTexParameteri( GL_TEXTURE_RECTANGLE, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
	glTexImage2D( GL_TEXTURE_RECTANGLE, 0, GL_RGBA8UI, WIDTH, 256, 0, GL_RGBA_INTEGER, GL_UNSIGNED_BYTE, &imageData[ 0 ] );
	glBindImageTexture( 6, RGBParadePresentTex, 0, GL_FALSE, 0, GL_READ_WRITE, GL_RGBA8UI );



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

		cout << "compiling RGB parade shaders... " << std::flush;
		RGBParadeComputeShader = CShader( "resources/engine_code/shaders/RGBParadeCompute.cs.glsl" ).Program;
		RGBParadeCompositeShader = CShader( "resources/engine_code/shaders/RGBParadeComposite.cs.glsl" ).Program;
		cout << "done." << endl << std::flush;

  }
}

// static void HelpMarker(const char *desc) {
//   ImGui::TextDisabled("(?)");
//   if (ImGui::IsItemHovered()) {
//     ImGui::BeginTooltip();
//     ImGui::PushTextWrapPos(ImGui::GetFontSize() * 35.0f);
//     ImGui::TextUnformatted(desc);
//     ImGui::PopTextWrapPos();
//     ImGui::EndTooltip();
//   }
// }

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

  if(ImGui::BeginTabItem("Raymarcher Controls"))
  {
    ImGui::Text("");
    ImGui::ColorEdit3("Basic Diffuse", (float*)&basic_diffuse);
    ImGui::Text("");
    ImGui::Text("Lights");
    ImGui::ColorEdit3("Light 1 Diffuse", (float*)&lightCol1d);
    ImGui::ColorEdit3("Light 1 Specular", (float*)&lightCol1s);
    ImGui::SliderFloat("Light 1 Spec Power", &specpower1, 0.1, 200.0);
    ImGui::SliderFloat("Light 1 Shadow Sharpness", &shadow1, 0.1, 100.0);
    ImGui::Text("");
    ImGui::SliderFloat("Light 1 Orbit Radius", &orbit1, 0.1, 100.0);
    // what should the visibility only/phong switcher look like?
		// only light 1 is implemented at this time
    // ImGui::Text("");
    // ImGui::ColorEdit3("Light 2 Diffuse", (float*)&lightCol2d);
    // ImGui::ColorEdit3("Light 2 Specular", (float*)&lightCol2s);
    // ImGui::SliderFloat("Light 2 Spec Power", &specpower2, 0.1, 200.0);
    // ImGui::SliderFloat("Light 2 Shadow Sharpness", &shadow2, 0.1, 100.0);
    // ImGui::Text("");
    // ImGui::SliderFloat("Light 2 Orbit Radius", &orbit2, 0.1, 100.0);
    // ImGui::Text("");
    // ImGui::ColorEdit3("Light 3 Diffuse", (float*)&lightCol3d);
    // ImGui::ColorEdit3("Light 3 Specular", (float*)&lightCol3s);
    // ImGui::SliderFloat("Light 3 Spec Power", &specpower3, 0.1, 200.0);
    // ImGui::SliderFloat("Light 3 Shadow Sharpness", &shadow3, 0.1, 100.0);
    // ImGui::Text("");
    // ImGui::SliderFloat("Light 3 Orbit Radius", &orbit3, 0.1, 100.0);
    // ImGui::Text("");

    ImGui::EndTabItem();
  }
  if(ImGui::BeginTabItem("Render Settings"))
  {
		ImGui::Text( "%f", time );
		ImGui::SameLine();
		if( ImGui::SmallButton( "Reset Timer" ) ) {
			time = 0.0;
		}
    ImGui::Text("");
    ImGui::SliderFloat(" FoV ", &fov, 0.001, 4.);
    ImGui::Text("");
    ImGui::ColorEdit3("Fog Color", (float*)&clear_color);
    ImGui::Text("");

    // fog terms
    ImGui::SliderFloat(" Depth Scale ", &depth_scale, 0.001, 15.);

    const char* dmodes[] = {"1", "2", "3", "EXP1", "EXP2", "EXP3", "EXP4", "POW1", "POW2", "POW3", "SIGMOID", "BASIC RATIO"};
    ImGui::Combo("Depth Falloff", &depth_selector, dmodes, IM_ARRAYSIZE(dmodes));

    // ao scale
    ImGui::SliderFloat(" AO Scale ", &AO_scale, 0.001, 1.);

    // tonemap methodology
    const char* tmodes[] = {"None (Linear)", "ACES (Narkowicz 2015)", "Unreal Engine 3", "Unreal Engine 4", "Uncharted 2", "Gran Turismo", "Modified Gran Turismo", "Rienhard", "Modified Rienhard", "jt", "robobo1221s", "robo", "reinhardRobo", "jodieRobo", "jodieRobo2", "jodieReinhard", "jodieReinhard2"};
    ImGui::Combo("Tonemapping Mode", &current_tmode, tmodes, IM_ARRAYSIZE(tmodes));

    // gamma correction
    ImGui::SliderFloat("gamma", &gamma_correction, 0.15, 4.0);

    ImGui::Text("");
    ImGui::Text("Raymarch Timing ");
    ImGui::SameLine();
    ImGui::Text("%d us", raymarch_microseconds);
    ImGui::Text("");
    ImGui::Text("Dither Timing ");
    ImGui::SameLine();
    ImGui::Text("%d us", dither_microseconds);
    ImGui::Text("");
    ImGui::Text("Display Timing ");
    ImGui::SameLine();
    ImGui::Text("%d us", display_microseconds);
    ImGui::Text("");
    ImGui::Text("Total Loop Timing ");
    ImGui::SameLine();
    ImGui::Text("%d us", total_loop_microseconds);
    ImGui::Text("");
    ImGui::Text("");
    ImGui::EndTabItem();
  }

  if(ImGui::BeginTabItem("Dither Parameters"))
  {
    const char* colorspaces [] = { " RGB ", " SRGB ", " XYZ ", " XYY ", " HSV ", " HSL ", " HCY ", " YPBPR ", " YPBPR601 ", " YCBCR1 ", " YCBCR2 ", " YCCBCCRC ", " YCOCG ", " BCH ", " CHROMAMAX ", " OKLAB "};
    const char* noise_funcs [] = { " NONE ", " BAYER ", " STATIC_MONO_BLUE ", " STATIC_RGB_BLUE ", " CYCLED_MONO_BLUE ", " CYCLED_RGB_BLUE ", " UNIFORM ", " INTERLEAVED_GRAD ", " VLACHOS ", " TRIANGLE_VLACHOS ", " TRIANGLE_MONO ", " TRIANGLE_RGB "};
    const char* dither_mode [] = { " BITCRUSH ", " EXPONENTIAL " };

    ImGui::Combo(" Colorspace ", &current_colorspace,  colorspaces, IM_ARRAYSIZE(colorspaces));
    ImGui::Combo(" Noise ",      &current_noise_func,  noise_funcs, IM_ARRAYSIZE(noise_funcs));
    ImGui::Combo(" Method ",     &current_dither_mode, dither_mode, IM_ARRAYSIZE(dither_mode));

    ImGui::Text("");
    ImGui::SliderInt(" Bit Depth ", &num_bits, 0, 8);

    ImGui::EndTabItem();
  }
  ImGui::EndTabBar();

  ImGui::End();
}

void engine::editor_window( bool &recompile ){
  static TextEditor editor;
  static auto lang = TextEditor::LanguageDefinition::GLSL();

  auto cpos = editor.GetCursorPosition();
  editor.SetPalette(TextEditor::GetDarkPalette());

  static const char *fileToEdit = "resources/engine_code/shaders/raymarch.cs.glsl";
  static bool loaded = false;
  if (!loaded) {
    std::ifstream t(fileToEdit);
    editor.SetLanguageDefinition(lang);
    if (t.good()) {
      editor.SetText(std::string((std::istreambuf_iterator<char>(t)),
                                  std::istreambuf_iterator<char>()));
      loaded = true;
    }
  }

  ImGui::Begin("Editor", NULL, 0);
  ImGui::Text("%6d/%-6d %6d lines  | %s | %s | %s | %s", cpos.mLine + 1,
              cpos.mColumn + 1, editor.GetTotalLines(),
              editor.IsOverwrite() ? "Ovr" : "Ins",
              editor.CanUndo() ? "*" : " ",
              editor.GetLanguageDefinition().mName.c_str(), fileToEdit);



	editor.Render("TextEditor", ImVec2( -FLT_MIN, ImGui::GetWindowSize().y - 50 ));
  // editor.Render("TextEditor");

  ImGui::Text(" ");
  ImGui::SameLine();
	if( ImGui::SmallButton( " Compile " ) || recompile ) {
		// compile the shader
		UShader shader = UShader( editor.GetText() );
		cout << "Shader object declared" << endl;

		if ( !shader.success ) {
			cout << "Shader Compilation Failed." << endl;
		} else {
			raymarch_shader = shader.Program;
			cout << std::string( shader.report ) << endl;
		}

		recompile = false;
  }
  ImGui::SameLine();
  ImGui::Text(" ");
  ImGui::SameLine();
  if( ImGui::SmallButton(" Reload ") ) {
    std::ifstream t( fileToEdit );
    if (t.good()) {
      editor.SetText(std::string((std::istreambuf_iterator<char>(t)),
                                  std::istreambuf_iterator<char>()));
      loaded = true;
    }
  }
  ImGui::SameLine();
  ImGui::Text(" ");
  ImGui::SameLine();
  if(ImGui::SmallButton(" Save "))
  {
    std::ofstream file("resources/engine_code/shaders/raymarch.cs.glsl");
    std::string savetext( editor.GetText() );
    file << savetext;
  }

	ImGui::SameLine();
	ImGui::Checkbox( "Render", &raymarch_stage );

  ImGui::End();
}

void engine::validatorWindow() {
	ImGui::Begin( "Formatter", NULL, 0 );
	static char Type[ 128 ] = "Category";
	static char Author[ 128 ] = "Author";
	ImGui::InputText( "Category", Type, 128 );
	ImGui::InputText( "Author Name", Author, 128 );

	static TextEditor editor;
	// static auto lang = TextEditor::LanguageDefinition::CPlusPlus();
	static auto lang = TextEditor::LanguageDefinition::GLSL();
	editor.SetLanguageDefinition( lang );

	auto cpos = editor.GetCursorPosition();
	// editor.SetPalette(TextEditor::GetLightPalette());
	editor.SetPalette( TextEditor::GetDarkPalette() );
	// editor.SetPalette(TextEditor::GetRetroBluePalette());

	// static const char *fileToEdit = "resources/engineCode/shaders/blit.vs.glsl";
	// std::ifstream t( fileToEdit );
	static bool initted = false;
	if ( !initted ) {
		editor.SetLanguageDefinition( lang );
		// if ( t.good() ) {
			// editor.SetText( std::string( ( std::istreambuf_iterator<char>(t)), std::istreambuf_iterator< char >() ) );
			editor.SetText( std::string( "" ) );
			initted = true;
		// }
	}

	// add dropdown for different shaders?
	ImGui::Text( "%6d/%-6d %6d lines  | %s | %s | %s | %s", cpos.mLine + 1,
							cpos.mColumn + 1, editor.GetTotalLines(),
							editor.IsOverwrite() ? "Ovr" : "Ins",
							editor.CanUndo() ? "*" : " ",
							editor.GetLanguageDefinition().mName.c_str(),
							// TextEditor::LanguageDefinition::GLSL(),
							std::string( "Working Scratch Space" ).c_str() );

	ImGui::SameLine();
	ImGui::Text("                          ");
	ImGui::SameLine();
	if( ImGui::SmallButton( "Dump to CLI" ) ) {

		// parse string - change tab to two spaces, newline to \n, etc
		std::string fromEditor( editor.GetText() );
		std::string toCLI;

		for ( auto c : fromEditor ) {
			if ( c == '\t' ){
				toCLI += std::string( "  " );
			} else if ( c == '\n' ) {
				toCLI += std::string( "\\n" );
			} else {
				toCLI += c;
			}
    }

		// put it on the command line, along with the other accoutrement
		cout << endl << endl;
		cout << "{" << endl;
		cout << "  \"category\": \"" << Type << "\"," << endl;
		cout << "  \"author\": \"" << Author << "\"," << endl;
		cout << "  \"code\": \"" << toCLI << "\"," << endl;
		cout << "  \"image\": \"images/DEC/\"" << endl;
		cout << "}," << endl << endl;

	}

	editor.Render( "Formatter" );
	ImGui::End();
}

void engine::animate_lights(float t){

  // use some perlin noise to animate brightness and move position around a little
  PerlinNoise p;

  //query with p.noise(x,y,z); - returns value 0.-1.

  // each of the lights has a flickerfactor (set by this function, passed to GPU), orbitradius, orbitrate, and phaseoffset, which help to set this flickerfactor
  //  the noise will be sampled along a circle in the xz plane, controlled by sinusoids,
  //   in the form  x = orbitradius * cos( orbitrate * t + phaseoffset )
  //   and          z = orbitradius * sin( orbitrate * t + phaseoffset )

  float samplex=0., sampley=0., samplez=0.;

  samplex = orbitradius1 * cos( orbitrate1 * t + phaseoffset1 );
  sampley = 6.5;
  samplez = orbitradius1 * sin( orbitrate1 * t + phaseoffset1 );
  flickerfactor1 = 1. + 0.4 * p.noise(samplex, sampley, samplez);

  samplex = orbitradius2 * cos( orbitrate2 * t + phaseoffset2 );
  sampley = -2.5;
  samplez = orbitradius2 * sin( orbitrate2 * t + phaseoffset2 );
  flickerfactor2 = 1. + 0.4 * p.noise(samplex, sampley, samplez);

  samplex = orbitradius3 * cos( orbitrate3 * t + phaseoffset3 );
  sampley = 3.5;
  samplez = orbitradius3 * sin( orbitrate3 * t + phaseoffset3 );
  flickerfactor3 = 1. + 0.4 * p.noise(samplex, sampley, samplez);

}

void engine::draw_everything() {
  auto t_loop_start = std::chrono::high_resolution_clock::now();
  //  ╦ ╦┌─┐┌┬┐┌─┐┌┬┐┌─┐  ╔═╗┌┬┐┌─┐┌┬┐┌─┐
  //  ║ ║├─┘ ││├─┤ │ ├┤   ╚═╗ │ ├─┤ │ ├┤
  //  ╚═╝┴  ─┴┘┴ ┴ ┴ └─┘  ╚═╝ ┴ ┴ ┴ ┴ └─┘
  // update rotation matrix
  // glm::quat rotationx = glm::angleAxis(rotation_about_x, basis_x);
  // glm::quat rotationy = glm::angleAxis(rotation_about_y, basis_y);
  // glm::quat rotationz = glm::angleAxis(rotation_about_z, basis_z);

	// no
  // glm::quat rotationx = glm::angleAxis(rotation_about_x, glm::vec3(1,0,0));
  // glm::quat rotationy = glm::angleAxis(rotation_about_y, glm::vec3(0,1,0));
  // glm::quat rotationz = glm::angleAxis(rotation_about_z, glm::vec3(0,0,1));
  // glm::mat4 rotation = glm::toMat4(rotationy * rotationx * rotationz);
	//
  // // create the basis vectors - these are more static now being retained as member variables
  // basis_x = (rotation*glm::vec4(1,0,0,0)).xyz();
  // basis_y = (rotation*glm::vec4(0,1,0,0)).xyz();
  // basis_z = (rotation*glm::vec4(0,0,1,0)).xyz();

  auto t_raymarch_start = std::chrono::high_resolution_clock::now();
  if(raymarch_stage){ // toggles invocation of the raymarch step
    //  ╦═╗┌─┐┬ ┬┌┬┐┌─┐┬─┐┌─┐┬ ┬
    //  ╠╦╝├─┤└┬┘│││├─┤├┬┘│  ├─┤
    //  ╩╚═┴ ┴ ┴ ┴ ┴┴ ┴┴└─└─┘┴ ┴
    // using the raymarch shader
    glUseProgram(raymarch_shader);

    // send basis vectors to the raymarch shader
    glUniform3f(glGetUniformLocation(raymarch_shader, "basis_x"), basisX.x, basisX.y, basisX.z);
    glUniform3f(glGetUniformLocation(raymarch_shader, "basis_y"), basisY.x, basisY.y, basisY.z);
    glUniform3f(glGetUniformLocation(raymarch_shader, "basis_z"), basisZ.x, basisZ.y, basisZ.z);

    // basic diffuse color
    glUniform3f(glGetUniformLocation(raymarch_shader, "basic_diffuse"), basic_diffuse.x, basic_diffuse.y, basic_diffuse.z);

    // fog color
    glUniform3f(glGetUniformLocation(raymarch_shader, "fog_color"), clear_color.x, clear_color.y, clear_color.z);

    // tonemapping mode
    glUniform1i(glGetUniformLocation(raymarch_shader, "tonemap_mode"), current_tmode);

    // gamma correction
    glUniform1f(glGetUniformLocation(raymarch_shader, "gamma"), gamma_correction);

    // send light information to the raymarch shader
    // animate light parameters
    animate_lights(SDL_GetTicks() * 0.001);

    // light flicker factor
    glUniform1f(glGetUniformLocation(raymarch_shader, "flickerfactor1"), flickerfactor1);
    glUniform1f(glGetUniformLocation(raymarch_shader, "flickerfactor2"), flickerfactor2);
    glUniform1f(glGetUniformLocation(raymarch_shader, "flickerfactor3"), flickerfactor3);

    // diffuse color
    glUniform3f(glGetUniformLocation(raymarch_shader, "lightCol1d"), lightCol1d.x, lightCol1d.y, lightCol1d.z);
    glUniform3f(glGetUniformLocation(raymarch_shader, "lightCol2d"), lightCol2d.x, lightCol2d.y, lightCol2d.z);
    glUniform3f(glGetUniformLocation(raymarch_shader, "lightCol3d"), lightCol3d.x, lightCol3d.y, lightCol3d.z);

    // specular color
    glUniform3f(glGetUniformLocation(raymarch_shader, "lightCol1s"), lightCol1s.x, lightCol1s.y, lightCol1s.z);
    glUniform3f(glGetUniformLocation(raymarch_shader, "lightCol2s"), lightCol2s.x, lightCol2s.y, lightCol2s.z);
    glUniform3f(glGetUniformLocation(raymarch_shader, "lightCol3s"), lightCol3s.x, lightCol3s.y, lightCol3s.z);

    // specular power
    glUniform1f(glGetUniformLocation(raymarch_shader, "specpower1"), specpower1);
    glUniform1f(glGetUniformLocation(raymarch_shader, "specpower2"), specpower2);
    glUniform1f(glGetUniformLocation(raymarch_shader, "specpower3"), specpower3);

    // shadow sharpness
    glUniform1f(glGetUniformLocation(raymarch_shader, "shadow1"), shadow1);
    glUniform1f(glGetUniformLocation(raymarch_shader, "shadow2"), shadow2);
    glUniform1f(glGetUniformLocation(raymarch_shader, "shadow3"), shadow3);

    // ambient occlusion strength
    glUniform1f(glGetUniformLocation(raymarch_shader, "AO_scale"), AO_scale);

    // position
    glUniform3f(glGetUniformLocation(raymarch_shader, "lightPos1"), lightPos1.x, lightPos1.y, lightPos1.z);
    glUniform3f(glGetUniformLocation(raymarch_shader, "lightPos2"), lightPos2.x, lightPos2.y, lightPos2.z);
    glUniform3f(glGetUniformLocation(raymarch_shader, "lightPos3"), lightPos3.x, lightPos3.y, lightPos3.z);

    // fov term
    glUniform1f(glGetUniformLocation(raymarch_shader, "fov"), fov);

    // depth scale term
    glUniform1f(glGetUniformLocation(raymarch_shader, "depth_scale"), depth_scale);

    // depth falloff calculation selector
    glUniform1i(glGetUniformLocation(raymarch_shader, "depth_falloff"), depth_selector);

    // send position to the raymarch shader
    glUniform3f(glGetUniformLocation(raymarch_shader, "ray_origin"), position.x, position.y, position.z);

    // send a quantitiy representing time
		time += 0.001;
    glUniform1f(glGetUniformLocation(raymarch_shader, "time"), time );

    // invoke the shader on the GPU
    glDispatchCompute( WIDTH/8, HEIGHT/8, 1 ); //workgroup is 8x8x1, so divide each x and y by 8

    // sync to ensure the raymarched image is in the texture
    glMemoryBarrier( GL_SHADER_IMAGE_ACCESS_BARRIER_BIT );
  }
  auto t_raymarch_end = std::chrono::high_resolution_clock::now();
  raymarch_microseconds = std::chrono::duration_cast<std::chrono::microseconds>(t_raymarch_end - t_raymarch_start).count();


  auto t_dither_start = std::chrono::high_resolution_clock::now();
  if(dither_stage){ // toggles invocation of the dither step
    //  ╔╦╗┬┌┬┐┬ ┬┌─┐┬─┐
    //   ║║│ │ ├─┤├┤ ├┬┘
    //  ═╩╝┴ ┴ ┴ ┴└─┘┴└─
    // invoke the dither shader
    //  - needs to know mode, and also frame number to cycle the blue noise
		glUseProgram(dither_shader);

    static unsigned int frame = 0;
    frame++; // increment
    glUniform1i(glGetUniformLocation(dither_shader, "frame"), frame); // send
    glUniform1i(glGetUniformLocation(dither_shader, "bits"), num_bits);
    glUniform1i(glGetUniformLocation(dither_shader, "spaceswitch"), current_colorspace);
    glUniform1i(glGetUniformLocation(dither_shader, "dithermode"), current_dither_mode);
    glUniform1i(glGetUniformLocation(dither_shader, "noise_function"), current_noise_func);

    // parameters controlling the dither process
    // current_colorspace
    // current_noise_func
    // current_dither_mode
    // num_bits

    // invoke on the GPU
		glDispatchCompute( WIDTH/8, HEIGHT/8, 1 );

    // sync to ensure the dithered image is in the texture
		glMemoryBarrier( GL_SHADER_IMAGE_ACCESS_BARRIER_BIT );
  }
  auto t_dither_end = std::chrono::high_resolution_clock::now();
  dither_microseconds = std::chrono::duration_cast<std::chrono::microseconds>(t_dither_end - t_dither_start).count();


	// static std::vector< uint8_t > imageData;
	// static bool firstTime = false;
	// if( firstTime ) {
	// 	imageData.resize( WIDTH * HEIGHT * 4, 0 );
	// 	firstTime = false;
	// } else {
	// 	// clear the buffers
	// 	//
	// 	// glActiveTexture( GL_TEXTURE0 + 3 );
	// 	// glBindTexture( GL_TEXTURE_2D, RGBParadeAccumulators[ 0 ] );
	// 	// glTexImage2D( GL_TEXTURE_2D, 0, GL_R32UI, WIDTH, 256, 0,  GL_RED_INTEGER, GL_UNSIGNED_INT, &imageData[ 0 ] );
	// 	// glBindImageTexture( 3, RGBParadeAccumulators[ 0 ], 0, GL_FALSE, 0, GL_READ_WRITE, GL_R32UI );
	// 	//
	// 	// glActiveTexture( GL_TEXTURE0 + 4 );
	// 	// glBindTexture( GL_TEXTURE_2D, RGBParadeAccumulators[ 1 ] );
	// 	// glTexImage2D( GL_TEXTURE_2D, 0, GL_R32UI, WIDTH, 256, 0,  GL_RED_INTEGER, GL_UNSIGNED_INT, &imageData[ 0 ] );
	// 	// glBindImageTexture( 4, RGBParadeAccumulators[ 1 ], 0, GL_FALSE, 0, GL_READ_WRITE, GL_R32UI );
	// 	//
	// 	// glActiveTexture( GL_TEXTURE0 + 5 );
	// 	// glBindTexture( GL_TEXTURE_2D, RGBParadeAccumulators[ 2 ] );
	// 	// glTexImage2D( GL_TEXTURE_2D, 0, GL_R32UI, WIDTH, 256, 0,  GL_RED_INTEGER, GL_UNSIGNED_INT, &imageData[ 0 ] );
	// 	// glBindImageTexture( 5, RGBParadeAccumulators[ 2 ], 0, GL_FALSE, 0, GL_READ_WRITE, GL_R32UI );
	// 	//
	// 	// glActiveTexture( GL_TEXTURE0 + 6 );
	// 	// glBindTexture( GL_TEXTURE_2D, RGBParadePresentTex );
	// 	// glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA8UI, WIDTH, 256, 0, GL_RGBA_INTEGER, GL_UNSIGNED_BYTE, &imageData[ 0 ] );
	// 	// glBindImageTexture( 6, RGBParadePresentTex, 0, GL_FALSE, 0, GL_READ_WRITE, GL_RGBA8UI );
	// 	//
	// 	// glMemoryBarrier( GL_SHADER_IMAGE_ACCESS_BARRIER_BIT );
	// }

	// dispatch the parade shaders
	glUseProgram( RGBParadeComputeShader );
	glDispatchCompute( WIDTH / 8, HEIGHT / 8, 1 );
	glMemoryBarrier( GL_SHADER_IMAGE_ACCESS_BARRIER_BIT );

	glUseProgram( RGBParadeCompositeShader );
	glDispatchCompute( WIDTH / 8, 256 / 8, 1 ); // images only 256px tall, for intensity bins
	glMemoryBarrier( GL_SHADER_IMAGE_ACCESS_BARRIER_BIT );


  //  ╔╦╗┬┌─┐┌─┐┬  ┌─┐┬ ┬
  //   ║║│└─┐├─┘│  ├─┤└┬┘
  //  ═╩╝┴└─┘┴  ┴─┘┴ ┴ ┴

  auto t_display_start = std::chrono::high_resolution_clock::now();
  // texture display
  glUseProgram(display_shader);
  glBindVertexArray(display_vao);
  glBindBuffer(GL_ARRAY_BUFFER, display_vbo);

	glUniform1i( glGetUniformLocation( display_shader, "paradePresent" ), 6 );

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

  auto t_display_end = std::chrono::high_resolution_clock::now();
  display_microseconds = std::chrono::duration_cast<std::chrono::microseconds>(t_display_end - t_display_start).count();

  //  ╦┌┬┐╔═╗┬ ┬┬
  //  ║│││║ ╦│ ││
  //  ╩┴ ┴╚═╝└─┘┴
  {// in this scope, everything related to imgui happens
    start_imgui(); // Start the Dear ImGui frame

    quit_conf(&quitconfirm); // show quit confirm window, if relevant
    control_window(); // do the controls window
    editor_window( shaderRecompile ); // do the window with the text editor
		validatorWindow(); // for formatting the output, to be used in the DEC

		// static bool showDemoWindow = true;
		// if ( showDemoWindow )
		// 	ImGui::ShowDemoWindow( &showDemoWindow );


    end_imgui(); // put ImGui stuff in the back buffer
  }

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

		if(event.type == SDL_KEYDOWN && event.key.keysym.sym == SDLK_RETURN && ( SDL_GetModState() & KMOD_ALT )) {
			shaderRecompile = true; // recompile the shader
			cout << "recompiling shader now" << endl;
		}

    if(!ImGui::GetIO().WantCaptureKeyboard)
    {// imgui doesn't want the input, so we should use it

      if(event.type == SDL_KEYDOWN && event.key.keysym.sym == SDLK_f)
      {
        cout << endl;
        cout << "position: " << to_string(position) << endl;
        cout << "rotation: " << rotation_about_x << " " << rotation_about_y << " " << rotation_about_z << endl;
      }

      if(event.type == SDL_KEYDOWN && event.key.keysym.sym == SDLK_p)
      {
        auto now = std::chrono::system_clock::now();
        auto in_time_t = std::chrono::system_clock::to_time_t(now);

        std::stringstream ss;
        ss << std::put_time(std::localtime(&in_time_t), "Screenshot-%Y-%m-%d %X") << ".png";
        screenshot(ss.str());
      }


			// no
      // if(event.type == SDL_KEYDOWN && event.key.keysym.sym == SDLK_w)
      //   rotation_about_x -= SDL_GetModState() & KMOD_SHIFT ? 0.1 : 0.03;
			//
      // if(event.type == SDL_KEYDOWN && event.key.keysym.sym == SDLK_s)
      //   rotation_about_x += SDL_GetModState() & KMOD_SHIFT ? 0.1 : 0.03;
			//
      // if(event.type == SDL_KEYDOWN && event.key.keysym.sym == SDLK_a)
      //   rotation_about_y -= SDL_GetModState() & KMOD_SHIFT ? 0.1 : 0.03;
			//
      // if(event.type == SDL_KEYDOWN && event.key.keysym.sym == SDLK_d)
      //   rotation_about_y += SDL_GetModState() & KMOD_SHIFT ? 0.1 : 0.03;
			//
      // if(event.type == SDL_KEYDOWN && event.key.keysym.sym == SDLK_e)
      //   rotation_about_z -= SDL_GetModState() & KMOD_SHIFT ? 0.1 : 0.03;
			//
      // if(event.type == SDL_KEYDOWN && event.key.keysym.sym == SDLK_q)
      //   rotation_about_z += SDL_GetModState() & KMOD_SHIFT ? 0.1 : 0.03;


			// quaternion based rotation via retained state in the basis vectors - much easier to use than the arbitrary euler angles
			if( event.type == SDL_KEYDOWN && event.key.keysym.sym == SDLK_w ) {
				glm::quat rot = glm::angleAxis( SDL_GetModState() & KMOD_SHIFT ? -0.1f : -0.005f, basisX );	// basisX is the axis, therefore remains untransformed
				basisY = ( rot * glm::vec4( basisY, 0.0f )).xyz();
				basisZ = ( rot * glm::vec4( basisZ, 0.0f )).xyz();
			}
			if( event.type == SDL_KEYDOWN && event.key.keysym.sym == SDLK_s ) {
				glm::quat rot = glm::angleAxis( SDL_GetModState() & KMOD_SHIFT ?  0.1f :  0.005f, basisX );
				basisY = ( rot * glm::vec4( basisY, 0.0f )).xyz();
				basisZ = ( rot * glm::vec4( basisZ, 0.0f )).xyz();
			}
			if( event.type == SDL_KEYDOWN && event.key.keysym.sym == SDLK_a ) {
				glm::quat rot = glm::angleAxis( SDL_GetModState() & KMOD_SHIFT ? -0.1f : -0.005f, basisY );	// same as above, but basisY is the axis
				basisX = ( rot * glm::vec4( basisX, 0.0f )).xyz();
				basisZ = ( rot * glm::vec4( basisZ, 0.0f )).xyz();
			}
			if( event.type == SDL_KEYDOWN && event.key.keysym.sym == SDLK_d ) {
				glm::quat rot = glm::angleAxis( SDL_GetModState() & KMOD_SHIFT ?  0.1f :  0.005f, basisY );
				basisX = ( rot * glm::vec4( basisX, 0.0f )).xyz();
				basisZ = ( rot * glm::vec4( basisZ, 0.0f )).xyz();
			}
			if( event.type == SDL_KEYDOWN && event.key.keysym.sym == SDLK_q ) {
				glm::quat rot = glm::angleAxis( SDL_GetModState() & KMOD_SHIFT ? -0.1f : -0.005f, basisZ ); // and again for basisZ
				basisX = ( rot * glm::vec4( basisX, 0.0f )).xyz();
				basisY = ( rot * glm::vec4( basisY, 0.0f )).xyz();
			}
			if( event.type == SDL_KEYDOWN && event.key.keysym.sym == SDLK_e ) {
				glm::quat rot = glm::angleAxis( SDL_GetModState() & KMOD_SHIFT ?  0.1f :  0.005f, basisZ );
				basisX = ( rot * glm::vec4( basisX, 0.0f )).xyz();
				basisY = ( rot * glm::vec4( basisY, 0.0f )).xyz();
			}

			// f to reset basis, F to reset basis and home to origin
			if( event.type == SDL_KEYDOWN && event.key.keysym.sym == SDLK_f ) {
				if( SDL_GetModState() & KMOD_SHIFT ) {
					position = glm::vec3( 0.0, 0.0, 0.0 );
				}
				// reset to default basis
				basisX = glm::vec3( 1.0, 0.0, 0.0 );
				basisY = glm::vec3( 0.0, 1.0, 0.0 );
				basisZ = glm::vec3( 0.0, 0.0, 1.0 );
			}

      if(event.type == SDL_KEYDOWN && event.key.keysym.sym == SDLK_UP)
        position += (SDL_GetModState() & KMOD_SHIFT ? 0.5f : 0.07f) * basisZ;

      if(event.type == SDL_KEYDOWN && event.key.keysym.sym == SDLK_DOWN)
        position -= (SDL_GetModState() & KMOD_SHIFT ? 0.5f : 0.07f) * basisZ;

      if(event.type == SDL_KEYDOWN && event.key.keysym.sym == SDLK_RIGHT)
        position += (SDL_GetModState() & KMOD_SHIFT ? 0.5f : 0.07f) * basisX;

      if(event.type == SDL_KEYDOWN && event.key.keysym.sym == SDLK_LEFT)
        position -= (SDL_GetModState() & KMOD_SHIFT ? 0.5f : 0.07f) * basisX;

      if(event.type == SDL_KEYDOWN && event.key.keysym.sym == SDLK_PAGEUP)
        position += (SDL_GetModState() & KMOD_SHIFT ? 0.5f : 0.07f) * basisY;

      if(event.type == SDL_KEYDOWN && event.key.keysym.sym == SDLK_PAGEDOWN)
        position -= (SDL_GetModState() & KMOD_SHIFT ? 0.5f : 0.07f) * basisY;
    }
  }
  auto t_loop_end =  std::chrono::high_resolution_clock::now();
  total_loop_microseconds = std::chrono::duration_cast<std::chrono::microseconds>(t_loop_end - t_loop_start).count();

}

void engine::screenshot(std::string filename){
  // declare buffer and allocate space
  std::vector<unsigned char> image_bytes_to_save, temp;
  image_bytes_to_save.resize(WIDTH * HEIGHT * 4);

  // glReadPixels(0, 0, WIDTH, HEIGHT, GL_RGB, GL_UNSIGNED_BYTE, &image_bytes_to_save[0]);

  // glBindBuffer(GL_TEXTURE_BUFFER, display_texture);
  // glGetBufferSubData(GL_TEXTURE_BUFFER, 0, image_bytes_to_save.size(), &image_bytes_to_save[0]);

  // glGetTextureImage(display_texture, 0, GL_RGBA, GL_UNSIGNED_BYTE,  image_bytes_to_save.size(), &image_bytes_to_save[0]);

  glBindTexture(GL_TEXTURE_RECTANGLE, display_texture);
  glGetTexImage(GL_TEXTURE_RECTANGLE, 0, GL_RGBA_INTEGER, GL_UNSIGNED_BYTE, &image_bytes_to_save[0]);

  temp.assign(image_bytes_to_save.begin(), image_bytes_to_save.end());

  // reorder flipped image content
  for (int x = 0; x < WIDTH; x++)
    for (int y = 0; y < HEIGHT; y++) {
      int input_base = 4 * ((HEIGHT - y - 1) * WIDTH + x);
      int output_base = 3 * (y * WIDTH + x);
      image_bytes_to_save[output_base + 0] = temp[input_base + 0];
      image_bytes_to_save[output_base + 1] = temp[input_base + 1];
      image_bytes_to_save[output_base + 2] = temp[input_base + 2];
    }

  // save the resulting image - using the same buffer makes it so you don't have to copy it
  unsigned error;
  if ((error = lodepng::encode((std::string("screenshots/")+filename).c_str(), image_bytes_to_save, WIDTH, HEIGHT, LCT_RGB, 8))) {
    std::cout << "encode error during save(\" " + filename + " \") " << error << ": " << lodepng_error_text(error) << std::endl;
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
