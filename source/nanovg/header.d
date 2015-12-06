module nanovg.h;

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

// nanovg.h
// NanoVG core exports(Canvas/CustomRenderer APIs)

struct NVGcontext{}

struct NVGcolor
{
    float r, g, b, a;
}
struct NVGpaint
{
    float[6] xform;
    float[2] extent;
    float radius;
    float feather;
    NVGcolor innerColor;
    NVGcolor outerColor;
    int image;
}
alias NVGwinding = int;
enum : NVGwinding
{
    NVG_CCW = 1,
    NVG_CW = 2
}
alias NVGsolidity = int;
enum : NVGsolidity
{
    NVG_SOLID = 1,
    NVG_HOLE = 2
}
alias NVGlineCap = int;
enum : NVGlineCap
{
    NVG_BUTT,
    NVG_ROUND,
    NVG_SQUARE,
    NVG_BEVEL,
    NVG_MITER
}
alias NVGalign = int;
enum : NVGalign
{
    // Horizontal align
    NVG_ALIGN_LEFT = 1 << 0,
    NVG_ALIGN_CENTER = 1 << 1,
    NVG_ALIGN_RIGHT = 1 << 2,
    // Vertical align
    NVG_ALIGN_TOP = 1 << 3,
    NVG_ALIGN_MIDDLE = 1 << 4,
    NVG_ALIGN_BOTTOM = 1 << 5,
    NVG_ALIGN_BASELINE = 1 << 6
}

struct NVGglyphPosition
{
    const(char)* str;
    float x;
    float minx, maxx;
}
struct NVGtextRow
{
    const(char)* start;
    const(char)* end;
    const(char)* next;
    float width;
    float minx, maxx;
}

alias NVGimageFlags = int;
enum : NVGimageFlags
{
    NVG_IMAGE_GENERATE_MIPMAPS = 1 << 0,
    NVG_IMAGE_REPEATX = 1 << 1,
    NVG_IMAGE_REPEATY = 1 << 2,
    NVG_IMAGE_FLIPY = 1 << 3,
    NVG_IMAGE_PREMULTIPLIED = 1 << 4
}

extern(C)
{
void nvgBeginFrame(NVGcontext* pContext, int windowWidth, int windowHeight, float devicePixelRatio);
void nvgCancelFrame(NVGcontext* pContext);
void nvgEndFrame(NVGcontext* pContext);

NVGcolor nvgRGB(byte r, byte g, byte b);
NVGcolor nvgRGBf(float r, float g, float b);
NVGcolor nvgRGBA(byte r, byte g, byte b, byte a);
NVGcolor nvgRGBAf(float r, float g, float b, float a);
NVGcolor nvgLerpRGBA(NVGcolor c0, NVGcolor c1, float u);
NVGcolor nvgTransRGBA(NVGcolor c0, byte a);
NVGcolor nvgTransRGBAf(NVGcolor c0, float a);
NVGcolor nvgHSL(float h, float s, float l);
NVGcolor nvgHSLA(float h, float s, float l, byte a);

void nvgSave(NVGcontext* pContext);
void nvgRestore(NVGcontext* pContext);
void nvgReset(NVGcontext* pContext);

void nvgStrokeColor(NVGcontext* pContext, NVGcolor color);
void nvgStrokePaint(NVGcontext* pContext, NVGpaint paint);
void nvgFillColor(NVGcontext* pContext, NVGcolor color);
void nvgFillPaint(NVGcontext* pContext, NVGpaint paint);
void nvgMiterLimit(NVGcontext* pContext, float limit);
void nvgStrokeWidth(NVGcontext* pContext, float size);
void nvgLineCap(NVGcontext* pContext, int cap);
void nvgLineJoin(NVGcontext* pContext, int join);
void nvgGlobalAlpha(NVGcontext* pContext, float alpha);

void nvgResetTransform(NVGcontext* pContext);
void nvgTransform(NVGcontext* pContext, float a, float b, float c, float d, float e, float f);
void nvgTranslate(NVGcontext* pContext, float x, float y);
void nvgRotate(NVGcontext* pContext, float angle);
void nvgSkewX(NVGcontext* pContext, float angle);
void nvgSkewY(NVGcontext* pContext, float angle);
void nvgScale(NVGcontext* pContext, float x, float y);
void nvgCurrentTransform(NVGcontext* pContext, float* xform);

void nvgTransformIdentity(float* dst);
void nvgTransformTranslate(float* dst, float tx, float ty);
void nvgTransformScale(float* dst, float sx, float sy);
void nvgTransformRotate(float* dst, float a);
void nvgTransformSkewX(float* dst, float a);
void nvgTransformSkewY(float* dst, float a);
void nvgTransformMultiply(float* dst, const(float)* src);
void nvgTransformPremultiply(float* dst, const(float)* src);
int  nvgTransformInverse(float* dst, const(float)* src);
void nvgTransformPoint(float* dstx, float* dsty, const(float)* xform, float srcx, float srcy);
float nvgDegToRad(float deg);
float nvgRadToDeg(float rad);

int nvgCreateImage(NVGcontext* pContext, const(char)* filename, int imageFlags);
int nvgCreateImageMem(NVGcontext* pContext, int imageFlags, byte* data, int ndata);
int nvgCreateImageRGBA(NVGcontext* pContext, int w, int h, int imageFlags, const(byte)* data);
int nvgUpdateImage(NVGcontext* pContext, int image, const(byte)* data);
int nvgImageSize(NVGcontext* pContext, int image, int* w, int* h);
int nvgDeleteImage(NVGcontext* pContext, int image);

NVGpaint nvgLinearGradient(NVGcontext* pContext, float sx, float sy, float ex, float ey, NVGcolor icol, NVGcolor ocol);
NVGpaint nvgBoxGradient(NVGcontext* pContext, float x, float y, float w, float h, float r, float f, NVGcolor icol, NVGcolor ocol);
NVGpaint nvgRadialGradient(NVGcontext* pContext, float cx, float cy, float inr, float outr, NVGcolor icol, NVGcolor ocol);
NVGpaint nvgImagePattern(NVGcontext* pContext, float ox, float oy, float ex, float ey, float angle, int image, float alpha);

void nvgScissor(NVGcontext* pContext, float x, float y, float w, float h);
void nvgIntersectScissor(NVGcontext* pContext, float x, float y, float w, float h);
void nvgResetScissor(NVGcontext* pContext);

void nvgBeginPath(NVGcontext* pContext);
void nvgMoveTo(NVGcontext* pContext, float x, float y);
void nvgLineTo(NVGcontext* pContext, float x, float y);
void nvgBezierTo(NVGcontext* pContext, float c1x, float c1y, float c2x, float c2y, float x, float y);
void nvgQuadTo(NVGcontext* pContext, float cx, float cy, float x, float y);
void nvgArcTo(NVGcontext* pContext, float x1, float y1, float x2, float y2, float radius);
void nvgClosePath(NVGcontext* pContext);
void nvgPathWinding(NVGcontext* pContext, NVGwinding dir);
void nvgArc(NVGcontext* pContext, float cx, float cy, float r, float a0, float a1, NVGwinding dir);
void nvgRect(NVGcontext* pContext, float x, float y, float w, float h);
void nvgRoundedRect(NVGcontext* pContext, float x, float y, float w, float h, float r);
void nvgEllipse(NVGcontext* pContext, float cx, float cy, float rx, float ry);
void nvgCircle(NVGcontext* pContext, float cx, float cy, float r);
void nvgFill(NVGcontext* pContext);
void nvgStroke(NVGcontext* pContext);

int nvgCreateFont(NVGcontext* pContext, const(char)* name, const(char)* filename);
int nvgCreateFontMem(NVGcontext* pContext, const(char)* name, byte* data, int ndata, int freeData);
int nvgFindFont(NVGcontext* pContext, const(char)* name);
int nvgFontSize(NVGcontext* pContext, float size);
int nvgFontBlur(NVGcontext* pContext, float blur);
int nvgTextLetterSpacing(NVGcontext* pContext, float spacing);
int nvgTextLineHeight(NVGcontext* pContext, float lineHeight);
int nvgTextAlign(NVGcontext* pContext, NVGalign _align);
int nvgFontFaceId(NVGcontext* pContext, int font);
int nvgFontFace(NVGcontext* pContext, const(char)* font);
float nvgText(NVGcontext* pContext, float x, float y, const(char)* _string, const(char)* end);
void nvgTextBox(NVGcontext* pContext, float x, float y, float breakRowWidth, const(char)* _string, const(char)* end);
float nvgTextBounds(NVGcontext* pContext, float x, float y, const(char)* _string, const(char)* end, float* bounds);
void nvgTextBoxBounds(NVGcontext* pContext, float x, float y, float breakRowWidth, const(char)* _string, const(char)* end, float* bounds);
int nvgTextGlyphPositions(NVGcontext* pContext, float x, float y, const(char)* _string, const(char)* end, NVGglyphPosition* positions, int maxPositions);
void nvgTextMetrics(NVGcontext* pContext, float* ascender, float* descender, float* lineh);
int nvgTextBreakLines(NVGcontext* pContext, const(char)* _string, const(char)* end, float breakRowWidth, NVGtextRow* rows, int maxRows);
}

// InternalRenderAPIs
alias NVGtexture = uint;
enum : NVGtexture
{
    NVG_TEXTURE_ALPHA = 0x01,
    NVG_TEXTURE_RGBA = 0x02
}

struct NVGscissor
{
    float[6] xform;
    float[2] extent;
}
struct NVGvertex
{
    float x, y, u, v;
}
struct NVGpath
{
    int first;
    int count;
    byte closed;
    int nbevel;
    NVGvertex* fill;
    int nfill;
    NVGvertex* stroke;
    int nstroke;
    int winding;
    int convex;
}
struct NVGparams
{
    void* userPtr;
    int edgeAntiAlias;
    extern(C) int function(void* uptr) renderCreate;
    extern(C) int function(void* uptr, int type, int w, int h, int imageFlags, const(byte)* data) renderCreateTexture;
    extern(C) int function(void* uptr, int image) renderDeleteTexture;
    extern(C) int function(void* uptr, int image, int x, int y, int w, int h, const(byte)* data) renderUpdateTexture;
    extern(C) int function(void* uptr, int image, int* w, int* h) renderGetTextureSize;
    extern(C) void function(void* uptr, int width, int height) renderViewport;
    extern(C) void function(void* uptr) renderCancel;
    extern(C) void function(void* uptr) renderFlush;
    extern(C) void function(void* uptr, NVGpaint* paint, NVGscissor* scissor, float fringe, const(float)* bounds, const(NVGpath)* paths, int npaths) renderFill;
    extern(C) void function(void* uptr, NVGpaint* paint, NVGscissor* scissor, float fringe, float strokeWidth, const(NVGpath)* paths, int npaths) renderStroke;
    extern(C) void function(void* uptr, NVGpaint* paint, NVGscissor* scissor, const(NVGvertex)* verts, int nverts) renderTriangles;
    extern(C) void function(void* uptr) renderDelete;
}

// InternalContextConstructor/Destructor
extern(C)
{
    NVGcontext* nvgCreateInternal(NVGparams* params);
    void nvgDeleteInternal(NVGcontext* pContext);
    NVGparams* nvgInternalParams(NVGcontext* pContext);

    // Debug function
    void nvgDebugDumpPathCache(NVGcontext* pContext);
}
