#version 120

#extension GL_EXT_gpu_shader4 : require

uniform sampler2D GeometryTex;
uniform mat4 RotMat;

uniform vec2 Offset;
uniform float Size;

const float PIPI = 6.2832;

void main(void) {
  vec4 pos = texelFetch2D(GeometryTex, ivec2(floor(gl_FragCoord.xy)), 0);
  pos = RotMat * pos;
  pos.xz += Offset;
  vec2 fac = vec2(pow(0.5 + 0.5 * cos(PIPI * pos.x / Size), 16.0), pow(0.5 + 0.5 * cos(PIPI * pos.z / Size), 16.0)) / (pos.w / 20.0 / Size + 1.0);
  float lf = 0.5 * mix(0.0, 1.0, min(1.0, fac.x + fac.y));
  gl_FragColor = vec4(0.0, lf, lf, 1.0);
}