#version 120

uniform sampler2D HeightMap;
uniform float Height;
uniform vec2 TerrainSize;

varying vec3 Vertex;

void main(void) {
  vec2 FakeVertex = Vertex.xz;
  if (Vertex.x < 0.0) FakeVertex.x = Vertex.x * Vertex.x / 1638.4;
  if (Vertex.z < 0.0) FakeVertex.y = Vertex.z * Vertex.z / 1638.4;
  if (Vertex.x > TerrainSize.x) FakeVertex.x = TerrainSize.x - (Vertex.x - TerrainSize.x) * (Vertex.x - TerrainSize.x) / 1638.4;
  if (Vertex.z > TerrainSize.y) FakeVertex.y = TerrainSize.y - (Vertex.z - TerrainSize.y) * (Vertex.z - TerrainSize.y) / 1638.4;

  vec2 hm = texture2D(HeightMap, FakeVertex / TerrainSize).gb;
  if (abs(256.0 * hm.r - Height) > 0.1)
    discard;
  gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
  vec2 projected = (gl_ModelViewProjectionMatrix * vec4(Vertex, 1.0)).zw;
  gl_FragDepth = sqrt(projected.x / projected.y);
}
