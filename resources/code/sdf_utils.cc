#include "sdf.h"
// This contains the lower level code

void sdf::create_window()
{
	if(SDL_Init( SDL_INIT_EVERYTHING ) != 0)
	{
		printf("Error: %s\n", SDL_GetError());
	}

	SDL_GL_SetAttribute( SDL_GL_DOUBLEBUFFER, 1 );
	SDL_GL_SetAttribute( SDL_GL_ACCELERATED_VISUAL, 1 );
	SDL_GL_SetAttribute( SDL_GL_RED_SIZE, 8 );
	SDL_GL_SetAttribute( SDL_GL_GREEN_SIZE, 8 );
	SDL_GL_SetAttribute( SDL_GL_BLUE_SIZE, 8 );
	SDL_GL_SetAttribute( SDL_GL_ALPHA_SIZE, 8 );

	SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);
	SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, 8);

	// SDL_GL_SetAttribute( SDL_GL_MULTISAMPLEBUFFERS, 1);  //gl_SamplePosition has to be used in my shader in order for this to
	// SDL_GL_SetAttribute( SDL_GL_MULTISAMPLESAMPLES, 8);   //have any effect on the way my shader works (i.e. add to gl_FragCoord)

	// this is how you query the screen resolution
	SDL_DisplayMode dm;
	SDL_GetDesktopDisplayMode(0, &dm);

	// pulling these out because I'm going to try to span the whole screen with
	// the window, in a way that's flexible on different resolution screens
	int total_screen_width = dm.w;
	int total_screen_height = dm.h;
	
	cout << "creating window...";

	// window = SDL_CreateWindow( "OpenGL Window", 0, 0, total_screen_width, total_screen_height, SDL_WINDOW_OPENGL | SDL_WINDOW_HIDDEN | SDL_WINDOW_BORDERLESS );
	window = SDL_CreateWindow( "OpenGL Window", 0, 0, total_screen_width, total_screen_height, SDL_WINDOW_OPENGL | SDL_WINDOW_HIDDEN | SDL_WINDOW_RESIZABLE );
  	SDL_ShowWindow(window);
	
	cout << "done." << endl;


	cout << "setting up OpenGL context...";
	// OpenGL 4.3 + GLSL version 430
	const char* glsl_version = "#version 430";
	SDL_GL_SetAttribute(SDL_GL_CONTEXT_FLAGS, 0);
	SDL_GL_SetAttribute( SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE );
	SDL_GL_SetAttribute( SDL_GL_CONTEXT_MAJOR_VERSION, 4 );
	SDL_GL_SetAttribute( SDL_GL_CONTEXT_MINOR_VERSION, 3 );
	GLcontext = SDL_GL_CreateContext( window );

	SDL_GL_MakeCurrent(window, GLcontext);
	SDL_GL_SetSwapInterval(1); // Enable vsync -- questionable utility
	// SDL_GL_SetSwapInterval(0); // explicitly disable vsync


	if (glewInit() != GLEW_OK)
	{
		fprintf(stderr, "Failed to initialize OpenGL loader!\n");
	}

	glEnable(GL_DEPTH_TEST);

	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	
	// Setup Dear ImGui context
	IMGUI_CHECKVERSION();
	ImGui::CreateContext();
	ImGuiIO& io = ImGui::GetIO(); (void)io; // void cast prevents unused variable warning

	ImGui::StyleColorsDark();

	// Setup Platform/Renderer bindings
	ImGui_ImplSDL2_InitForOpenGL(window, GLcontext);
	ImGui_ImplOpenGL3_Init(glsl_version);

	clear_color = ImVec4(75.0f/255.0f, 75.0f/255.0f, 75.0f/255.0f, 0.5f); // initial value for clear color

	// really excited by the fact imgui has an hsv picker to set this
	glClearColor(clear_color.x, clear_color.y, clear_color.z, clear_color.w);
	glClear( GL_COLOR_BUFFER_BIT );
	SDL_GL_SwapWindow( window );
	
	cout << "done." << endl;
	
	ImVec4* colors = ImGui::GetStyle().Colors;
	
	colors[ImGuiCol_Text]                   = ImVec4(0.64f, 0.37f, 0.37f, 1.00f);
	colors[ImGuiCol_TextDisabled]           = ImVec4(0.49f, 0.26f, 0.26f, 1.00f);
	colors[ImGuiCol_WindowBg]               = ImVec4(0.17f, 0.00f, 0.00f, 0.94f);
	colors[ImGuiCol_ChildBg]                = ImVec4(0.00f, 0.00f, 0.00f, 0.00f);
	colors[ImGuiCol_PopupBg]                = ImVec4(0.18f, 0.00f, 0.00f, 0.94f);
	colors[ImGuiCol_Border]                 = ImVec4(0.35f, 0.00f, 0.03f, 0.50f);
	colors[ImGuiCol_BorderShadow]           = ImVec4(0.00f, 0.00f, 0.00f, 0.00f);
	colors[ImGuiCol_FrameBg]                = ImVec4(0.14f, 0.04f, 0.00f, 1.00f);
	colors[ImGuiCol_FrameBgHovered]         = ImVec4(0.14f, 0.04f, 0.00f, 1.00f);
	colors[ImGuiCol_FrameBgActive]          = ImVec4(0.14f, 0.04f, 0.00f, 1.00f);
	colors[ImGuiCol_TitleBg]                = ImVec4(0.14f, 0.04f, 0.00f, 1.00f);
	colors[ImGuiCol_TitleBgActive]          = ImVec4(0.14f, 0.04f, 0.00f, 1.00f);
	colors[ImGuiCol_TitleBgCollapsed]       = ImVec4(0.00f, 0.00f, 0.00f, 0.51f);
	colors[ImGuiCol_MenuBarBg]              = ImVec4(0.14f, 0.14f, 0.14f, 1.00f);
	colors[ImGuiCol_ScrollbarBg]            = ImVec4(0.02f, 0.02f, 0.02f, 0.53f);
	colors[ImGuiCol_ScrollbarGrab]          = ImVec4(0.31f, 0.31f, 0.31f, 1.00f);
	colors[ImGuiCol_ScrollbarGrabHovered]   = ImVec4(0.41f, 0.41f, 0.41f, 1.00f);
	colors[ImGuiCol_ScrollbarGrabActive]    = ImVec4(0.51f, 0.51f, 0.51f, 1.00f);
	colors[ImGuiCol_CheckMark]              = ImVec4(0.87f, 0.23f, 0.09f, 1.00f);
	colors[ImGuiCol_SliderGrab]             = ImVec4(0.87f, 0.23f, 0.09f, 1.00f);
	colors[ImGuiCol_SliderGrabActive]       = ImVec4(1.00f, 0.33f, 0.00f, 1.00f);
	colors[ImGuiCol_Button]                 = ImVec4(0.81f, 0.38f, 0.09f, 0.08f);
	colors[ImGuiCol_ButtonHovered]          = ImVec4(0.87f, 0.23f, 0.09f, 1.00f);
	colors[ImGuiCol_ButtonActive]           = ImVec4(1.00f, 0.33f, 0.00f, 1.00f);
	colors[ImGuiCol_Header]                 = ImVec4(0.81f, 0.38f, 0.09f, 0.08f);
	colors[ImGuiCol_HeaderHovered]          = ImVec4(0.87f, 0.23f, 0.09f, 1.00f);
	colors[ImGuiCol_HeaderActive]           = ImVec4(1.00f, 0.33f, 0.00f, 1.00f);
	colors[ImGuiCol_Separator]              = ImVec4(0.81f, 0.38f, 0.09f, 0.08f);
	colors[ImGuiCol_SeparatorHovered]       = ImVec4(0.87f, 0.23f, 0.09f, 1.00f);
	colors[ImGuiCol_SeparatorActive]        = ImVec4(1.00f, 0.33f, 0.00f, 1.00f);
	colors[ImGuiCol_ResizeGrip]             = ImVec4(0.81f, 0.38f, 0.09f, 0.08f);
	colors[ImGuiCol_ResizeGripHovered]      = ImVec4(0.87f, 0.23f, 0.09f, 1.00f);
	colors[ImGuiCol_ResizeGripActive]       = ImVec4(1.00f, 0.33f, 0.00f, 1.00f);
	colors[ImGuiCol_Tab]                    = ImVec4(0.81f, 0.38f, 0.09f, 0.08f);
	colors[ImGuiCol_TabHovered]             = ImVec4(0.87f, 0.23f, 0.09f, 1.00f);
	colors[ImGuiCol_TabActive]              = ImVec4(1.00f, 0.33f, 0.00f, 1.00f);
	colors[ImGuiCol_TabUnfocused]           = ImVec4(0.81f, 0.38f, 0.09f, 0.08f);
	colors[ImGuiCol_TabUnfocusedActive]     = ImVec4(0.81f, 0.38f, 0.09f, 0.08f);
	colors[ImGuiCol_PlotLines]              = ImVec4(0.61f, 0.61f, 0.61f, 1.00f);
	colors[ImGuiCol_PlotLinesHovered]       = ImVec4(1.00f, 0.43f, 0.35f, 1.00f);
	colors[ImGuiCol_PlotHistogram]          = ImVec4(0.90f, 0.70f, 0.00f, 1.00f);
	colors[ImGuiCol_PlotHistogramHovered]   = ImVec4(1.00f, 0.60f, 0.00f, 1.00f);
	colors[ImGuiCol_TextSelectedBg]         = ImVec4(0.81f, 0.38f, 0.09f, 0.08f);
	colors[ImGuiCol_DragDropTarget]         = ImVec4(1.00f, 1.00f, 0.00f, 0.90f);
	colors[ImGuiCol_NavHighlight]           = ImVec4(1.00f, 0.60f, 0.00f, 1.00f);
	colors[ImGuiCol_NavWindowingHighlight]  = ImVec4(1.00f, 1.00f, 1.00f, 0.70f);
	colors[ImGuiCol_NavWindowingDimBg]      = ImVec4(0.80f, 0.80f, 0.80f, 0.20f);
	colors[ImGuiCol_ModalWindowDimBg]       = ImVec4(0.80f, 0.80f, 0.80f, 0.35f);
	
}


static void HelpMarker(const char* desc)
{
	ImGui::TextDisabled("(?)");
	if (ImGui::IsItemHovered())
	{
		ImGui::BeginTooltip();
		ImGui::PushTextWrapPos(ImGui::GetFontSize() * 35.0f);
		ImGui::TextUnformatted(desc);
		ImGui::PopTextWrapPos();
		ImGui::EndTooltip();
	}
}

void sdf::draw_everything()
{
	ImGuiIO& io = ImGui::GetIO(); (void)io; // void cast prevents unused variable warning

	glClearColor(clear_color.x, clear_color.y, clear_color.z, clear_color.w);   // from hsv picker
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);                     // clear the background

	// draw the stuff on the GPU
	// GPU_Data.display();

	// Start the Dear ImGui frame
	ImGui_ImplOpenGL3_NewFrame();
	ImGui_ImplSDL2_NewFrame(window);
	ImGui::NewFrame();

	// show the demo window
	static bool show_demo_window = true;
	if (show_demo_window) ImGui::ShowDemoWindow(&show_demo_window);


	// do my own window
	ImGui::SetNextWindowPos(ImVec2(10,10));
	ImGui::SetNextWindowSize(ImVec2(256,315));
	ImGui::Begin("Controls", NULL, 0);

	// widgets
	ImGui::Text(" ");
	
	HelpMarker("USER:\nHold SHIFT or use mouse to select text.\n" "CTRL+Left/Right to word jump.\n" "CTRL+A or double-click to select all.\n" "CTRL+X,CTRL+C,CTRL+V clipboard.\n" "CTRL+Z,CTRL+Y undo/redo.\n" "ESCAPE to revert.");


	
	ImGui::End();
	ImGui::Render();

	ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());   // put imgui data into the framebuffer
	
	SDL_GL_SwapWindow(window);			// swap the double buffers 
	
	// handle events
	
	SDL_Event event;
	while (SDL_PollEvent(&event))
	{
		ImGui_ImplSDL2_ProcessEvent(&event);
		if (event.type == SDL_QUIT)
			pquit = true;
		if (event.type == SDL_WINDOWEVENT && event.window.event == SDL_WINDOWEVENT_CLOSE && event.window.windowID == SDL_GetWindowID(window))
			pquit = true;

		if ((event.type == SDL_KEYUP  && event.key.keysym.sym == SDLK_ESCAPE) || (event.type == SDL_MOUSEBUTTONDOWN && event.button.button == SDL_BUTTON_X1)) //x1 is browser back on the mouse
			pquit = true;
		
	}
	
}


void sdf::quit()
{
  //shutdown everything
  ImGui_ImplOpenGL3_Shutdown();
  ImGui_ImplSDL2_Shutdown();
  ImGui::DestroyContext();

  //destroy window
  SDL_GL_DeleteContext(GLcontext);
  SDL_DestroyWindow(window);
  SDL_Quit();
  
  cout << "goodbye." << endl;
}
