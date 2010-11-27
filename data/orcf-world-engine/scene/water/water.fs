#version 120

uniform sampler2D HeightMap;
uniform float Height;
uniform vec2 TerrainSize;

varying vec2 Vertex;

void main(void) {
  vec2 hm = texture2D(HeightMap, Vertex / TerrainSize).gb;
  if (abs(256.0 * hm.r - Height) > 0.1 || hm.r < hm.g)
    discard;
  gl_FragData[2] = vec4(Vertex.x, Height, Vertex.y, length(vec3(gl_ModelViewMatrix * vec4(Vertex.x, Height, Vertex.y, 1.0))));
  gl_FragData[1] = vec4(0.0, 1.0, 0.0, 1.0);
  gl_FragData[0] = vec4(1.0, 1.0, 1.0, 1.0);
}
