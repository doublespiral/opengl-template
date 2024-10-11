#version 330 core


/* globals */
// constants
uniform vec2 screen_resolution = vec2(1920, 1080);

// input
uniform float time;

/* etc */
layout (location = 0) out vec4 output_color;

in vec4 gl_FragCoord;

void main()
{
    // normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy * 3) / screen_resolution.xy;

    // time varying pixel color
    vec3 color = 0.5 + 0.5*cos(time + uv.yyx + vec3(4, 2, 0));

    // output
    output_color = vec4(color.r, color.g, color.b, 1.0);
}