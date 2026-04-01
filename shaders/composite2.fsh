#version 330

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D depthtex0;
uniform sampler2D depthtex2;

in vec4 color;
in vec2 texcoord;

/* RENDERTARGETS: 0,2,5,6 */
layout(location = 0) out vec4 outColor;
layout(location = 1) out vec4 outLight;
layout(location = 2) out vec4 outLightCum;
layout(location = 3) out vec4 outDebug;

const bool colortex5Clear = false;

uniform float viewWidth;
uniform float viewHeight;

#include "lib/common.glsl"

uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferPreviousProjection;

uniform vec3 previousCameraPosition;

void main() {
  vec2 d = 1/vec2(viewWidth,viewHeight);
  vec3 light = vec3(0);
  float dist0 = linearizeDepth(texture(depthtex0, texcoord).r);
  float factor = 0;

  vec3 col = texture(colortex0, texcoord).rgb;

  vec3 screenPos = vec3(texcoord, texture(depthtex2, texcoord).r);
  vec3 ndcPos = screenPos*2-1;
  vec3 viewPos = projectAndDivide(gbufferProjectionInverse, ndcPos);
  vec3 feetPos = (gbufferModelViewInverse*vec4(viewPos,1)).xyz;
  vec3 prevViewPos = (gbufferPreviousModelView*vec4(feetPos+cameraPosition-previousCameraPosition,1)).xyz;
  vec3 prevNdcPos = projectAndDivide(gbufferPreviousProjection, prevViewPos);
  vec3 prevScreenPos = prevNdcPos*0.5+0.5;

  float acc_power = 200;
  
  vec2 prev = prevScreenPos.xy;
  bool offscreen = any(lessThan(prev, vec2(0.0))) || any(greaterThan(prev, vec2(1.0)));
  bool toofar = abs(linearizeDepth(texture(colortex5, prev).a)-linearizeDepth(texture(depthtex0, texcoord).r)) > 0.5;
  if (!(offscreen||toofar)) {
    outLightCum.rgb = texture(colortex5, prev).rgb*acc_power;
    outLightCum.a = texture(colortex5, prev).a;
  } else {
    outLightCum.rgb = texture(colortex3, texcoord).rgb*acc_power;
    outLightCum.a = texture(depthtex0, texcoord).r;
  }
  if (texture(depthtex0, texcoord).r >= 1) {
    outLightCum.rgb = texture(colortex0, texcoord).rgb*acc_power;
    outLightCum.a = 1;
  }
  if (texture(depthtex0, texcoord).r <= 0.6) {
    outLightCum.rgb = texture(colortex3, texcoord).rgb*acc_power;
  }
  
  float acc = 0;
  for (int i = -2; i <= 2; i++) {
    for (int j = -2; j <= 2; j++) {
      vec2 u = vec2(i,j);
      float f = exp(-length(u)*length(u)/2);
      outLightCum.rgb += texture(colortex2,texcoord+u*d).rgb*f;
      acc += f;
    }
  }
  outLightCum.a += texture(depthtex0, texcoord).r;
  outLightCum.a /= 2;
  outLightCum.rgb /= acc_power + acc;
  outLight = vec4(light, 1.0);
  outColor = vec4(col*outLightCum.rgb+texture(colortex4,texcoord).rgb, 1.0);
  //outDebug = outLightCum;
}
