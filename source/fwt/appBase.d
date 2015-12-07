module fwt.appBase;

//
// FWT(GLFW Toolkit)
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

// fwt AppBase Class
import derelict.opengl3.gl3, derelict.opengl3.gl;
import derelict.glfw3.glfw3;

mixin template AsSingleton()
{
	private __gshared typeof(this) _instanceCache;
	private static bool hasInstanceCache;
	public static @property instance()
	{
		if(!hasInstanceCache)
		{
			synchronized(typeof(this).classinfo)
			{
				if(_instanceCache is null) _instanceCache = new typeof(this)();
				hasInstanceCache = true;
			}
		}
		return _instanceCache;
	}
	private this(){}
}
mixin template DefaultMain(alias StartupClass) { void main() { StartupClass.instance.run(); } }

// Cannot instantiate
abstract class DerelictGLAppBase
{
	private GLFWwindow* pWindow;

	// Custom Sequences(default is empty)
	public void preInit() {}
	public void postInit() {}
	public void render() {}
	public void preTerminate() {}

	private final void init()
	{
		this.preInit();
		
		DerelictGL3.load();
		DerelictGLFW3.load();
		if(glfwInit() != GL_TRUE) throw new Exception("GLFW initialization failed.");

		glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
		glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
		glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
		this.pWindow = glfwCreateWindow(640, 480, "NanoVG Porting Test", null, null);
		if(this.pWindow is null) throw new Exception("GLFW Window creation failed.");
		this.pWindow.glfwMakeContextCurrent();
		DerelictGL3.reload();

		// centering
		auto vm = glfwGetVideoMode(glfwGetPrimaryMonitor());
		this.pWindow.glfwSetWindowPos((vm.width - 640) / 2, (vm.height - 480) / 2);

		this.postInit();
	}
	private final void terminate()
	{
		this.preTerminate();
		glfwTerminate();
	}

	public void run()
	{
		this.init();
		while(!this.pWindow.glfwWindowShouldClose())
		{
			this.render();
			this.pWindow.glfwSwapBuffers();
			glfwPollEvents();
		}
		this.terminate();
	}

	protected void requestFrameSize(out int w, out int h)
	{
		this.pWindow.glfwGetFramebufferSize(&w, &h);
	}
	protected void adjustViewport()
	{
		int fw, fh;
		this.requestFrameSize(fw, fh);
		glViewport(0, 0, fw, fh);
	}
}
