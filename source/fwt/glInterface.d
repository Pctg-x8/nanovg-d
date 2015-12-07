module fwt.glInterface;

//
// OpenGL Interfacing D
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

import derelict.opengl3.gl3, derelict.opengl3.gl;
import std.typecons, std.string, std.algorithm;

alias Size = Tuple!(int, "width", int, "height");
bool raised(int flag)(int flagSet) { return (flagSet & flag) != 0; }

class GLShaderCompileError : Exception
{
	public this(GLuint shader, string type)
	{
		GLint logLength;
		GLchar[] log;
		
		shader.glGetShaderiv(GLShaderInfo.LogLength, &logLength);
		if(logLength > 0)
		{
			log.length = logLength;
			shader.glGetShaderInfoLog(logLength, null, log.ptr);
			super(type ~ " Compilation Error: " ~ log.ptr.fromStringz.idup);
		}
		else super(type ~ " Compilation Error: No info available.");
	}
}
class GLProgramLinkError : Exception
{
	public this(GLuint program)
	{
		GLint logLength;
		GLchar[] log;
		
		program.glGetProgramiv(GLProgramInfo.LogLength, &logLength);
		if(logLength > 0)
		{
			log.length = logLength;
			program.glGetProgramInfoLog(logLength, null, log.ptr);
			super("Program Linking Error: " ~ log.ptr.fromStringz.idup);
		}
		else super("Program Linking Error: No info available.");
	}
}
class GLException : Exception
{
	public this(GLenum errcode)
	{
		super("OpenGL Error: 0x" ~ format("%04x", errcode));
	}
}
void glCheckError()
{
	auto err = glGetError();
	if(err != GL_NO_ERROR) throw new GLException(err);
}

enum GLShaderInfo : GLenum
{
	CompileStatus = GL_COMPILE_STATUS,
	LogLength = GL_INFO_LOG_LENGTH,
}
enum GLProgramInfo : GLenum
{
	LinkStatus = GL_LINK_STATUS,
	LogLength = GL_INFO_LOG_LENGTH
}

static class GLPixelStore
{
	static class Parameter(GLenum E)
	{
		static void opAssign(int i)
		{
			glPixelStorei(E, i);
		}
	}
	
	alias Alignment = Parameter!GL_UNPACK_ALIGNMENT;
	alias RowLength = Parameter!GL_UNPACK_ROW_LENGTH;
	alias SkipPixels = Parameter!GL_UNPACK_SKIP_PIXELS;
	alias SkipRows = Parameter!GL_UNPACK_SKIP_ROWS;
}
static class GLTexture2D
{
	static class Parameter(GLenum E)
	{
		static void opAssign(int i)
		{
			glTexParameteri(GL_TEXTURE_2D, E, i);
		}
	}
	
	static class Wrap
	{
		alias S = Parameter!GL_TEXTURE_WRAP_S;
		alias T = Parameter!GL_TEXTURE_WRAP_T;
	}
	static class Filter
	{
		alias Min = Parameter!GL_TEXTURE_MIN_FILTER;
		alias Mag = Parameter!GL_TEXTURE_MAG_FILTER;
	}
}
static class ArrayData(GLenum T)
{
	static void opAssign(E)(E[] ary)
	{
		glBufferData(T, ary.length * E.sizeof, ary.ptr, GL_STREAM_DRAW);
		glCheckError();
	}
}
struct ByteRange
{
	size_t offset, length;
}
static class GLUniformBuffer
{
	alias ArrayData = .ArrayData!GL_UNIFORM_BUFFER;
	static class BindRange
	{
		static void opIndexAssign(ByteRange br, GLint i, GLint bi)
		{
			glBindBufferRange(GL_UNIFORM_BUFFER, i, bi, br.offset, br.length);
			glCheckError();
		}
	}
	
	static int opDispatch(string op)() if(op == "OffsetAlignment")
	{
		int v;
		glGetIntegerv(GL_UNIFORM_BUFFER_OFFSET_ALIGNMENT, &v);
		return v;
	}
}
struct DisablePointer { /* empty */ }
alias PlainFloatPointer = Tuple!(int, "dim", size_t, "stride", size_t, "offset");
static class GLArrayBuffer
{
	alias ArrayData = .ArrayData!GL_ARRAY_BUFFER;
	static class AttribPointer
	{
		static void opIndexAssign(PlainFloatPointer p, GLint l)
		{
			glEnableVertexAttribArray(l); glCheckError();
			glVertexAttribPointer(l, p.dim, GL_FLOAT, GL_FALSE,
				cast(GLint)p.stride, cast(const(GLvoid)*)p.offset);
			glCheckError();
		}
		static void opIndexAssign(DisablePointer p, GLint l)
		{
			glDisableVertexAttribArray(l);
			glCheckError();
		}
	}
}
static class GLProgram
{
	static class Uniform
	{
		static void opIndexAssign(GLint i, GLint l)
		{
			glUniform1i(l, i);
		}
		static void opIndexAssign(float[2] v2, GLint l)
		{
			glUniform2fv(l, 1, v2.ptr);
		}
	}
}

const GLuint NullTexture = 0;
const GLuint DisableProgram = 0;
alias GLBlendFuncParams = Tuple!(GLenum, "src", GLenum, "dst");
static class GLBlendPresets
{
	// src + dst * (1.0f - src.alpha)
	static const PremultipliedBlending = GLBlendFuncParams(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
}
alias GLStencilOpSet = Tuple!(GLenum, "stencilFail", GLenum, "depthFail", GLenum, "depthSucc");
static class GLStencilOpPresets
{
	static const Keep = GLStencilOpSet(GL_KEEP, GL_KEEP, GL_KEEP);
	static const Zero = GLStencilOpSet(GL_ZERO, GL_ZERO, GL_ZERO);
	static const IncrementOnSucceeded = GLStencilOpSet(GL_KEEP, GL_KEEP, GL_INCR);
}
alias GLStencilFuncParams = Tuple!(GLenum, "func", GLint, "refv", GLuint, "mask");
// Switch Constant
enum : bool { Disable = false, Enable = true }
enum GLFaceDirection : GLenum
{
	Front = GL_FRONT, Back = GL_BACK
}
enum GLPathDirection : GLenum
{
	Clockwise = GL_CW, CounterClockwise = GL_CCW
}
static class GLSwitchOptions(GLenum E)
{
	static void opAssign(bool sw) { (sw ? glEnable : glDisable)(E); }
}
static class GLTupleSetter(alias F, T)
{
	static void opAssign(T p) { F(p.expand); }
}
static class GLSingleSetter(alias F, T)
{
	static void opAssign(T p) { F(p); }
}
auto asGLbool(bool b) { return b ? GL_TRUE : GL_FALSE; }
static class GLContext
{
	static class BindTexture(GLenum E)
	{
		static void opAssign(GLuint i)
		{
			glBindTexture(E, i);
		}
	}
	static class BindBuffer(GLenum E, T)
	{
		static void opAssign(T i) { glBindBuffer(E, i is null ? 0 : i.id); }
	}
	static class VertexArray
	{
		static void opAssign(VertexArrayObject o) { glBindVertexArray(o is null ? 0 : o.id); }
	}
	static class RenderProgram
	{
		static void opAssign(GLuint p) { glUseProgram(p); }
	}
	static class Blend
	{
		alias Enable = GLSwitchOptions!GL_BLEND;
		alias Func = GLTupleSetter!(glBlendFunc, GLBlendFuncParams);
	}
	static class CullFace
	{
		alias Enable = GLSwitchOptions!GL_CULL_FACE;
		alias Direction = GLSingleSetter!(glCullFace, GLFaceDirection);
		alias FrontFace = GLSingleSetter!(glFrontFace, GLPathDirection);
	}
	static class DepthTest
	{
		alias Enable = GLSwitchOptions!GL_DEPTH_TEST;
	}
	static class ScissorTest
	{
		alias Enable = GLSwitchOptions!GL_SCISSOR_TEST;
	}
	static class Stencil
	{
		alias EnableTest = GLSwitchOptions!GL_STENCIL_TEST;
		alias Mask = GLSingleSetter!(glStencilMask, GLuint);
		static class Operations
		{
			static void opAssign(GLStencilOpSet args) { glStencilOp(args.expand); }
			static void opIndexAssign(GLStencilOpSet args, GLFaceDirection dir)
			{
				glStencilOpSeparate(dir, args.expand);
			}
		}
		alias Func = GLTupleSetter!(glStencilFunc, GLStencilFuncParams);
	}
	static class ActiveTexture
	{
		static void opAssign(GLuint index)
		{
			glActiveTexture(GL_TEXTURE0 + index);
			glCheckError();
		}
	}
	static class ColorMask
	{
		static void opAssign(bool[4] col)
		{
			glColorMask(col[0].asGLbool, col[1].asGLbool, col[2].asGLbool, col[3].asGLbool);
		}
	}
	
	alias Texture2D = BindTexture!GL_TEXTURE_2D;
	alias UniformBuffer = BindBuffer!(GL_UNIFORM_BUFFER, UniformBufferObject);
	alias ArrayBuffer = BindBuffer!(GL_ARRAY_BUFFER, ArrayBufferObject);
}

// OpenGL Objects
class BufferObject
{
	GLuint buffer;
	
	@property id() { return this.buffer; }
	
	public this()
	{
		glGenBuffers(1, &this.buffer);
	}
	~this()
	{
		glDeleteBuffers(1, &this.buffer);
	}
}
alias UniformBufferObject = BufferObject;
alias ArrayBufferObject = BufferObject;
class VertexArrayObject
{
	GLuint buffer;
	@property id() { return this.buffer; }
	
	public this()
	{
		glGenVertexArrays(1, &this.buffer);
	}
	~this()
	{
		glDeleteVertexArrays(1, &this.buffer);
	}
}
