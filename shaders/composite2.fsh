#version 330

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D depthtex0;

in vec4 color;
in vec2 texcoord;

/* RENDERTARGETS: 0,2 */
layout(location = 0) out vec4 outColor;
layout(location = 1) out vec4 outLight;

uniform float viewWidth;
uniform float viewHeight;

#include "lib/common.glsl"

void main() {
  vec2 d = 1/vec2(viewWidth,viewHeight);
  vec3 light = vec3(0);
  float dist0 = linearizeDepth(texture(depthtex0, texcoord).r);
  float factor = 0;

  vec3 col = texture(colortex0, texcoord).rgb;
  
  outLight = vec4(light, 1.0);
  outColor = vec4(col*texture(colortex2, texcoord).xyz, 1.0);
}
