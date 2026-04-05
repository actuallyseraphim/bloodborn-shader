#version 330

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D colortex6;
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
uniform int frameCounter;
uniform float acc_power;

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
  
  vec2 prev = prevScreenPos.xy;
  bool offscreen = any(lessThan(prev, vec2(0.0))) || any(greaterThan(prev, vec2(1.0)));
  bool toofar = abs(linearizeDepth(texture(colortex5, prev).a)-linearizeDepth(texture(depthtex0, texcoord).r)) > 0.5;
  bool isEntity = texture(colortex7, texcoord).r == MC_RENDER_STAGE_ENTITIES;
  bool toodim = length(texture(colortex4, texcoord).rgb) - length(texture(colortex5, prev)) > 0.1;
  if (texture(depthtex0, texcoord).r >= 1) {
    outLightCum.rgb = texture(colortex0, texcoord).rgb;
    outLightCum.a = 1;
  } else if (texture(depthtex0, texcoord).r <= 0.6) {
    outLightCum.rgb = texture(colortex3, texcoord).rgb;
  } else {
    if (offscreen||toofar||isEntity||toodim) {
      outLightCum.rgb = texture(colortex4, texcoord).rgb;
      outLightCum.a = texture(depthtex0, texcoord).r;
    } else {
      outLightCum.rgb = texture(colortex5, prev).rgb*acc_power;
      outLightCum.a = texture(colortex5, prev).a;
      float acc = 0;
      for (int i = 0; i <= 25; i++) {
        vec2 u = vogel(i,25,frameCounter)*4;
        float f = exp(-length(u)*length(u)/2);
        outLightCum.rgb += texture(colortex2,texcoord+u*d).rgb*f;
        acc += f;
      }
      outLightCum.rgb /= acc_power + acc;
      outLightCum.a += texture(depthtex0, texcoord).r;
      outLightCum.a /= 2;
    }
  }
  
  outLightCum.rgb = clamp(outLightCum.rgb,0,10);
  light = outLightCum.rgb;
  outLight = vec4(light, 1.0);
  outColor = vec4(col*light, 1.0);
  outDebug = vec4(texture(colortex6, texcoord).rgb,1.0);
  //outDebug = outLightCum;
}
