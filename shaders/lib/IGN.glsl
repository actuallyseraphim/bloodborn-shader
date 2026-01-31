// adapted from: https://blog.demofox.org/2022/01/01/interleaved-gradient-noise-a-different-kind-of-low-discrepancy-sequence/
float IGN(vec2 uv, int frame) {
  frame = frame % 64;
  vec2 p = uv + 5.588238f * float(frame);
  return mod(52.9829189f * mod(0.06711056f*p.x + 0.00583715f*p.y, 1.0f), 1.0f);
}
