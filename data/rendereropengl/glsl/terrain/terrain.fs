#version 120

uniform sampler2D TerrainTexture;

varying float dist;

vec2 trunc(vec2 a) {
  return a - floor(a);
}

vec2 getRightTexCoord(float fac) {
  return trunc(gl_TexCoord[0].xy * 4.0 * fac) / 4.0;
}

void main(void) {
  gl_FragColor = texture2D(TerrainTexture, getRightTexCoord(1.0)) * vec4(1.0, 1.0, 1.0, dist - 10.0);
}