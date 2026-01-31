vec3 cosineHemisphereSample(vec2 rand, vec3 normal) {
  vec3 bitangent = perpendicular(normal);
  vec3 tangent   = cross(bitangent, normal);

  float r   = sqrt(rand.x);
  float phi = 6.28318530718 * rand.y;

  float x = r * cos(phi);
  float y = r * sin(phi);
  float z = sqrt(max(0.0, 1.0 - rand.x));

  return x * tangent + y * bitangent + z * normal;
}


vec3 sampleCosineHemisphere(vec3 N, float u1, float u2) {
  float r = sqrt(u1);
  float phi = 2.0 * PI * u2;
  float x = r * cos(phi);
  float y = r * sin(phi);
  float z = sqrt(max(0.0, 1.0 - u1)); // = sqrt(1 - r*r)
  vec3 local = vec3(x, y, z);

  float s = N.z >= 0.0 ? 1.0 : -1.0;
  float a = -1.0 / (s + N.z);
  float b = N.x * N.y * a;
  vec3 T = vec3(1.0 + s * N.x * N.x * a, s * b, -s * N.x);
  vec3 B = vec3(b, s + N.y * N.y * a, -N.y);

  vec3 world = local.x * T + local.y * B + local.z * N;
  return normalize(world);
}

bool raymarchSSGI(vec3 rayOrigin,
                  vec3 rayDir,
                  out vec2 hitUV,
                  out vec3 hitPos) {
  const int STEPS = 30;
  const float STEP_SIZE = 0.1;
  const float THICKNESS = 0.1;

  vec3 pos = rayOrigin;

  for (int i = 0; i < STEPS; i++) {
    pos += rayDir * STEP_SIZE * (i+1)/10;

    vec4 clip = gbufferProjection * vec4(pos, 1.0);
    vec3 ndc  = clip.xyz / clip.w;

    if (abs(ndc.x) > 1.0 || abs(ndc.y) > 1.0 || ndc.z > 1.0)
      return false;

    vec2 uv = ndc.xy * 0.5 + 0.5;

    float sceneDepth = texture(depthtex0, uv).r;
    vec3 scenePos = reconstructViewPos(uv, sceneDepth);

    // Depth test (thickness avoids acne)
    if (scenePos.z > pos.z+0.02) {
      hitUV = uv;
      hitPos = scenePos;
      return true;
    }
  }

  return false;
}
