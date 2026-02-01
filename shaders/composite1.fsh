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

uniform mat4 gbufferProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;

#include "lib/common.glsl"
#include "lib/IGN.glsl"

#include "lib/SSGI.glsl"

uniform float viewWidth;
uniform float viewHeight;
uniform int frameCounter;

uniform float ambient;

void main() {
  vec3 col = texture(colortex0, texcoord).xyz;
  vec2 ignNoise = vec2(IGN(gl_FragCoord.xy, frameCounter),
                       IGN(gl_FragCoord.yx, frameCounter));
  vec3 hitNorm = texture(colortex1, texcoord).xyz*2-1;

  vec3 rn = sampleCosineHemisphere(hitNorm, ignNoise.x, fract(17*ignNoise.y));
  vec3 pos = reconstructViewPos(texcoord, texture(depthtex0,texcoord).r);

  vec2 hitUV;
  vec3 hitPos;

  vec3 light = texture(colortex3, texcoord).rgb+ambient;
  
  if (raymarchSSGI(pos, rn, hitUV, hitPos)) {
    vec3 mclight = texture(colortex3, hitUV).rgb+0.02;
    vec3 gi = texture(colortex0, hitUV).rgb*mclight;
    vec3 lightDir = normalize(hitPos - pos);
    float falloff = pow(length(hitPos - pos), 2)/10+1;
    light += vec3(dot(hitNorm,lightDir))*gi/falloff;
  }
  
  outColor = vec4(col, 1.0);
  outLight = vec4(light, 1.0);
}
