#version 120

uniform sampler2D HeightMap;
uniform vec2 TerrainSize;

uniform vec2 offset;
uniform vec2 VOffset;
uniform int LOD;

varying float dist;
varying vec4 Vertex;

float fpart(float a) {
  return a - floor(a);
}

float fetchHeightAtOffset(vec2 O) {
  return texture2D(HeightMap, 5.0 * (Vertex.xz + O + vec2(0.1, 0.1)) / TerrainSize).a * 256.0;
}

void main(void) {
  Vertex = gl_Vertex;
  Vertex.xz *= pow(4.0, 2.0 - LOD);
  Vertex.xz += VOffset;
  Vertex.y = fetchHeightAtOffset(vec2(0.0, 0.0));
  gl_TexCoord[0] = vec4(Vertex.xz * 4.0, 0.0, 1.0);
  dist = length(gl_ModelViewMatrix * Vertex);
  gl_Position = gl_ModelViewProjectionMatrix * Vertex;
}