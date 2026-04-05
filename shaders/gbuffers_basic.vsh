#version 330 compatibility

in vec4 at_tangent;

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform vec3 chunkOffset;

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out vec3 normal;
out vec3 tangent;
out vec3 binormal;
out vec3 glposition;

void main() {
  gl_Position = gl_ProjectionMatrix * gl_ModelViewMatrix *  vec4(gl_Vertex.xyz, 1);
  texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
  lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
  glcolor = gl_Color;
  
  normal   = normalize(gl_NormalMatrix * gl_Normal);
  tangent  = normalize(gl_NormalMatrix * at_tangent.xyz);
  binormal = normalize(cross(normal, tangent) * at_tangent.w);
}
