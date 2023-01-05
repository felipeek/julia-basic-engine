#version 330 core

layout (location = 0) in vec3 vertex_position;
layout (location = 1) in vec3 vertex_normal;
layout (location = 2) in vec2 texture_coords;
layout (location = 3) in vec3 vertex_bary_coords;
layout (location = 4) in vec4 vertex_selection_color;
layout (location = 5) in vec4 vertex_unique_tri_color;

uniform mat4 model_matrix;
uniform mat4 view_matrix;
uniform mat4 projection_matrix;

void main()
{
	gl_Position = projection_matrix * view_matrix * model_matrix * vec4(vertex_position, 1.0);
}