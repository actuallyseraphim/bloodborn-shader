const float PI = 3.14159265359;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 modelViewMatrixInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelView;

uniform vec3 cameraPosition;

vec3 perpendicular(vec3 n) {
    return normalize(
        abs(n.z) < 0.999
        ? cross(n, vec3(0.0, 0.0, 1.0))
        : cross(n, vec3(0.0, 1.0, 0.0))
    );
}

vec3 projectAndDivide(mat4 m, vec3 p) {
  vec4 h = m * vec4(p,1);
  return h.xyz/h.w;
}

vec3 reconstructViewPos(vec2 uv, float depth) {
  float z = depth * 2.0 - 1.0;
  vec4 clip = vec4(uv * 2.0 - 1.0, z, 1.0);
  vec4 view = gbufferProjectionInverse * clip;
  return view.xyz/view.w;
}

vec3 reconstructWorldPos(vec2 uv, float depth) {
  return (gbufferModelViewInverse*vec4(reconstructViewPos(uv,depth),1.0)).xyz + cameraPosition;
}

uniform float near;
uniform float far;

float linearizeDepth(float depth) {
  return near * far / (far + depth * (near - far));;
}

uniform vec3 sunPosition;   // view-space sun direction (built-in)
uniform vec3 moonPosition;  // view-space moon direction (built-in)
uniform int worldTime;      // 0–24000 ticks
uniform float rainStrength;

vec3 skyFunction(vec3 dir) {
  dir = normalize(dir);
  vec3 sunDir  = normalize(gbufferModelViewInverse * vec4(sunPosition, 1.0)).xyz;
  vec3 moonDir = normalize(gbufferModelViewInverse * vec4(moonPosition, 1.0)).xyz;
    
  float horizon = pow(max(1.0 - abs(dir.y), 0.0), 4.0);
  float zenith  = clamp(dir.y * 0.5 + 0.5, 0.0, 1.0);

  vec3 dayZenith   = vec3(0.10, 0.22, 0.60);
  vec3 dayHorizon  = vec3(0.60, 0.75, 0.90);
  vec3 nightSky    = vec3(0.01, 0.01, 0.04);

  float dayFactor  = clamp(sunDir.y * 0.5+0.5, 0.0, 1.0);
  float nightFactor = 1.0 - dayFactor;

  vec3 sky = mix(dayZenith, dayHorizon, horizon) * dayFactor
    + nightSky * nightFactor;

  float sunAltitude  = clamp(sunDir.y, 0.0, 1.0);
  float sunsetBlend  = pow(1.0 - sunAltitude, 3.0) * horizon;
  vec3  sunsetColor  = vec3(1.0, 0.35, 0.05);
  //sky = mix(sky, sunsetColor, sunsetBlend * 0.8);

  sky += step(dot(dir,-sunDir), -0.998);
  
  if (rainStrength > 0.0) {
    vec3 overcast = vec3(0.35, 0.38, 0.42);
    sky = mix(sky, overcast, rainStrength * 0.85);
  }

  return max(sky, vec3(0.0));
}
