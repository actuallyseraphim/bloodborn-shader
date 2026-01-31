#version 330 compatibility

out vec4 color;
out vec2 texcoord;

void main() {
    gl_Position = ftransform();

    color = gl_Color;
    texcoord = (gl_MultiTexCoord0).xy;
}
