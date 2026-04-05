#version 330

uniform sampler2D gtexture;
uniform sampler2D normals;
uniform sampler2D specular;
uniform sampler2D lightmap;

uniform vec4 entityColor;
uniform vec3 skyColor;
uniform float blindness;
uniform int isEyeInWater;
uniform float alphaTestRef;

uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;

in vec4 glcolor;
in vec2 texcoord;
in vec2 lmcoord;
in vec3 normal;
in vec3 tangent;
in vec3 binormal;
in vec3 glposition;

/* RENDERTARGETS: 0,1,2,3,4,7 */
layout(location = 0) out vec4 outColor;
layout(location = 1) out vec4 outNormal;
layout(location = 2) out vec4 outLight;
layout(location = 3) out vec4 outEmision;
layout(location = 4) out vec4 outSpecular;
layout(location = 5) out int outMask;

const float ambientOcclusionLevel = 0.0;

/*
const int colortex0Format = RGB32F;
const int colortex1Format = RGBA32F;
const int colortex2Format = RGBA32F;
const int colortex3Format = RGBA32F;
const int colortex4Format = RGB32F;
const int colortex5Format = RGBA32F;
const int colortex7Format = R32UI;
*/


uniform int renderStage;

void main() {
  vec4 col = glcolor * texture(gtexture, texcoord);
  if (col.a < alphaTestRef) {
    discard;
  }
  outColor = col;
  
  vec3 tangentNormal = texture(normals, texcoord).xyz * 2.0 - 1.0;
  tangentNormal.xy = tangentNormal.xy;
  tangentNormal.z = sqrt(1.0 - dot(tangentNormal.xy, tangentNormal.xy));
  mat3 TBN = mat3(tangent, binormal, normal);
  
  vec3 viewNormal = normalize(TBN * tangentNormal);
  outNormal = vec4(viewNormal, 1.0);
  
  outLight = vec4(lmcoord.x, lmcoord.y, 0, 1);
  vec4 spec = texture(specular, texcoord);
  if (spec.a >= 1) {
    spec.a = 0;
  }

  outSpecular = spec;
  outEmision = vec4(spec.aaa, 1);
  outMask = renderStage;
  if (renderStage == MC_RENDER_STAGE_PARTICLES) {
    outNormal = vec4(0,0,1,1);
  }
}
