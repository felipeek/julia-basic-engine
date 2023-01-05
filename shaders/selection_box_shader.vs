#version 330 core

layout (location = 0) in int idx;

uniform vec2 p1;
uniform vec2 p2;

void main()
{
	/*
	float x1 = -0.5;
	float x2 = 0.5;
	if (idx == 0) {
		gl_Position = vec4(x2, x2, 0.0, 1.0);
	} else if (idx == 1) {
		gl_Position = vec4(x1, x2, 0.0, 1.0);
	} else if (idx == 2) {
		gl_Position = vec4(x1, x1, 0.0, 1.0);
	} else {
		gl_Position = vec4(x2, x1, 0.0, 1.0);
	}
	*/

	if (idx == 0) {
		gl_Position = vec4(p1.x, p1.y, 0.0, 1.0);
	} else if (idx == 1) {
		gl_Position = vec4(p1.x, p2.y, 0.0, 1.0);
	} else if (idx == 2) {
		gl_Position = vec4(p2.x, p2.y, 0.0, 1.0);
	} else {
		gl_Position = vec4(p2.x, p1.y, 0.0, 1.0);
	}
}