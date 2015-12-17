# NanoVG-d
**Work in Progress**  
NanoVG([memononen/nanovg](https://github.com/memononen/nanovg)) porting and wrapping for dlang

## Features
- Digital Mars D version 2.068 and later are supported.
- Including OpenGL3 renderer and sample(using DerelictGL3/DerelictGLFW3).
- Available on GNU/Linux(Maybe available on Windows)

## Prerequirements
- libnanovg.a(build NanoVG yourself)

## Example(How to use)

```d
import derelict.glfw3.glfw3;
import derelict.opengl3.gl;

// import nanovg-d package
import nanovg;

void main(void)
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
	auto pContext = nvgCreateGL3();
	if(pContext is null) throw new Exception("NanoVG context creation failed.");
	scope(exit) nvgDeleteGL3(pContext);
	auto fontid = nvgCreateFont(pContext, "font", "./NotoSans-Regular.ttf");
	if(fontid < 0) throw new Exception("nvgCreateFont Error");
	
	glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
	while(!glfwWindowShouldClose(pWindow))
	{
		int w, h;
		pWindow.glfwGetFramebufferSize(&w, &h);
		glViewport(0, 0, w, h);
		
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
		{
			nvgBeginFrame(pContext, w, h, cast(float)w / cast(float)h);
			scope(exit) nvgEngFrame(pContext);
		
			// Text
			nvgFontFaceId(pContext, this.fontid);
			nvgFontSize(pContext, 18.0f);
			nvgTextAlign(pContext, NVG_ALIGN_LEFT | NVG_ALIGN_TOP);
			nvgFontBlur(pContext, 0);
			nvgFillColor(pContext, nvgRGBAf(0.0f, 0.0f, 0.0f, 1.0f));
			nvgText(pContext, 8, 8, "NanoVG.d Sample".toStringz, null);
			
			// Filled Rectangle
			nvgBeginPath(pContext);
			nvgRect.pContext, 100, 100, 150, 30);
			nvgFillColor(pContext, nvgRGBAf(1.0f, 0.75f, 0.0f, 0.5f));
			nvgFill(pContext);
			
			// Filled Rectangle2
			nvgBeginPath(this.pContext);
			nvgRect(this.pContext, 130, 120, 50, 50);
			nvgFillColor(this.pContext, nvgRGBAf(0.0f, 0.5f, 1.0f, 0.75f));
			nvgFill(this.pContext);
		
			// Filled/Rounded Rectangle
			nvgBeginPath(this.pContext);
			nvgRoundedRect(this.pContext, 50, 50, 250, 250, 8);
			nvgFillColor(this.pContext, nvgRGBAf(0.0f, 0.0f, 0.0f, 0.25f));
			nvgFill(this.pContext);
			
			// Centered Text
			nvgTextAlign(this.pContext, NVG_ALIGN_CENTER | NVG_ALIGN_TOP);
			nvgFontBlur(this.pContext, 0);
			nvgFillColor(this.pContext, nvgRGBAf(1.0f, 1.0f, 1.0f, 1.0f));
			nvgText(this.pContext, 50 + 250 / 2, 50 + 4, "TestWindow Modoki".toStringz, null);
		
			// Bezier Stroke
			nvgBeginPath(this.pContext);
			nvgMoveTo(this.pContext, 200, 200);
			nvgBezierTo(this.pContext, 200, 300, 200, 300, 300, 300);
			nvgStrokeColor(this.pContext, nvgRGBAf(0.0f, 0.0f, 0.0f, 1.0f));
			nvgStrokeWidth(this.pContext, 1.0f);
			nvgStroke(this.pContext);
		}
		
		pWindow.glfwSwapBuffers();
		glfwPollEvents();
	}
}
```

## License
zlib license(see LICENSE.txt)
