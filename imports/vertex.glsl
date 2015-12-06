#version 130

uniform vec2 viewSize;
in vec2 vertex;
in vec2 texcoord;
out vec2 texcoord_out;
out vec2 pos;
void main(void)
{
	texcoord_out = texcoord;
	pos = vertex;
	vec2 scaledPos = (2.0f * vertex) / viewSize;
	gl_Position = vec4(scaledPos.x - 1.0f, 1.0f - scaledPos.y, 0.0f, 1.0f);
}