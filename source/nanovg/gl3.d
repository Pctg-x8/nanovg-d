module nanovg.gl3;

//
// NanoVG-d:
// Copyright (c) 2015 S.Percentage
//
// Original Source(NanoVG):
// Copyright (c) 2013 Mikko Mononen memon@inside.org
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

// NanoVG OpenGL3 renderer Implementation

import nanovg.h;
import derelict.opengl3.gl3;
import std.string, std.range, std.algorithm, std.math;
import core.memory;
import std.experimental.logger;

public import fwt.glInterface;

enum CommandType
{
	Fill, ConvexFill, Stroke, Triangles
}
enum ImageType
{
	Single, RGBA
}
enum ShaderType : int
{
	Gradient, Textured, StencilFilling, TexturedTris	
}
enum TexturePostProcess : int
{
	None, Multiply, Colorize
}

auto premultiplied(NVGcolor color)
{
	return NVGcolor(color.r * color.a, color.g * color.a, color.b * color.a, color.a);
}
auto asFloat4(NVGcolor color)
{
	return [color.r, color.g, color.b, color.a];
}
auto asMatrix3x4(float[6] xform)
{
	return
	[
		xform[0], xform[1], 0.0f, 0.0f,
		xform[2], xform[3], 0.0f, 0.0f,
		xform[4], xform[5], 1.0f, 0.0f
	];
}
auto maxVertCount(const(NVGpath)[] paths)
{
	return paths.map!(a => a.nfill + a.nstroke).sum;
}

class Texture
{
	GLuint texture, sampler;
	Size size;
	ImageType type;
	int flags;
	
	public this(int w, int h, int type, int imageFlags, const(byte)* pData)
	{
		info("CreateTexture: ", w, "/", h);
		this.size = Size(w, h);
		this.flags = imageFlags;
		
		glGenTextures(1, &this.texture);
		GLContext.Texture2D = this.texture;
		this.setPixelStoreState();
		
		GLTexture2D.Wrap.S = imageFlags.raised!NVG_IMAGE_REPEATX ? GL_REPEAT : GL_CLAMP_TO_EDGE;
		GLTexture2D.Wrap.T = imageFlags.raised!NVG_IMAGE_REPEATY ? GL_REPEAT : GL_CLAMP_TO_EDGE;
		GLTexture2D.Filter.Min = imageFlags.raised!NVG_IMAGE_GENERATE_MIPMAPS ? GL_LINEAR_MIPMAP_LINEAR : GL_LINEAR;
		GLTexture2D.Filter.Mag = GL_LINEAR;
		switch(type)
		{
		case NVG_TEXTURE_RGBA:
			this.type = ImageType.RGBA;
			glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, pData);
			break;
		default:
			this.type = ImageType.Single;
			glTexImage2D(GL_TEXTURE_2D, 0, GL_RED, w, h, 0, GL_RED, GL_UNSIGNED_BYTE, pData);
		}
		glCheckError();
		this.revertPixelStoreState();
		if(imageFlags.raised!NVG_IMAGE_GENERATE_MIPMAPS)
		{
			glGenerateMipmap(GL_TEXTURE_2D);
			glCheckError();
		}
		GLContext.Texture2D = NullTexture;
		
		/*glGenSamplers(1, &this.sampler);
		this.sampler.glSamplerParameteri(GL_TEXTURE_WRAP_S, imageFlags.raised!NVG_IMAGE_REPEATX ? GL_REPEAT : GL_CLAMP_TO_EDGE);
		this.sampler.glSamplerParameteri(GL_TEXTURE_WRAP_T, imageFlags.raised!NVG_IMAGE_REPEATY ? GL_REPEAT : GL_CLAMP_TO_EDGE);
		this.sampler.glSamplerParameteri(GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
		this.sampler.glSamplerParameteri(GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glCheckError();*/
	}
	public ~this()
	{
		glDeleteSamplers(1, &this.sampler);
		glDeleteTextures(1, &this.texture);
	}
	private void setPixelStoreState()
	{
		GLPixelStore.Alignment = 1;
		GLPixelStore.RowLength = this.size.width;
		GLPixelStore.SkipPixels = 0;
		GLPixelStore.SkipRows = 0;
	}
	private void revertPixelStoreState()
	{
		GLPixelStore.SkipRows = 0;
		GLPixelStore.SkipPixels = 0;
		GLPixelStore.RowLength = 0;
		GLPixelStore.Alignment = 4;
	}
	
	bool update(int x, int y, int w, int h, const(byte)* data)
	{
		info("UpdateTexture: ", x, "/", y, "/", w, "/", h);
		info("UpdateData: \n", data[0 .. w * h].map!(a => format("%02x", a)).chunks(16).enumerate.map!(a => format("+%04x: ", a[0] * 0x10) ~ a[1].join(" ")).join("\n"));
		GLContext.Texture2D = this.texture;
		this.setPixelStoreState();
		GLPixelStore.SkipPixels = x;
		GLPixelStore.SkipRows = y;
		
		final switch(this.type)
		{
		case ImageType.RGBA:
			glTexSubImage2D(GL_TEXTURE_2D, 0, x, y, w, h, GL_RGBA, GL_UNSIGNED_BYTE, data);
			break;
		case ImageType.Single:
			glTexSubImage2D(GL_TEXTURE_2D, 0, x, y, w, h, GL_RED, GL_UNSIGNED_BYTE, data);
		}
		glCheckError();
		
		this.revertPixelStoreState();
		GLContext.Texture2D = NullTexture;
		return true;
	}
	bool getTextureSize(int* w, int* h)
	{
		*w = this.size.width;
		*h = this.size.height;
		return true;
	}
}

class RenderProgram
{
	GLuint vsh, fsh, program;
	
	public this()
	{
		this.vsh = glCreateShader(GL_VERTEX_SHADER);
		this.fsh = glCreateShader(GL_FRAGMENT_SHADER);
		this.program = glCreateProgram();
		
		this.vsh.glShaderSource(1, [import("vertex.glsl").toStringz].ptr, null);
		this.fsh.glShaderSource(1, [import("fragment.glsl").toStringz].ptr, null);
		this.buildShaders();
		this.uniformBlocks = new UniformBlockIndexAccessor();
		this.uniforms = new UniformLocationAccessor();
		this.inputs = new AttributeLocationAccessor();
	}
	private void buildShaders()
	{
		GLint status;
		
		this.vsh.glCompileShader();
		this.vsh.glGetShaderiv(GLShaderInfo.CompileStatus, &status);
		if(status != GL_TRUE) throw new GLShaderCompileError(this.vsh, "Vertex");
		this.fsh.glCompileShader();
		this.fsh.glGetShaderiv(GLShaderInfo.CompileStatus, &status);
		if(status != GL_TRUE) throw new GLShaderCompileError(this.fsh, "Fragment");
		this.program.glAttachShader(this.vsh);
		this.program.glAttachShader(this.fsh);
		this.program.glLinkProgram();
		this.program.glGetProgramiv(GLProgramInfo.LinkStatus, &status);
		if(status != GL_TRUE) throw new GLProgramLinkError(this.program);
	}
	
	class UniformBlockIndexAccessor
	{
		GLint[string] cache;
		
		public this() { this.userIndexes = new UserIndexAccessor(); }
		GLint opDispatch(string op)() { return this[op]; }
		GLint opIndex(string op)
		{
			if(op in cache) return cache[op];
			cache[op] = this.outer.program.glGetUniformBlockIndex(op.toStringz);
			return cache[op];
		}
		class UserIndexAccessor
		{
			void opIndexAssign(GLint idx, string vn)
			{
				info("UniformBlock Binding: ", this.outer[vn], " <=> ", idx);
				glUniformBlockBinding(this.outer.outer.program, this.outer[vn], idx);
				glCheckError();
			}
		}
		UserIndexAccessor userIndexes;
	}
	UniformBlockIndexAccessor uniformBlocks;
	class UniformLocationAccessor
	{
		GLint[string] cache;
		
		GLint opDispatch(string op)()
		{
			if(op in cache) return cache[op];
			cache[op] = this.outer.program.glGetUniformLocation(op.toStringz);
			return cache[op];
		}
	}
	UniformLocationAccessor uniforms;
	class AttributeLocationAccessor
	{
		GLint[string] cache;
		
		GLint opDispatch(string op)()
		{
			if(op in cache) return cache[op];
			cache[op] = this.outer.program.glGetAttribLocation(op.toStringz);
			return cache[op];
		}
	}
	AttributeLocationAccessor inputs;
}
struct FragUniformBuffer
{
	float[3*4] scissorMatr, paintMatr;
	float[4] innerColor, outerColor;
	float[2] scissorExt, scissorScale;
	float[2] extent;
	float radius, feather;
	float strokeMult, strokeThr;
	int texType, type;
}
struct InternalDrawCall
{
	CommandType type;
	int image;
	size_t pathOffset, pathCount;
	size_t triangleOffset, triangleCount;
	size_t uniformOffset;
}
struct Path
{
	size_t fillOffset, fillCount;
	size_t strokeOffset, strokeCount;
}

class Context
{
	const FUBUserIndex = 1;
	
	RenderProgram program;
	UniformBufferObject fragUniformObject;
	VertexArrayObject varray;
	ArrayBufferObject vbuffer;
	Texture[] textureList;
	Path[] pathList;
	InternalDrawCall[] callList;
	NVGvertex[] vertexList;
	FragUniformBuffer[] uniformList;
	Size vport;
	size_t ubHardwareSize, ubHardwarePadding;
	
	GLint ublocFrag;
	GLint ulocTexImage, ulocViewSize;
	GLint alocVertex, alocTexcoord;

	void init()
	{
		this.program = new RenderProgram();
		this.ublocFrag = this.program.uniformBlocks.frag;
		this.ulocTexImage = this.program.uniforms.texImage;
		this.ulocViewSize = this.program.uniforms.viewSize;
		this.alocVertex = this.program.inputs.vertex;
		this.alocTexcoord = this.program.inputs.texcoord;
		
		info("viewSize Location: ", this.ulocViewSize);
		info("texImage Location: ", this.ulocTexImage);
		
		this.program.uniformBlocks.userIndexes["frag"] = FUBUserIndex;
		this.fragUniformObject = new UniformBufferObject();
		this.varray = new VertexArrayObject();
		this.vbuffer = new ArrayBufferObject();
		int ub_align = GLUniformBuffer.OffsetAlignment;
		this.ubHardwareSize = (cast(int)((FragUniformBuffer.sizeof - 1) / ub_align) + 1) * ub_align;
		this.ubHardwarePadding = this.ubHardwareSize - FragUniformBuffer.sizeof;
		info("GL UniformBlockAlign: ", ub_align);
		info("HardwareUniformBlockSize: ", this.ubHardwareSize);
		info("UniformBlockPadding: ", this.ubHardwarePadding);
		
		glFinish();
	}
	void terminate() {}
	int createTexture(int type, int w, int h, int imageFlags, const(byte)* data)
	{
		auto emptyIter = this.textureList.enumerate.filter!(a => a.value is null);
		if(!emptyIter.empty)
		{
			emptyIter.front.value = new Texture(w, h, type, imageFlags, data);
			return cast(int)emptyIter.front.index + 1;
		}
		else
		{
			this.textureList ~= new Texture(w, h, type, imageFlags, data);
			return cast(int)this.textureList.length;
		}
	}
	void deleteTexture(int image_id)
	{
		this.textureList[image_id - 1] = null;
	}
	Texture findTexture(int image_id)
	{
		return this.textureList[image_id - 1];
	}

	void cancelRender()
	{
		this.pathList = null;
		this.callList = null;
		this.vertexList = null;
		this.uniformList = null;
	}
	void flush()
	{
		this.processCallList();
		this.cancelRender();
	}
	private void processCallList()
	{
		if(this.callList.empty) return;
		
		// render init
		GLContext.RenderProgram = this.program.program;
		GLContext.ColorMask = [true, true, true, true];
		// blend
		GLContext.Blend.Enable = true;
		GLContext.Blend.Func = GLBlendPresets.PremultipliedBlending;
		// cullface
		GLContext.CullFace.Enable = true;
		GLContext.CullFace.Direction = GLFaceDirection.Back;
		GLContext.CullFace.FrontFace = GLPathDirection.CounterClockwise;
		// stencil
		GLContext.Stencil.Mask = GLuint.max;
		GLContext.Stencil.Operations = GLStencilOpPresets.Keep;
		GLContext.Stencil.Func = GLStencilFuncParams(GL_ALWAYS, 0, GLuint.max);
		// switch
		GLContext.DepthTest.Enable = false;
		GLContext.ScissorTest.Enable = false;
		// activate shader resource
		GLContext.ActiveTexture = 0;
		GLContext.Texture2D = NullTexture;
		// uniform setup
		ubyte[] uniformBytes;
		foreach(i, ref ub; this.uniformList)
		{
			auto pBytePtr = cast(ubyte*)&ub;
			uniformBytes ~= pBytePtr[0 .. FragUniformBuffer.sizeof];
			if(this.ubHardwarePadding > 0) uniformBytes.length += this.ubHardwarePadding;
		}
		info(false, "uniforms: ", this.uniformList);
		info(false, "uniformBufferData: \n", uniformBytes.map!(a => format("%02x", a)).chunks(16).enumerate.map!(a => format("+%04x: ", a[0] * 0x10) ~ a[1].join(" ")).join("\n"));
		GLContext.UniformBuffer = this.fragUniformObject;
		GLUniformBuffer.ArrayData = uniformBytes;
		GLProgram.Uniform[this.ulocTexImage] = 0;
		GLProgram.Uniform[this.ulocViewSize] = [this.vport.width, this.vport.height];
		// vertex array setup
		GLContext.VertexArray = this.varray;
		GLContext.ArrayBuffer = this.vbuffer;
		GLArrayBuffer.ArrayData = this.vertexList;
		GLArrayBuffer.AttribPointer[this.alocVertex] = PlainFloatPointer(2, NVGvertex.sizeof, NVGvertex.x.offsetof);
		GLArrayBuffer.AttribPointer[this.alocTexcoord] = PlainFloatPointer(2, NVGvertex.sizeof, NVGvertex.u.offsetof);
		
		foreach(call; this.callList)
		{
			info("callType: ", call.type);
			final switch(call.type)
			{
			case CommandType.Fill: this.processFill(call); break;
			case CommandType.ConvexFill: this.processConvexFill(call); break;
			case CommandType.Stroke: this.processStroke(call); break;
			case CommandType.Triangles: this.processTriangles(call);
			}
		}
		
		GLArrayBuffer.AttribPointer[this.alocTexcoord] = DisablePointer();
		GLArrayBuffer.AttribPointer[this.alocVertex] = DisablePointer();
		GLContext.ArrayBuffer = cast(ArrayBufferObject)null;
		GLContext.VertexArray = cast(VertexArrayObject)null;
		GLContext.CullFace.Enable = false;
		GLContext.Texture2D = NullTexture;
		GLContext.RenderProgram = DisableProgram;
	}
	const FillFunc = (Path a) { glDrawArrays(GL_TRIANGLE_FAN, cast(int)a.fillOffset, cast(int)a.fillCount); };
	const DrawStrokeFunc = (Path a) { glDrawArrays(GL_TRIANGLE_STRIP, cast(int)a.strokeOffset, cast(int)a.strokeCount); };
	private void processFill(InternalDrawCall call)
	{
		auto processList = this.pathList[call.pathOffset .. call.pathOffset + call.pathCount];
		
		// Draw shapes
		GLContext.Stencil.EnableTest = true;
		GLContext.Stencil.Mask = 0xff;
		GLContext.Stencil.Func = GLStencilFuncParams(GL_ALWAYS, 0, 0xff);
		GLContext.ColorMask = [false, false, false, false];
		this.setUniformAndTexture(call.uniformOffset, 0);
		GLContext.Stencil.Operations[GLFaceDirection.Front] = GLStencilOpSet(GL_KEEP, GL_KEEP, GL_INCR_WRAP);
		GLContext.Stencil.Operations[GLFaceDirection.Back] = GLStencilOpSet(GL_KEEP, GL_KEEP, GL_DECR_WRAP);
		GLContext.CullFace.Enable = false;
		processList.each!FillFunc;
		GLContext.CullFace.Enable = true;
		
		// Draw anti-aliased pixels
		GLContext.ColorMask = [true, true, true, true];
		this.setUniformAndTexture(call.uniformOffset + 1, call.image);
		GLContext.Stencil.Func = GLStencilFuncParams(GL_EQUAL, 0, 0xff);
		GLContext.Stencil.Operations = GLStencilOpPresets.Keep;
		processList.each!DrawStrokeFunc;
		
		// Draw fill
		GLContext.Stencil.Func = GLStencilFuncParams(GL_NOTEQUAL, 0, 0xff);
		GLContext.Stencil.Operations = GLStencilOpPresets.Zero;
		glDrawArrays(GL_TRIANGLES, cast(int)call.triangleOffset, cast(int)call.triangleCount);
		
		GLContext.Stencil.EnableTest = false;
	}
	private void processConvexFill(InternalDrawCall call)
	{
		auto processList = this.pathList[call.pathOffset .. call.pathOffset + call.pathCount];
		
		this.setUniformAndTexture(call.uniformOffset, call.image);
		processList.each!FillFunc;
		processList.each!DrawStrokeFunc;
	}
	private void processStroke(InternalDrawCall call)
	{
		auto processList = this.pathList[call.pathOffset .. call.pathOffset + call.pathCount];
		
		// Uses Stencil Stroke
		GLContext.Stencil.EnableTest = true;
		GLContext.Stencil.Mask = 0xff;
		
		// Fill the stroke base without overlap
		GLContext.Stencil.Func = GLStencilFuncParams(GL_EQUAL, 0, 0xff);
		GLContext.Stencil.Operations = GLStencilOpPresets.IncrementOnSucceeded;
		this.setUniformAndTexture(call.uniformOffset + 1, call.image);
		processList.each!DrawStrokeFunc;
		
		// Draw anti-aliased pixels
		this.setUniformAndTexture(call.uniformOffset, call.image);
		GLContext.Stencil.Func = GLStencilFuncParams(GL_EQUAL, 0, 0xff);
		GLContext.Stencil.Operations = GLStencilOpPresets.Keep;
		processList.each!DrawStrokeFunc;
		
		// Clear stencil buffer
		GLContext.ColorMask = [false, false, false, false];
		GLContext.Stencil.Func = GLStencilFuncParams(GL_ALWAYS, 0, 0xff);
		GLContext.Stencil.Operations = GLStencilOpPresets.Zero;
		processList.each!DrawStrokeFunc;
		GLContext.ColorMask = [true, true, true, true];
		
		GLContext.Stencil.EnableTest = false;
	}
	private void processTriangles(InternalDrawCall call)
	{
		this.setUniformAndTexture(call.uniformOffset, call.image);
		glDrawArrays(GL_TRIANGLES, cast(int)call.triangleOffset, cast(int)call.triangleCount);
	}
	private void allocatePathList(CommandType T)(const(NVGpath)[] paths)
	{
		foreach(path; paths)
		{
			Path internal;
			
			static if(T == CommandType.Fill) if(path.nfill > 0)
			{
				internal.fillOffset = this.vertexList.length;
				internal.fillCount = path.nfill;
				this.vertexList ~= path.fill[0 .. path.nfill];
			}
			if(path.nstroke > 0)
			{
				internal.strokeOffset = this.vertexList.length;
				internal.strokeCount = path.nstroke;
				this.vertexList ~= path.stroke[0 .. path.nstroke];
			}
			this.pathList ~= internal;
		}
	}
	void pushCommand(CommandType T, Param)(NVGpaint* paint, NVGscissor* scissor, float fringe, const(NVGpath)[] paths, Param param)
	{
		InternalDrawCall call;
		with(call)
		{
			type = T;
			pathOffset = this.pathList.length;
			pathCount = paths.length;
			image = paint.image;
			uniformOffset = this.uniformList.length;
		}
		this.allocatePathList!T(paths);
		
		// Depended by CommandType
		static if(T == CommandType.Fill)
		{
			if(paths.length == 1 && paths.front.convex) call.type = CommandType.ConvexFill;
		
			// quad
			auto quad = [
				NVGvertex(param[0], param[3], 0.5f, 1.0f),
				NVGvertex(param[2], param[3], 0.5f, 1.0f),
				NVGvertex(param[2], param[1], 0.5f, 1.0f),
				NVGvertex(param[0], param[3], 0.5f, 1.0f),
				NVGvertex(param[2], param[1], 0.5f, 1.0f),
				NVGvertex(param[0], param[1], 0.5f, 1.0f)
			];
			call.triangleOffset = this.vertexList.length;
			call.triangleCount = 6;
			this.vertexList ~= quad;
		
			// Set UniformBuffer
			if(call.type == CommandType.Fill)
			{
				FragUniformBuffer ub_stencil;
				ub_stencil.strokeThr = -1.0f;
				ub_stencil.type = ShaderType.StencilFilling;
				this.uniformList ~= ub_stencil;
			}
			this.uniformList ~= this.createUniformBufferFromPaint(*paint, *scissor, fringe, fringe, -1.0f);
		}
		else static if(T == CommandType.Stroke)
		{
			this.uniformList ~= this.createUniformBufferFromPaint(*paint, *scissor, param, fringe, -1.0f);
			this.uniformList ~= this.createUniformBufferFromPaint(*paint, *scissor, param, fringe, 1.0f - 0.5f / 255.0f);
		}
		else static assert(false, "Invalid CommandType for pushCommand");
		
		this.callList ~= call;
	}
	void pushTrianglesCommand(NVGpaint* paint, NVGscissor* scissor, const(NVGvertex)[] verts)
	{
		InternalDrawCall call;
		with(call)
		{
			type = CommandType.Triangles;
			image = paint.image;
			triangleOffset = this.vertexList.length;
			triangleCount = verts.length;
			uniformOffset = this.uniformList.length;
		}
		this.vertexList ~= verts;

		this.uniformList ~= this.createUniformBufferFromPaint(*paint, *scissor, 1.0f, 1.0f, -1.0f);
		this.uniformList.back.type = ShaderType.TexturedTris;
		
		this.callList ~= call;
	}
	
	private auto createUniformBufferFromPaint(NVGpaint paint, NVGscissor scissor, float width, float fringe, float strokeThr)
	{
		FragUniformBuffer ub;
		float[6] invxform;
		
		ub.innerColor = paint.innerColor.premultiplied.asFloat4;
		ub.outerColor = paint.outerColor.premultiplied.asFloat4;
		
		if(scissor.extent[0] < -0.5f || scissor.extent[1] < -0.5f)
		{
			ub.scissorMatr[] = 0.0;
			ub.scissorExt = [1.0f, 1.0f];
			ub.scissorScale = [1.0f, 1.0f];
		}
		else
		{
			nvgTransformInverse(invxform.ptr, scissor.xform.ptr);
			ub.scissorMatr = invxform.asMatrix3x4;
			ub.scissorExt = scissor.extent;
			ub.scissorScale[0] = sqrt(scissor.xform[0] ^^ 2.0f + scissor.xform[2] ^^ 2.0f);
			ub.scissorScale[1] = sqrt(scissor.xform[1] ^^ 2.0f + scissor.xform[3] ^^ 2.0f);
		}
		
		ub.extent = paint.extent;
		ub.strokeMult = (width * 0.5f + fringe * 0.5f) / fringe;
		ub.strokeThr = strokeThr;
		
		if(paint.image != 0)
		{
			auto texture = this.findTexture(paint.image);
			if(texture is null) throw new Exception("Texture not found");
			if(texture.flags.raised!NVG_IMAGE_FLIPY)
			{
				float[6] flipped;
				nvgTransformScale(flipped.ptr, 1.0f, -1.0f);
				nvgTransformMultiply(flipped.ptr, paint.xform.ptr);
				nvgTransformInverse(invxform.ptr, flipped.ptr);
			}
			else nvgTransformInverse(invxform.ptr, paint.xform.ptr);
			ub.type = ShaderType.Textured;
			
			if(texture.type == ImageType.RGBA)
			{
				if(texture.flags.raised!NVG_IMAGE_PREMULTIPLIED)
				{
					ub.texType = TexturePostProcess.None;
				}
				else ub.texType = TexturePostProcess.Multiply;
			}
			else ub.texType = TexturePostProcess.Colorize;
		}
		else
		{
			ub.type = ShaderType.Gradient;
			ub.radius = paint.radius;
			ub.feather = paint.feather;
			nvgTransformInverse(invxform.ptr, paint.xform.ptr);
		}
		ub.paintMatr = invxform.asMatrix3x4;
		return ub;
	}
	private void setUniformAndTexture(size_t uniformIndex, int image_id)
	{
		info(false, "Setting UniformOffset: ", uniformIndex * this.ubHardwareSize, "(", uniformIndex, ")");
		info("UniformBuffer TextureType: ", this.uniformList[uniformIndex].texType);
		info("UniformBuffer RenderType: ", this.uniformList[uniformIndex].type);
		GLUniformBuffer.BindRange[this.fragUniformObject.id, FUBUserIndex] = ByteRange(uniformIndex * this.ubHardwareSize, FragUniformBuffer.sizeof);
		if(image_id == 0) GLContext.Texture2D = NullTexture;
		else
		{
			const auto texture = this.findTexture(image_id);
			GLContext.Texture2D = texture is null ? NullTexture : texture.texture;
			info("Texture: ", texture.texture);
		}
	}

	@property viewport(Size sz)
	{
		this.vport = sz;
	}
}
auto asContext(void* p) { return cast(Context)p; }

extern(C)
{
	// Initialize/Terminate
	int initContext(void* uptr)
	{
		uptr.asContext.init();
		return 1;
	}
	void deleteContext(void* uptr)
	{
		uptr.asContext.terminate();
		GC.removeRoot(uptr);
	}
	// Textures
	int createTexture(void* uptr, int type, int w, int h, int imageFlags, const(byte)* data)
	{
		return uptr.asContext.createTexture(type, w, h, imageFlags, data);
	}
	int deleteTexture(void* uptr, int image)
	{
		uptr.asContext.deleteTexture(image);
		return 1;
	}
	int updateTexture(void* uptr, int image, int x, int y, int w, int h, const(byte)* data)
	{
		return uptr.asContext.findTexture(image).update(x, y, w, h, data);
	}
	int getTextureSize(void* uptr, int image, int* w, int* h)
	{
		return uptr.asContext.findTexture(image).getTextureSize(w, h);
	}
	// Viewport
	void setViewport(void* uptr, int w, int h)
	{
		uptr.asContext.viewport = Size(w, h);
	}
	// Render Control
	void cancel(void* uptr) { uptr.asContext.cancelRender(); }
	void flush(void* uptr) { uptr.asContext.flush(); }
	// Internal Commands
	void pushFillCommand(void* uptr, NVGpaint* paint, NVGscissor* scissor, float fringe, const(float)* bounds, const(NVGpath)* pPaths, int nPaths)
	{
		uptr.asContext.pushCommand!(CommandType.Fill)(paint, scissor, fringe, pPaths[0 .. nPaths], bounds[0 .. 4]);
	}
	void pushStrokeCommand(void* uptr, NVGpaint* paint, NVGscissor* scissor, float fringe, float strokeWidth, const(NVGpath)* pPaths, int nPaths)
	{
		uptr.asContext.pushCommand!(CommandType.Stroke)(paint, scissor, fringe, pPaths[0 .. nPaths], strokeWidth);
	}
	void pushTrianglesCommand(void* uptr, NVGpaint* paint, NVGscissor* scissor, const(NVGvertex)* verts, int nVerts)
	{
		uptr.asContext.pushTrianglesCommand(paint, scissor, verts[0 .. nVerts]);
	}
}

// NanoVG Export
NVGcontext* nvgCreateGL3()
{
	auto pContext = new Context();

	GC.addRoot(cast(void*)pContext);
	GC.setAttr(cast(void*)pContext, GC.BlkAttr.NO_MOVE);

	NVGparams params;
	with(params)
	{
		userPtr = cast(void*)pContext;
		edgeAntiAlias = 1;
		renderCreate			= &initContext;
		renderCreateTexture		= &createTexture;
		renderDeleteTexture		= &deleteTexture;
		renderUpdateTexture		= &updateTexture;
		renderGetTextureSize	= &getTextureSize;
		renderViewport			= &setViewport;
		renderCancel			= &cancel;
		renderFlush				= &flush;
		renderFill				= &pushFillCommand;
		renderStroke			= &pushStrokeCommand;
		renderTriangles			= &pushTrianglesCommand;
		renderDelete			= &deleteContext;
	}

	return nvgCreateInternal(&params);
}
alias nvgDeleteGL3 = nvgDeleteInternal;
