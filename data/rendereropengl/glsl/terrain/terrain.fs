#version 120

uniform sampler2D TerrainTexture;

vec2 trunc(vec2 a) {
  return a - floor(a);
}

vec2 getRightTexCoord(float fac) {
  return clamp(trunc(gl_TexCoord[0].xy * 4.0 * fac), 1.0 / 512.0, 1.0 - 1.0 / 512.0) / 4.0;
}

void main(void) {
  gl_FragColor = (texture2D(TerrainTexture, getRightTexCoord(1.0 / 483)) + texture2D(TerrainTexture, getRightTexCoord(1.0 / 128.0))) * 0.5;
}