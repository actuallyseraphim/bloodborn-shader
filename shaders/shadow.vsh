#version 330 compatibility

out vec2 texcoord;
out vec4 glcolor;

#include "lib/common.glsl"

void main() {
  gl_Position = gl_ProjectionMatrix * gl_ModelViewMatrix *  vec4(gl_Vertex.xyz, 1);
  gl_Position.xyz = distortShadowClipPos(gl_Position.xyz);
  texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
  glcolor = gl_Color;
}
