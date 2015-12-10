import std.stdio;

//
// NanoVG-d Sample Source
// Copyright (c) 2015 S.Percentage
//
// This software is provided 'as-is', without any express or implied
// warranty.  In no event will the authors be held liable for any damages
// arising from the use of this software.
// Permission is granted to anyone to use this software for any purpose,
// including commercial applications, and to alter it and redistribute it
// freely, subject to the following restrictions:
// 1. The origin of this software must not be misrepresented; you must not
//    claim that you wrote the original software. If you use this software
//    in a product, an acknowledgment in the product documentation would be
//    appreciated but is not required.
// 2. Altered source versions must be plainly marked as such, and must not be
//    misrepresented as being the original software.
// 3. This notice may not be removed or altered from any source distribution.
//

import nanovg, fwt;
import std.string;

final class NanoVGSampleApp : DerelictGLAppBase
{
	mixin AsSingleton;
	private NVGcontext* pContext;
	private int fontid;

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
			this.fontid = nvgCreateFont(this.pContext, "font", "./NotoSans-Regular.ttf");
			if(this.fontid < 0) throw new Exception("nvgCreateFont Error");

			glClearColor(0.0f, 0.0f, 1.0f, 1.0f);
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
		
			nvgFontFaceId(this.pContext, this.fontid);
			nvgFontSize(this.pContext, 20.0f);
			nvgTextAlign(this.pContext, NVG_ALIGN_LEFT | NVG_ALIGN_TOP);
			nvgFontBlur(this.pContext, 0);
			nvgFillColor(this.pContext, nvgRGBAf(0.0f, 0.0f, 0.0f, 1.0f));
			nvgText(this.pContext, 0, 0, "NanoVG.d Sample".toStringz, null);
			
			nvgBeginPath(this.pContext);
			nvgRect(this.pContext, 100, 100, 150, 30);
			nvgFillColor(this.pContext, nvgRGBAf(1.0f, 0.75f, 0.0f, 0.5f));
			nvgFill(this.pContext);
	
			nvgBeginPath(this.pContext);
			nvgRect(this.pContext, 130, 120, 50, 50);
			nvgFillColor(this.pContext, nvgRGBAf(0.0f, 0.5f, 1.0f, 0.75f));
			nvgFill(this.pContext);
	
			nvgBeginPath(this.pContext);
			nvgRoundedRect(this.pContext, 50, 50, 250, 250, 8);
			nvgFillColor(this.pContext, nvgRGBAf(0.0f, 0.0f, 0.0f, 0.25f));
			nvgFill(this.pContext);
	
			nvgBeginPath(this.pContext);
			nvgMoveTo(this.pContext, 200, 200);
			nvgBezierTo(this.pContext, 200, 300, 200, 300, 300, 300);
			nvgStrokeColor(this.pContext, nvgRGBAf(0.0f, 0.0f, 0.0f, 1.0f));
			nvgStrokeWidth(this.pContext, 1.0f);
			nvgStroke(this.pContext);
		
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
