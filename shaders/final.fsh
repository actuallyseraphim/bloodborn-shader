#version 330

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D colortex6;
uniform sampler2D depthtex0;
uniform float vignette;

in vec2 texcoord;
out vec4 outColor;

vec3 ACESFilmic(vec3 x) {
    const float a = 2.51, b = 0.03, c = 2.43, d = 0.59, e = 0.14;
    return clamp((x * (a*x + b)) / (x * (c*x + d) + e), 0.0, 1.0);
}

vec3 applyExposure(vec3 col, float ev) {
    return col * pow(2.0, ev);
}

vec3 linearToSRGB(vec3 col) {
    return mix(
        12.92 * col,
        1.055 * pow(col, vec3(1.0/2.4)) - 0.055,
        step(0.0031308, col)
    );
}

#include "lib/common.glsl"

void main() {
  vec3 hdr = texture(colortex0, texcoord).rgb/2;
  
  // Exposure → tonemap → gamma
  vec3 exposed   = applyExposure(hdr, 3);
  vec3 tonemapped = ACESFilmic(exposed);
  vec3 srgb      = linearToSRGB(tonemapped);
  
  // Vignette applied after tonemap so it doesn't push blacks into the curve
  float v = 1.0 - length(texcoord * 2.0 - 1.0) * vignette;
  v = smoothstep(0.0, 1.0, v); // softer falloff than linear

  vec3 screenPos = vec3(texcoord, 1);
  vec3 ndcPos = screenPos*2-1;
  vec3 viewPos = projectAndDivide(gbufferProjectionInverse, ndcPos);
  vec3 feetPos = (gbufferModelViewInverse*vec4(viewPos,1)).xyz;
  
  outColor = vec4(srgb * v, 1.0);
  //outColor = vec4(texture(colortex6, texcoord).rgb, 1.0);  
  //outColor = vec4(texture(colortex3, texcoord).rgb, 1.0);  
  //outColor = vec4(skyFunction(normalize(feetPos)).rgb, 1.0);
}
