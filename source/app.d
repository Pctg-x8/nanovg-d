import std.stdio;

import nanovg, fwt;
import std.string;

final class NanoVGSampleApp : DerelictGLAppBase
{
	mixin AsSingleton;
	private NVGcontext* pContext;

	public override
	{
		void preInit()
		{
			writeln("nanovg-d: NanoVG porting for Dlang.");
		}
		void postInit()
		{
			/+this.pContext = nvgCreateGL3(NVG_ANTIALIAS | NVG_STENCIL_STROKES | NVG_DEBUG);
			if(this.pContext is null) throw new Exception("NanoVG initialization failed.");+/
			writeln("OpenGL: ", glGetString(GL_VERSION).fromStringz);
			this.pContext = nvgCreateGL3();
			if(this.pContext is null) throw new Exception("NanoVG context creation failed.");

			glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
		}
		void preTerminate()
		{
			nvgDeleteGL3(this.pContext);
		}

		void render()
		{
			int w, h;
			this.requestFrameSize(w, h);
			glViewport(0, 0, w, h);
			
			glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
			nvgBeginFrame(this.pContext, w, h, cast(float)w / cast(float)h);
			
			nvgEndFrame(this.pContext);
		}
	}
}
mixin DefaultMain!NanoVGSampleApp;

/+
	while(!glfwWindowShouldClose(window))
	{
		int ww, wh, fw, fh;
		glfwGetWindowSize(window, &ww, &wh);
		glfwGetFramebufferSize(window, &fw, &fh);

		glViewport(0, 0, fw, fh);

		glClear(GL_COLOR_BUFFER_BIT);
		/*nvgBeginFrame(pContext, ww, wh, cast(float)fw / fh);

		nvgBeginPath(pContext);
		nvgRect(pContext, 100, 100, 150, 30);
		nvgFillColor(pContext, nvgRGBAf(1.0f, 0.75f, 0.0f, 0.5f));
		nvgFill(pContext);

		nvgBeginPath(pContext);
		nvgRect(pContext, 130, 120, 50, 50);
		nvgFillColor(pContext, nvgRGBAf(0.0f, 0.5f, 1.0f, 0.75f));
		nvgFill(pContext);

		nvgBeginPath(pContext);
		nvgRoundedRect(pContext, 50, 50, 250, 250, 4);
		nvgFillColor(pContext, nvgRGBAf(0.0f, 0.0f, 0.0f, 0.25f));
		nvgFill(pContext);

		nvgBeginPath(pContext);
		nvgMoveTo(pContext, 200, 200);
		nvgBezierTo(pContext, 200, 300, 200, 300, 300, 300);
		nvgStrokeColor(pContext, nvgRGBAf(0.0f, 0.0f, 0.0f, 1.0f));
		nvgStrokeWidth(pContext, 1.0f);
		nvgStroke(pContext);

		nvgEndFrame(pContext);*/
		glfwSwapBuffers(window);
		glfwPollEvents();
	}
+/
