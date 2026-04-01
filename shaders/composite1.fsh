#version 330

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D depthtex0;

in vec4 color;
in vec2 texcoord;

/* RENDERTARGETS: 0,2,4,6 */
layout(location = 0) out vec4 outColor;
layout(location = 1) out vec4 outLight;
layout(location = 2) out vec4 outDirect;
layout(location = 3) out vec4 outDebug;

/*
const int colortex0Format = RGB32F;
const int colortex2Format = RGB32F;
const int colortex5Format = RGBA32F;
*/


#include "lib/common.glsl"
#include "lib/IGN.glsl"

#include "lib/SSGI.glsl"

uniform float viewWidth;
uniform float viewHeight;
uniform int frameCounter;

uniform float ambient;
uniform vec3 skyColor;

float GGX_NDF(float NdotH, float roughness) {
    float a  = roughness * roughness;
    float a2 = a * a;
    float d  = (NdotH * NdotH) * (a2 - 1.0) + 1.0;
    return a2 / max(PI * d * d, 1e-6);
}

void main() {
  vec3 col     = texture(colortex0, texcoord).rgb;
  vec3 pos     = reconstructViewPos(texcoord, texture(depthtex0, texcoord).r);
  if (texture(depthtex0, texcoord).r >= 1) {
    outColor.rgb = skyFunction(normalize(gbufferModelViewInverse*vec4(pos,1)).xyz);
    outLight = outColor;
    return;
  }
  
  float u = IGN(gl_FragCoord.xy, frameCounter);
  float v = IGN(gl_FragCoord.xy, frameCounter * 2 + 1);

  const vec2 R2 = vec2(0.75487766, 0.56984029);
  vec2 noise = fract(vec2(u, v) + R2 * float(frameCounter));

  vec3 hitNorm = normalize(texture(colortex1, texcoord).xyz);
  vec3 rn      = sampleCosineHemisphere(hitNorm, noise.x, noise.y);

  vec2 hitUV;
  vec3 hitPos;

  vec3 light = texture(colortex3, texcoord).rgb;
  float NdotL = max(dot(hitNorm, rn), 0.0);

  float roughness = pow(1.0 - texture(colortex4, texcoord).r, 2.0);
  roughness += pow(1.0 - texture(colortex4, texcoord).b, 2.0);
  roughness = min(1,roughness);
  
  vec3  H_gi    = normalize(normalize(pos) + rn);
  float NdotH_gi = max(dot(hitNorm, H_gi), 0.0);
  float ndfWeight = GGX_NDF(NdotH_gi, roughness) / max(4.0 * NdotL + 1e-4, 1e-4);
  float giWeight = mix(1.0, ndfWeight, 1.0 - roughness);
  
  if (raymarchSSGI(pos, rn, hitUV, hitPos)) {
    vec3 hitLight  = texture(colortex3, hitUV).rgb*2;
    //hitLight  -= texture(colortex5, hitUV).rgb;
    vec3 hitAlbedo = texture(colortex0, hitUV).rgb;
    vec2 edgeFade  = smoothstep(0.0, 0.08, hitUV) * smoothstep(1.0, 0.92, hitUV);
    
    vec3 gi        = hitAlbedo * hitLight;
    vec3  lightDir = normalize(hitPos - pos);
    float dist     = length(hitPos - pos);
    float falloff  = 1.0 / (dist * dist + 1.0);
    float fade     = edgeFade.x * edgeFade.y;
    
    light += NdotL * gi * falloff * fade * giWeight;
  }

  rn = reflect(normalize(pos), hitNorm);
  vec3  H_refl    = normalize(normalize(pos) + rn);
  float reflectance = pow(texture(colortex4, texcoord).g,2);
  float NdotH_refl = max(dot(hitNorm, H_refl), 0.0);
  float reflNDF   = clamp(GGX_NDF(NdotH_refl, roughness) * roughness * roughness, 0.0, 1.0);
  
  if (raymarchSSGI(pos, rn, hitUV, hitPos)) {
    vec3 hitAlbedo = texture(colortex5, hitUV).rgb;
    outDirect.rgb += hitAlbedo*reflectance*reflNDF;
  } else  {
    // outDirect.rgb += skyFunction((gbufferModelViewInverse*vec4(rn,1)).xyz)*reflectance*reflNDF;
  }
  outColor = vec4(col, 1.0);
  outLight = vec4(light, 1.0);
}
