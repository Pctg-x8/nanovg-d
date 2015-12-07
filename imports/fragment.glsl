#version 150 core

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

layout(std140) uniform frag
{
	mat3 scissorMatr, paintMatr;
	vec4 innerColor, outerColor;
	vec2 scissorExt, scissorScale;
	vec2 extent;
	float radius, feather;
	float strokeMult, strokeThr;
	int texType, type;
};
uniform sampler2D texImage;
in vec2 texcoord_out;
in vec2 pos;
out vec4 outColor;

// Helper Functions
float sdRoundRect(vec2 pt, vec2 ext, float rad)
{
	// Distance field of Rounded Rect
	vec2 ext2 = ext - vec2(rad);
	vec2 d = abs(pt) - ext2;
	return min(max(d.x, d.y), 0.0f) + length(max(d, 0.0f)) - rad;
}
float scissorMask(vec2 p)
{
	vec2 scTransformed = (scissorMatr * vec3(p, 1.0f)).xy;
	vec2 sc = vec2(0.5f) - (abs(scTransformed) - scissorExt) * scissorScale;
	vec2 sc_norm = clamp(sc, vec2(0.0f), vec2(1.0f));
	return sc_norm.x * sc_norm.y;
}
float strokeMask()
{
	vec2 strokeMaskTemp = vec2((1.0f - abs(texcoord_out.x * 2.0f - 1.0f)) * strokeMult, texcoord_out.y);
	vec2 strokeMaskClamped = min(vec2(1.0f), strokeMaskTemp);
	return strokeMaskClamped.x * strokeMaskClamped.y;
}
vec4 colorize(vec4 source)
{
	if(texType == 1) return vec4(source.xyz * source.w, source.w);
	else if(texType == 2) return vec4(source.x);
	else return source;
}

vec4 gradient(float strokeAlpha, float scissor)
{
	vec2 pt = (paintMatr * vec3(pos, 1.0f)).xy;
	float sdr = sdRoundRect(pt, extent, radius) / feather + 0.5f;
	float d = clamp(sdr, 0.0f, 1.0f);
	return mix(innerColor, outerColor, d) * strokeAlpha * scissor;
}
vec4 textureBlend(float strokeAlpha, float scissor)
{
	vec2 pt = (paintMatr * vec3(pos, 1.0f)).xy;
	vec4 texel = colorize(texture(texImage, pt));
	return texel * innerColor * strokeAlpha * scissor;
}
vec4 texturedTris(float scissor)
{
	vec4 texel = colorize(texture(texImage, texcoord_out));
	return /*texel * vec4(0.0f, 0.0f, 0.0f, 1.0f)*/vec4(texcoord_out, 0.0f, 1.0f) * scissor;
}

void main(void)
{
	float strokeAlpha = strokeMask();
	if(strokeAlpha < strokeThr) discard;
	
	float scissor = scissorMask(pos);
	if(type == 0) outColor = gradient(strokeAlpha, scissor);
	else if(type == 1) outColor = textureBlend(strokeAlpha, scissor);
	else if(type == 2) outColor = vec4(1.0f);
	else if(type == 3) outColor = texturedTris(scissor);
}