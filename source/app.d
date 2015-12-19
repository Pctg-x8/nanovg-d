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
	// private NVGcontext* pContext;
	// private int fontid;
	private NanoVG.ContextGL3 context;
	private NanoVG.Font fontid;

	public override
	{
		void preInit()
		{
			writeln("nanovg-d: NanoVG porting for Dlang.");
		}
		void postInit()
		{
			writeln("OpenGL: ", glGetString(GL_VERSION).fromStringz);
			this.context = new NanoVG.ContextGL3();
			this.fontid = this.context.createFont("font", "./NotoSans-Regular.ttf");
			/*this.pContext = nvgCreateGL3();
			if(this.pContext is null) throw new Exception("NanoVG context creation failed.");
			this.fontid = nvgCreateFont(this.pContext, "font", "./NotoSans-Regular.ttf");
			if(this.fontid < 0) throw new Exception("nvgCreateFont Error");*/

			glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
		}
		void preTerminate()
		{
			// nvgDeleteGL3(this.pContext);
		}

		void render()
		{
			int w, h;
			this.requestFrameSize(w, h);
			glViewport(0, 0, w, h);
			
			glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
			with(this.context)
			{
				beginFrame(w, h, cast(float)w / cast(float)h);
				scope(exit) endFrame();
				
				// Initialize
				fontFace = this.fontid;
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
