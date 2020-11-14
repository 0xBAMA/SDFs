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

//	SDL_GL_SetAttribute( SDL_GL_MULTISAMPLEBUFFERS, 1);
//	SDL_GL_SetAttribute( SDL_GL_MULTISAMPLESAMPLES, 8);

	// this is how you query the screen resolution
	SDL_DisplayMode dm;
	SDL_GetDesktopDisplayMode(0, &dm);

	// pulling these out because I'm going to try to span the whole screen with
	// the window, in a way that's flexible on different resolution screens
	int total_screen_width = dm.w;
	int total_screen_height = dm.h;

    cout << "environment is " << total_screen_width << " x " << total_screen_height << endl;

	cout << "creating window...";

	// window = SDL_CreateWindow( "OpenGL Window", 150, 50, total_screen_width-300, total_screen_height-100, SDL_WINDOW_OPENGL | SDL_WINDOW_BORDERLESS | SDL_WINDOW_RESIZABLE);
	window = SDL_CreateWindow( "OpenGL Window", 150, 50, 768, 512, SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE );
	
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
	SDL_GL_SetSwapInterval(1); // Enable vsync
	/* SDL_GL_SetSwapInterval(0); // explicitly disable vsync */






	if (glewInit() != GLEW_OK)
	{
		fprintf(stderr, "Failed to initialize OpenGL loader!\n");
	}

	glEnable(GL_DEPTH_TEST);
    glEnable(GL_POINT_SMOOTH);

    glPointSize(3.0);
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

	clear_color = ImVec4(0.0, 0.0, 0.0, 0.0); // initial value for clear color

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

void sdf::gl_setup()
{
	// some info on your current platform
	const GLubyte *renderer = glGetString( GL_RENDERER ); // get renderer string
	const GLubyte *version = glGetString( GL_VERSION );		// version as a string
	printf( "Renderer: %s\n", renderer );
	printf( "OpenGL version supported %s\n\n\n", version );
	
	
	
    // create the shader for the triangles to draw the pheremone field
    display_shader = Shader("resources/code/shaders/blit.vs.glsl", "resources/code/shaders/blit.fs.glsl").Program;

    // set up the points for the continuum
    //  A---------------B
    //  |          .    |
    //  |       .       |
    //  |    .          |
    //  |               |
    //  C---------------D

    // diagonal runs from C to B
    //  A is -1, 1
    //  B is  1, 1
    //  C is -1,-1
    //  D is  1,-1
    std::vector<glm::vec3> points;
    
    points.clear();
    points.push_back(glm::vec3(-1, 1, 0.5));  //A
    points.push_back(glm::vec3(-1,-1, 0.5));  //C
    points.push_back(glm::vec3( 1, 1, 0.5));  //B

    points.push_back(glm::vec3( 1, 1, 0.5));  //B
    points.push_back(glm::vec3(-1,-1, 0.5));  //C
    points.push_back(glm::vec3( 1,-1, 0.5));  //D

    // vao, vbo
    cout << "  setting up vao, vbo for display geometry...";
    glGenVertexArrays( 1, &display_vao );
    glBindVertexArray( display_vao );

    glGenBuffers( 1, &display_vbo );
    glBindBuffer( GL_ARRAY_BUFFER, display_vbo );
    cout << "done." << endl;

    // buffer the data
    cout << "  buffering vertex data...";
    glBufferData(GL_ARRAY_BUFFER, sizeof(glm::vec3) * points.size(), NULL, GL_DYNAMIC_DRAW);
    glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(glm::vec3) * points.size(), &points[0]);
    cout << "done." << endl;

    // set up attributes
    cout << "  setting up attributes in continuum shader...";
    GLuint points_attrib = glGetAttribLocation(display_shader, "vPosition");
    glEnableVertexAttribArray(points_attrib);
    glVertexAttribPointer(points_attrib, 3, GL_FLOAT, GL_FALSE, 0, (GLvoid*) (static_cast<const char*>(0) + (0)));
    cout << "done." << endl; 
    


    glGenTextures(1, &display_image2D);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, display_image2D);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8UI, DIM, DIM, 0, GL_RGBA_INTEGER, GL_UNSIGNED_BYTE, NULL);
    glBindImageTexture(0, display_image2D, 0, GL_FALSE, 0, GL_READ_WRITE, GL_RGBA8UI);


    // compile the compute shader to do the raycasting
    
    // ...

    CShader csraymarch("resources/code/shaders/raymarch.cs.glsl");
    raymarch_shader = csraymarch.Program;

    CShader csbitcrushRGB("resources/code/shaders/bitcrush_ditherRGB.cs.glsl");
    bitcrush_dither_shaderRGB = csbitcrushRGB.Program;

    CShader csbitcrushHSV("resources/code/shaders/bitcrush_ditherHSV.cs.glsl");
    bitcrush_dither_shaderHSV = csbitcrushHSV.Program;

    CShader csbitcrushHSL("resources/code/shaders/bitcrush_ditherHSL.cs.glsl");
    bitcrush_dither_shaderHSL = csbitcrushHSL.Program;

    CShader csbitcrushYUV("resources/code/shaders/bitcrush_ditherYUV.cs.glsl");
    bitcrush_dither_shaderYUV = csbitcrushYUV.Program;

    CShader csbitcrushsRGB("resources/code/shaders/bitcrush_dithersRGB.cs.glsl");
    bitcrush_dither_shadersRGB = csbitcrushsRGB.Program;

    CShader csbitcrushXYZ("resources/code/shaders/bitcrush_ditherXYZ.cs.glsl");
    bitcrush_dither_shaderXYZ = csbitcrushXYZ.Program;

    CShader csbitcrushxyY("resources/code/shaders/bitcrush_ditherxyY.cs.glsl");
    bitcrush_dither_shaderxyY = csbitcrushxyY.Program;

    CShader csbitcrushHCY("resources/code/shaders/bitcrush_ditherHCY.cs.glsl");
    bitcrush_dither_shaderHCY = csbitcrushHCY.Program;

    CShader csbitcrushYCbCr("resources/code/shaders/bitcrush_ditherYCbCr.cs.glsl");
    bitcrush_dither_shaderYCbCr = csbitcrushYCbCr.Program;

    dither = NONE;
    animate_lighting = true;


    rotation_about_x = 0;
    rotation_about_y = 0;
    rotation_about_z = 0;
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
    // get the screen dimensions and pass in as uniforms

    static glm::mat4 rotation;
    static glm::vec3 position = glm::vec3(0,4,0);
   

	glClearColor(clear_color.x, clear_color.y, clear_color.z, clear_color.w);   // from hsv picker
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);                     // clear the background


    // draw the stuff on the GPU
    // raymarching
    glUseProgram(raymarch_shader); 
    
    // send the light position
    if(animate_lighting)
    {
        glm::vec3 light_position = glm::vec3(0+sin(0.001*SDL_GetTicks()), 4 + 3 * sin(0.0003*SDL_GetTicks()), 6+cos(0.001*SDL_GetTicks()));
        glm::vec3 light_position2 = glm::vec3(0+5*sin(0.0005*SDL_GetTicks()), 4 + 3 * sin(0.0001*SDL_GetTicks()), 6+4*cos(0.0005*SDL_GetTicks()));
        glm::vec3 light_position3 = glm::vec3(0+5*sin(0.0003*SDL_GetTicks()), 4 + 3 * sin(0.0002*SDL_GetTicks()), 6+4*cos(0.0003*SDL_GetTicks()));
        
        glUniform3f(glGetUniformLocation(raymarch_shader, "lightPos"), light_position.x, light_position.y, light_position.z);
        glUniform3f(glGetUniformLocation(raymarch_shader, "lightPos2"), light_position2.x, light_position2.y, light_position2.z);
        glUniform3f(glGetUniformLocation(raymarch_shader, "lightPos3"), light_position3.x, light_position3.y, light_position3.z);
    }
   

    // basis vectors
    glm::vec3 basis_x = (rotation*glm::vec4(1,0,0,0)).xyz();
    glUniform3f(glGetUniformLocation(raymarch_shader, "basis_x"), basis_x.x, basis_x.y, basis_x.z);
    
    glm::vec3 basis_y = (rotation*glm::vec4(0,1,0,0)).xyz();
    glUniform3f(glGetUniformLocation(raymarch_shader, "basis_y"), basis_y.x, basis_y.y, basis_y.z);
    
    glm::vec3 basis_z = (rotation*glm::vec4(0,0,1,0)).xyz();
    glUniform3f(glGetUniformLocation(raymarch_shader, "basis_z"), basis_z.x, basis_z.y, basis_z.z);

    // ray origin
    glUniform3f(glGetUniformLocation(raymarch_shader, "ray_origin"), position.x, position.y, position.z);

    glDispatchCompute( DIM/8, DIM/8, 1 ); //workgroup is 8x8x1, so divide each x and y by 8 
    glMemoryBarrier( GL_SHADER_IMAGE_ACCESS_BARRIER_BIT );

   

    if(dither)
    {
        // Select color space, or none
        switch(dither)
        {
            case NONE:
                break;
            case RGB: 
                glUseProgram(bitcrush_dither_shaderRGB); 
                break;
            case HSL: 
                glUseProgram(bitcrush_dither_shaderHSL); 
                break;
            case HSV: 
                glUseProgram(bitcrush_dither_shaderHSV); 
                break;
            case YUV: 
                glUseProgram(bitcrush_dither_shaderYUV); 
                break;
            case sRGB:
                glUseProgram(bitcrush_dither_shadersRGB); 
                break;
            case XYZ:
                glUseProgram(bitcrush_dither_shaderXYZ); 
                break;
            case xyY:
                glUseProgram(bitcrush_dither_shaderxyY); 
                break;
            case HCY:
                glUseProgram(bitcrush_dither_shaderHCY); 
                break;
            case YCbCr:
                glUseProgram(bitcrush_dither_shaderYCbCr); 
                break;
            default:
                break;
        }
        
        if(dither != NONE)
        {
            glDispatchCompute( DIM/8, DIM/8, 1 ); //workgroup is 8x8x1, so divide each x and y by 8 
            glMemoryBarrier( GL_SHADER_IMAGE_ACCESS_BARRIER_BIT );
        }
    }

    // show the texture
    glUseProgram(display_shader);
    glBindVertexArray( display_vao );
    glBindBuffer( GL_ARRAY_BUFFER, display_vbo );

    glDrawArrays( GL_TRIANGLES, 0, 6 );


	// Start the Dear ImGui frame
	ImGui_ImplOpenGL3_NewFrame();
	ImGui_ImplSDL2_NewFrame(window);
	ImGui::NewFrame();

	// show the demo window
	// static bool show_demo_window = true;
	// if (show_demo_window) ImGui::ShowDemoWindow(&show_demo_window);

	// do my own window
	ImGui::SetNextWindowPos(ImVec2(10,10));
	ImGui::SetNextWindowSize(ImVec2(256,385));
	ImGui::Begin("Controls", NULL, 0);

    

    glm::quat rotationx = glm::angleAxis(rotation_about_x, glm::vec3(1,0,0));
    glm::quat rotationy = glm::angleAxis(rotation_about_y, glm::vec3(0,1,0));
    /* glm::quat rotationz = glm::angleAxis(rotation_about_z, glm::vec3(0,0,1)); */
    rotation = glm::toMat4(rotationy * rotationx);

    ImGui::SliderFloat("rotation about x", &rotation_about_x, -4.0f, 4.0f, "%.2f");
    ImGui::SliderFloat("rotation about y", &rotation_about_y, -4.0f, 4.0f, "%.2f");
    /* ImGui::SliderFloat("rotation about z", &rotation_about_z, -4.0f, 4.0f, "%.2f"); */


    /* cout << glm::to_string(rotation) << endl << endl; */

    // dither method selection
    const char* items[] = { "NONE", "HSL", "HSV", "RGB", "YUV", "sRGB", "XYZ", "xyY", "HCY", "YCbCr"};
    static int item_current = dither;
    ImGui::Combo("Dither", &item_current, items, IM_ARRAYSIZE(items));
    dither = dithertype(item_current);
    
    ImGui::Checkbox("Animate Lights", &animate_lighting);

    //do the other widgets	
    ImGui::SetCursorPosX(45);
    ImGui::ColorEdit3("", (float*)&clear_color); // Edit 3 floats representing a color
    ImGui::SameLine();
    HelpMarker("OpenGL Clear Color");


    ImGui::SetCursorPosX(60);
    ImGui::Text(" %.2f ms (%.1f FPS)", 1000.0f / ImGui::GetIO().Framerate, ImGui::GetIO().Framerate); 


	ImGui::End();
	ImGui::Render();

	ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());   // put imgui data into the framebuffer
    glViewport(0, 0, (int)io.DisplaySize.x, (int)io.DisplaySize.y);	

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
