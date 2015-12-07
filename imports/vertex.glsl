#version 130

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

uniform vec2 viewSize;
in vec2 vertex;
in vec2 texcoord;
out vec2 texcoord_out;
out vec2 pos;
void main(void)
{
	texcoord_out = texcoord * 512.0f;
	pos = vertex;
	vec2 scaledPos = (2.0f * vertex) / viewSize;
	gl_Position = vec4(scaledPos.x - 1.0f, 1.0f - scaledPos.y, 0.0f, 1.0f);
}