#version 330 compatibility

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform vec3 chunkOffset;

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out vec3 normal;

void main() {
  gl_Position = gl_ProjectionMatrix * gl_ModelViewMatrix *  vec4(gl_Vertex.xyz, 1);
  texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
  lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
  glcolor = gl_Color;
  normal = gl_NormalMatrix * gl_Normal;
}
