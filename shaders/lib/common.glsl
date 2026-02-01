const float PI = 3.14159265359;

uniform mat4 gbufferProjectionInverse;

vec3 perpendicular(vec3 n) {
    return normalize(
        abs(n.z) < 0.999
        ? cross(n, vec3(0.0, 0.0, 1.0))
        : cross(n, vec3(0.0, 1.0, 0.0))
    );
}

vec3 reconstructViewPos(vec2 uv, float depth) {
  float z = depth * 2.0 - 1.0;
  vec4 clip = vec4(uv * 2.0 - 1.0, z, 1.0);
  vec4 view = gbufferProjectionInverse * clip;
  return view.xyz/view.w;
}

uniform float near;
uniform float far;

float linearizeDepth(float depth) {
  return near * far / (far + depth * (near - far));;
}
