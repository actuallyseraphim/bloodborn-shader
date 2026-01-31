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

void main() {
  vec2 d = 1/vec2(viewWidth,viewHeight);
  vec3 light = vec3(0);
  vec3 normal = texture(colortex1, texcoord).xyz*2-1;
  float factor = 0;
  for (int i = 0; i < 10; i++) {
    for (int j = 0; j < 10; j++) {
      vec2 th = vec2(cos(float(i)/10+j), sin(float(i)/10+j));
      float r = j;
      vec3 n = texture(colortex1, texcoord+r*th*d).xyz*2-1;
      float f = dot(normal, n);
      factor += f;
      light += texture(colortex2, texcoord+r*th*d).xyz*f;
    }
  }
  light /= factor;

  vec3 col = texture(colortex0, texcoord).rgb;
  
  outLight = vec4(light, 1.0);
  outColor = vec4(light*col, 1.0);
}
