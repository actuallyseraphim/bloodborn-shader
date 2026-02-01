#version 330

uniform sampler2D colortex0;
uniform float vignette;

in vec2 texcoord;
out vec4 outColor;

void main() {
  float v = 1-length(texcoord*2-1)*vignette;
  outColor = texture(colortex0, texcoord) * v;
}
