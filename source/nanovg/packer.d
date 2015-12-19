module nanovg.packer;

// Packed Classes
import nanovg.h;
import std.typecons, std.string;

enum LineCap : NVGlineCap
{
	BUTT = NVG_BUTT, ROUND = NVG_ROUND,
	SQUARE = NVG_SQUARE, BEVEL = NVG_BEVEL,
	MITER = NVG_MITER
}
enum TextAlign : NVGalign
{
	LEFT = NVG_ALIGN_LEFT, CENTER = NVG_ALIGN_CENTER, RIGHT = NVG_ALIGN_RIGHT,
	TOP = NVG_ALIGN_TOP, MIDDLE = NVG_ALIGN_MIDDLE, BOTTOM = NVG_ALIGN_BOTTOM,
	BASELINE = NVG_ALIGN_BASELINE
}
enum ImageFlags : NVGimageFlags
{
	GENERATE_MIPMAPS = NVG_IMAGE_GENERATE_MIPMAPS,
	REPEATX = NVG_IMAGE_REPEATX, REPEATY = NVG_IMAGE_REPEATY,
	FLIPY = NVG_IMAGE_FLIPY, PREMULTIPLIED = NVG_IMAGE_PREMULTIPLIED
}
enum Winding : NVGwinding
{
	CCW = NVG_CCW,
	CW = NVG_CW
}
struct Matrix3x2
{
	float[6] elements;
	static auto FromXF(float[6] xf)
	{
		return Matrix3x2(xf);
	}
	
	// Matrix Maths //
	static @property Identity()
	{
		float[6] xform;
		nvgTransformIdentity(xform.ptr);
		return FromXF(xform);
	}
	auto translate(float tx, float ty) { nvgTransformTranslate(this.elements.ptr, tx, ty); return this; }
	auto scale(float sx, float sy) { nvgTransformScale(this.elements.ptr, sx, sy); return this; }
	auto rotate(float a) { nvgTransformRotate(this.elements.ptr, a); return this; }
	auto skewX(float a) { nvgTransformSkewX(this.elements.ptr, a); return this; }
	auto skewY(float a) { nvgTransformSkewY(this.elements.ptr, a); return this; }
	auto opBinary(string op)(Matrix3x2 other) if(op == "*")
	{
		float[6] elm_t; elm_t[] = this.elements[];
		nvgTransformMultiply(elm_t.ptr, other.elements.ptr);
		return FromXF(elm_t);
	}
	auto opOpAssign(string op)(Matrix3x2 other) if(op == "*")
	{
		nvgTransformMultiply(this.elements.ptr, other.elements.ptr);
	}
	auto inverse()
	{
		float[6] dst;
		nvgTransformInverse(dst.ptr, this.elements.ptr);
		this.elements[] = dst[];
	}
	auto transformPoint(float px, float py)
	{
		float dx, dy;
		nvgTransformPoint(&dx, &dy, this.elements.ptr, px, py);
		return tuple(dx, dy);
	}
}
class Texture
{
	NVGcontext* relatedContext;
	int id;
	
	public this(NVGcontext* pc, int i)
	{
		this.relatedContext = pc;
		this.id = i;
	}
	public ~this()
	{
		this.relatedContext.nvgDeleteImage(this.id);
	}
	public bool update(const(byte[]) data)
	{
		return this.relatedContext.nvgUpdateImage(this.id, data.ptr) != 0;
	}
	public auto size()
	{
		int w, h;
		this.relatedContext.nvgImageSize(this.id, &w, &h);
		return tuple(w, h);
	}
}
alias Font = int;
alias GlyphPosition = NVGglyphPosition;
alias TextRow = NVGtextRow;
class Context(alias InitializerFun, alias DisposerFun)
{
	NVGcontext* pInternal;
	
	public this()
	{
		this.pInternal = InitializerFun();
	}
	public ~this()
	{
		DisposerFun(this.pInternal);
	}
	
	// StateController //
	public void save() { this.pInternal.nvgSave(); }
	public void restore() { this.pInternal.nvgRestore(); }
	public void reset() { this.pInternal.nvgReset(); }
	
	// RenderingManagement //
	public auto beginFrame(int w, int h, float aspect) { this.pInternal.nvgBeginFrame(w, h, aspect); }
	public auto endFrame() { this.pInternal.nvgEndFrame(); }
	
	// RenderSetters //
	public @property
	{
		void strokeColor(NVGcolor color) { this.pInternal.nvgStrokeColor(color); }
		void strokePaint(NVGpaint paint) { this.pInternal.nvgStrokePaint(paint); }
		void fillColor(NVGcolor color) { this.pInternal.nvgFillColor(color); }
		void fillPaint(NVGpaint paint) { this.pInternal.nvgFillPaint(paint); }
		void miterLimit(float limit) { this.pInternal.nvgMiterLimit(limit); }
		void strokeWidth(float width) { this.pInternal.nvgStrokeWidth(width); }
		void lineCap(LineCap cap) { this.pInternal.nvgLineCap(cap); }
		void lineJoin(int join) { this.pInternal.nvgLineJoin(join); }
		void globalAlpha(float alpha) { this.pInternal.nvgGlobalAlpha(alpha); }
	}
	
	// Transforms //
	public void resetTransform() { this.pInternal.nvgResetTransform(); }
	public @property void transform(Matrix3x2 matr)
	{
		this.pInternal.nvgTransform(matr.elements[0], matr.elements[1], matr.elements[2],
			matr.elements[3], matr.elements[4], matr.elements[5]);
	}
	public @property auto transform()
	{
		float[6] xform;
		this.pInternal.nvgCurrentTransform(xform.ptr);
		return Matrix3x2.FromXF(xform);
	}
	public auto translate(float x, float y) { this.pInternal.nvgTranslate(x, y); return this; }
	public auto rotate(float angle) { this.pInternal.nvgRotate(angle); return this; }
	public auto skewX(float angle) { this.pInternal.nvgSkewX(angle); return this; }
	public auto skewY(float angle) { this.pInternal.nvgSkewY(angle); return this; }
	public auto scale(float x, float y) { this.pInternal.nvgScale(x, y); return this; }
	
	// Images //
	public Texture createImage(string filePath, ImageFlags imageFlags)
	{
		return new Texture(this.pInternal, this.pInternal.nvgCreateImage(filePath.toStringz, imageFlags));
	}
	public Texture createImageMem(ImageFlags imageFlags, byte[] data)
	{
		return new Texture(this.pInternal, this.pInternal.nvgCreateImageMem(imageFlags, data.ptr, cast(int)data.length));
	}
	public Texture createImageRGBA(int w, int h, ImageFlags imageFlags, const(byte[]) data)
	{
		return new Texture(this.pInternal, this.pInternal.nvgCreateImageRGBA(w, h, imageFlags, data.ptr));
	}
	
	// PaintMaking //
	public auto createLinearGradientPaint(float sx, float sy, float ex, float ey, NVGcolor col1, NVGcolor col2)
	{
		return this.pInternal.nvgLinearGradient(sx, sy, ex, ey, col1, col2);
	}
	public auto createBoxGradientPaint(float x, float y, float w, float h, float r, float f, NVGcolor icol, NVGcolor ocol)
	{
		return this.pInternal.nvgBoxGradient(x, y, w, h, r, f, icol, ocol);
	}
	public auto createRadialGradientPaint(float cx, float cy, float ir, float or, NVGcolor icol, NVGcolor ocol)
	{
		return this.pInternal.nvgRadialGradient(cx, cy, ir, or, icol, ocol);
	}
	public auto createImagePattern(float ox, float oy, float ex, float ey, float angle, Texture image, float alpha)
	in { assert(image !is null); }
	body {
		return this.pInternal.nvgImagePattern(ox, oy, ex, ey, angle, image.id, alpha);
	}
	
	// Scissoring //
	public @property scissor(Tuple!(float, float, float, float) sr) { this.pInternal.nvgScissor(sr.expand); }
	public @property intersectScissor(Tuple!(float, float, float, float) sr) { this.pInternal.nvgIntersectScissor(sr.expand); }
	public void resetScissor() { this.pInternal.nvgResetScissor(); }
	
	// PathMaking/Drawing //
	public void beginPath() { this.pInternal.nvgBeginPath(); }
	public void moveTo(float x, float y) { this.pInternal.nvgMoveTo(x, y); }
	public void lineTo(float x, float y) { this.pInternal.nvgLineTo(x, y); }
	public void bezierTo(float c1x, float c1y, float c2x, float c2y, float x, float y) { this.pInternal.nvgBezierTo(c1x, c1y, c2x, c2y, x, y); }
	public void quadTo(float cx, float cy, float x, float y) { this.pInternal.nvgQuadTo(cx, cy, x, y); }
	public void arcTo(float x1, float y1, float x2, float y2, float rad) { this.pInternal.nvgArcTo(x1, y1, x2, y2, rad); }
	public void closePath() { this.pInternal.nvgClosePath(); }
	public @property pathWinding(Winding d) { this.pInternal.nvgPathWinding(d); }
	public void arc(float cx, float cy, float r, float a0, float a1, Winding d) { this.pInternal.nvgArc(cx, cy, r, a0, a1, d); }
	public void rect(float x, float y, float w, float h) { this.pInternal.nvgRect(x, y, w, h); }
	public void roundedRect(float x, float y, float w, float h, float r) { this.pInternal.nvgRoundedRect(x, y, w, h, r); }
	public void ellipse(float cx, float cy, float rx, float ry) { this.pInternal.nvgEllipse(cx, cy, rx, ry); }
	public void circle(float cx, float cy, float r) { this.pInternal.nvgCircle(cx, cy, r); }
	public void fill() { this.pInternal.nvgFill(); }
	public void stroke() { this.pInternal.nvgStroke(); }
	
	// Font/TextPositioning //
	public Font createFont(string name, string fileName) { return this.pInternal.nvgCreateFont(name.toStringz, fileName.toStringz); }
	public Font createFontMem(string name, byte[] data, int freeData)
	{
		return this.pInternal.nvgCreateFontMem(name.toStringz, data.ptr, cast(int)data.length, freeData);
	}
	public Font findFont(string name) { return this.pInternal.nvgFindFont(name.toStringz); }
	public @property fontSize(float size) { this.pInternal.nvgFontSize(size); }
	public @property fontBlur(float blur) { this.pInternal.nvgFontBlur(blur); }
	public @property fontFace(Font f) { this.pInternal.nvgFontFaceId(f); }
	public @property fontFace(string name) { this.pInternal.nvgFontFace(name.toStringz); }
	public @property textLetterSpacing(float spacing) { this.pInternal.nvgTextLetterSpacing(spacing); }
	public @property textLineHeight(float lineHeight) { this.pInternal.nvgTextLineHeight(lineHeight); }
	public @property textAlign(TextAlign a) { this.pInternal.nvgTextAlign(a); }
	
	// TextDrawing //
	public auto text(float x, float y, string str, string end = null)
	{
		return this.pInternal.nvgText(x, y, str.toStringz, end is null ? null : end.toStringz);
	}
	public void textBox(float x, float y, float breakRowWidth, string str, string end = null)
	{
		this.pInternal.nvgTextBox(x, y, breakRowWidth, str.toStringz, end is null ? null : end.toStringz);
	}
	public auto textBounds(float x, float y, string str, string end, float[4] bounds)
	{
		return this.pInternal.nvgTextBounds(x, y, str.toStringz, end is null ? null : end.toStringz, bounds.ptr);
	}
	public void textBoxBounds(float x, float y, float breakRowWidth, string str, string end, float[4] bounds)
	{
		this.pInternal.nvgTextBoxBounds(x, y, breakRowWidth, str.toStringz, end is null ? null : end.toStringz, bounds.ptr);
	}
	public auto textGlyphPositions(float x, float y, string str, string end, GlyphPosition[] positions)
	{
		return this.pInternal.nvgTextGlyphPositions(x, y, str.toStringz, end is null ? null : end.toStringz, positions.ptr, cast(int)positions.length);
	}
	public void textMetrics(out float ascender, out float descender, out float lineheight)
	{
		this.pInternal.nvgTextMetrics(&ascender, &descender, &lineheight);
	}
	public auto textBreakLines(string str, string end, float breakRowWidth, TextRow[] rows)
	{
		return this.pInternal.nvgTextBreakLines(str.toStringz, end is null ? null : end.toStringz, breakRowWidth, rows.ptr, cast(int)rows.length);
	}
}

version(UseGL3Renderer)
{
	import nanovg.gl3;
	alias ContextGL3 = Context!(nvgCreateGL3, nvgDeleteGL3);
}
