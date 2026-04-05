#version 330

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D depthtex0;
uniform sampler2D depthtex2;
uniform sampler2D shadowtex0;

uniform sampler2D noisetex;

in vec4 color;
in vec2 texcoord;

/* RENDERTARGETS: 0,2,4,6 */
layout(location = 0) out vec4 outColor;
layout(location = 1) out vec4 outLight;
layout(location = 2) out vec4 outFastLight;
layout(location = 3) out vec4 outDebug;

uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

#include "lib/common.glsl"
#include "lib/IGN.glsl"

uniform float raySpread;
#include "lib/SSGI.glsl"

uniform float viewWidth;
uniform float viewHeight;
uniform int   frameCounter;

uniform float directEmissionStength;
uniform float blockEmissionStength;
uniform float ambient;

uniform vec3 skyColor;
uniform vec3 shadowLightPosition;
uniform vec3 upPosition;

const vec3 warm = vec3(255, 198, 140)/255/10;

float GGX_NDF(float NdotH, float roughness) {
    float a  = roughness * roughness;
    float a2 = a * a;
    float d  = (NdotH * NdotH) * (a2 - 1.0) + 1.0;
    return a2 / max(PI * d * d, 1e-6);
}
float fresnelSchlick(float NdotV, float F0, float roughness) {
  float f = pow(1.0 - NdotV, 5.0);
  return F0 + (max(1.0 - roughness, F0) - F0) * f;
}

void main() {
  vec3 col     = texture(colortex0, texcoord).rgb;
  vec3 pos     = reconstructViewPos(texcoord, getDepth(depthtex0, texcoord));
  if (texture(depthtex0, texcoord).r >= 1) {
    outColor.rgb = skyFunction(normalize(gbufferModelViewInverse*vec4(pos,1)).xyz);
    outLight = outColor;
    return;
  }
  
  // gi
  float u = IGN(gl_FragCoord.xy, frameCounter);
  float v = IGN(gl_FragCoord.xy, frameCounter * 2 + 1);
  float ray_len = IGN(gl_FragCoord.xy, frameCounter * 3 + 1);

  vec3 hitNorm = normalize(texture(colortex1, texcoord).xyz);
  vec3 rn      = sampleCosineHemisphere(hitNorm, u, v);

  vec2 hitUV;
  vec3 hitPos;

  vec3 light = vec3(0);
  outFastLight = directEmissionStength*texture(colortex3, texcoord);
  outFastLight += ambient * texture(colortex2, texcoord).y*max(dot(sunPosition, upPosition)/10000, 0.1);
  float NdotL = max(dot(hitNorm, rn), 0.0);

  float roughness = pow(1.0 - texture(colortex4, texcoord).r, 2.0);
  roughness += pow(1.0 - texture(colortex4, texcoord).b, 2.0);
  roughness = min(1,roughness);
  
  vec3  H      = normalize(pos + rn);
  float NdotH  = max(dot(hitNorm, H), 0.0);
  float ndfWeight = GGX_NDF(NdotH, roughness) / max(4.0 * NdotL + 1e-4, 1e-4);
  ndfWeight  = mix(1.0, ndfWeight, 1.0 - roughness);
  
  float reflectance = max(texture(colortex4, texcoord).g,0.0);
  float fresnel     = fresnelSchlick(dot(hitNorm, -normalize(pos)), reflectance, roughness);

  rn = normalize(mix(rn,reflect(normalize(pos), hitNorm), reflectance*fresnel));
  NdotL = max(dot(hitNorm, rn), 0.0);
  if (raymarchSSGI(pos, rn, hitUV, hitPos, ray_len*0.15+0.05)) {
    vec3 hitLight  = texture(colortex3, hitUV).rgb*blockEmissionStength;
    // idk why that works, but it makes reflections better
    hitLight      *= (1-reflectance*(1-directEmissionStength/blockEmissionStength));
    hitLight      += texture(colortex5, hitUV).rgb;
    
    vec3 hitAlbedo = texture(colortex0, hitUV).rgb;
    vec2 edgeFade  = smoothstep(0.0, 0.08, hitUV) * smoothstep(1.0, 0.92, hitUV);
    
    vec3  lightDir = normalize(hitPos - pos);
    float dist     = length(hitPos - pos);
    float falloff  = 1 / (dist * dist + 10.0);
    float fade     = edgeFade.x * edgeFade.y;

    light += NdotL*ndfWeight*hitAlbedo*hitLight;
  }
  
  // shadow map
  rn    = normalize(shadowLightPosition);
  NdotL = max(dot(hitNorm, rn), 0.0);
  
  H         = normalize(pos + rn);
  NdotH     = max(dot(hitNorm, H), 0.0);
  ndfWeight = GGX_NDF(NdotH, roughness) / max(4.0 * NdotL + 1e-4, 1e-4);
  ndfWeight = mix(1.0, ndfWeight, 1.0 - roughness);
  fresnel   = fresnelSchlick(dot(hitNorm, -normalize(pos)), reflectance, roughness);

  vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(pos, 1.0)).xyz;
  vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
  vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
  shadowClipPos.z -= 0.001;
  shadowClipPos.xyz = distortShadowClipPos(shadowClipPos.xyz); 
  vec3 shadowNDCPos = shadowClipPos.xyz / shadowClipPos.w;
  vec3 shadowScreenPos = shadowNDCPos * 0.5 + 0.5;
  float shadow = 0;
  
  for (int i = 0; i <= 10; i++) {
    vec2 u = vogel(i,10,1)/2048;
    float d = texture(shadowtex0, shadowScreenPos.xy+u).r;
    shadow += step(shadowScreenPos.z, d);
  }

  shadow /= 25;
  
  outFastLight.rgb += shadow*skyFunction(normalize(gbufferModelViewInverse*vec4(shadowLightPosition,1)).xyz)*NdotL*ndfWeight*0.1;
  
  light += outFastLight.rgb;
  
  outColor = vec4(col, 1.0);
  outLight = vec4(light, 1.0);
  outDebug.rgb = texture(colortex0, hitUV).rgb;
}
