#version 330

uniform sampler2D gtexture;
uniform sampler2D specular;
uniform sampler2D lightmap;
uniform sampler2D depthtex0;

uniform vec4 entityColor;
uniform float blindness;
uniform int isEyeInWater;
uniform float alphaTestRef;

in vec4 glcolor;
in vec2 texcoord;
in vec2 lmcoord;
in vec3 normal;

/* RENDERTARGETS: 0,1,2,3 */
layout(location = 0) out vec4 outColor;
layout(location = 1) out vec3 outNormal;
layout(location = 2) out vec3 outLight;
layout(location = 3) out vec4 outEmision;

const float ambientOcclusionLevel = 0.0;

void main() {
  vec3 light = vec3(min(1, lmcoord.x + lmcoord.y));
  vec4 col = glcolor * texture(gtexture, texcoord);
  if (col.a < alphaTestRef) {
    discard;
  }
  outColor = col;
  outNormal = normal*0.5+0.5;
  
  outLight = light;
  vec4 spec = texture(specular, texcoord);
  if (spec.a >= 1) {
    spec.a = 0;
  }
  outEmision = col * spec.a;
}
