#version 120

uniform sampler2D HeightMap;
uniform float Height;
uniform vec2 TerrainSize;

varying vec2 Vertex;

void main(void) {
  vec2 hm = texture2D(HeightMap, Vertex / TerrainSize).gb;
  if (abs(256.0 * hm.r - Height) > 0.1 || hm.r < hm.g) {
    discard;
  gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);
}
