#version 330 core

in vec4 fragment_selection_color;

out vec4 final_color;

void main()
{
	final_color = fragment_selection_color;
	//final_color = vec4(1.0, 0.0, 0.0, 1.0);
}