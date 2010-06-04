#version 120

uniform sampler2D HeightMap;
uniform vec2 TerrainSize;

varying vec4 Vertex;
varying float dist;

float fpart(float a) {
  return a - floor(a);
}

float fetchHeight(int index) {
  return mix(
          mix(texture2D(HeightMap, 5.0 * (Vertex.xz  + vec2(0.0, 0.0)) / TerrainSize)[index], texture2D(HeightMap, 5.0 * (Vertex.xz  + vec2(0.2, 0.0)) / TerrainSize)[index], fpart(5.0 * Vertex.x)),
          mix(texture2D(HeightMap, 5.0 * (Vertex.xz  + vec2(0.0, 0.2)) / TerrainSize)[index], texture2D(HeightMap, 5.0 * (Vertex.xz  + vec2(0.2, 0.2)) / TerrainSize)[index], fpart(5.0 * Vertex.x)),
          fpart(5.0 * Vertex.z)) * 256.0;
}

void main(void) {
  float h = fetchHeight(1);
  if (h < Vertex.y - 0.01 || h > Vertex.y + 0.01)
    discard;
  gl_FragColor = vec4(dist / 256.0, fpart(dist), 1.0, Vertex.y);
}