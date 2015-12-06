module fwt.appBase;

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
