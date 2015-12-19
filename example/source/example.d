
import derelict.glfw3.glfw3;
import derelict.opengl3.gl;
import std.string;

// import nanovg-d package
import nanovg;

void main()
{
	// Load/InitLibrary
	DerelictGL3.load();
	DerelictGLFW3.load();
	if(glfwInit() != GL_TRUE) throw new Exception("GLFW initialization failed.");
	scope(exit) glfwTerminate();
	
	// For Intel Graphics(Forced to use OpenGL 3.3 Core Profile)
	glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
	glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
	glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
	
	// CreateWindow
	auto pWindow = glfwCreateWindow(640, 480, "NanoVG.d Example", null, null);
	if(pWindow is null) throw new Exception("GLFW Window creation failed.");
	pWindow.glfwMakeContextCurrent();
	// LazyLoading GL3
	DerelictGL3.reload();
	
	// CenteringWindow
	auto vm = glfwGetVideoMode(glfwGetPrimaryMonitor());
	pWindow.glfwSetWindowPos((vm.width - 640) / 2, (vm.height - 480) / 2);
	
	// CreateNanoVGContext/Font
	// (Download and place NotoSans font)
	auto context = new NanoVG.ContextGL3();
	auto fontid = context.createFont(pContext, "font", "./NotoSans-Regular.ttf");
	
	glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
	while(!glfwWindowShouldClose(pWindow))
	{
		int w, h;
		pWindow.glfwGetFramebufferSize(&w, &h);
		glViewport(0, 0, w, h);
		
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
		with(context)
		{
			beginFrame(w, h, cast(float)w / cast(float)h);
			scope(exit) endFrame();
			
			// Initialize
			fontFace = fontid;
			fontSize = 18.0f;
			fontBlur = 0;
			
			// Title Text
			textAlign = NanoVG.TextAlign.LEFT | NanoVG.TextAlign.TOP;
			fillColor = nvgRGBAf(0.0f, 0.0f, 0.0f, 1.0f);
			text(8, 8, "NanoVG.d Sample");
			
			// Rect1
			beginPath();
			rect(100, 100, 150, 30);
			fillColor = nvgRGBAf(1.0f, 0.75f, 0.0f, 0.5f);
			fill();
			
			// Rect2
			beginPath();
			rect(130, 120, 50, 50);
			fillColor = nvgRGBAf(0.0f, 0.5f, 1.0f, 0.75f);
			fill();
			
			// Rounded Rect
			beginPath();
			roundedRect(50, 50, 250, 250, 8.0f);
			fillColor = nvgRGBAf(0.0f, 0.0f, 0.0f, 0.25f);
			fill();
			
			// Centered Text
			textAlign = NanoVG.TextAlign.CENTER | NanoVG.TextAlign.TOP;
			fillColor = nvgRGBAf(1.0f, 1.0f, 1.0f, 1.0f);
			text(50 + 250 / 2, 50 + 4, "TextWindow Modoki");
			
			// Beizer Curve
			beginPath();
			moveTo(200, 200);
			bezierTo(200, 300, 200, 300, 300, 300);
			strokeColor = nvgRGBAf(0.0f, 0.0f, 0.0f, 1.0f);
			stroke();
		}
		
		pWindow.glfwSwapBuffers();
		glfwPollEvents();
	}
}