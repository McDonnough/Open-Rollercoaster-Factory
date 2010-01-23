#version 120

uniform sampler2D TerrainTexture;
uniform sampler2D HeightMap;
uniform vec2 TerrainSize;

varying float dist;

vec2 trunc(vec2 a) {
  return a - floor(a);
}

vec2 getRightTexCoord(void) {
  return trunc(gl_TexCoord[0].xy * 4.0) / 4.0;
}

void main(void) {
  gl_TexCoord[0] = vec4(gl_Vertex.xz / 64.0, 0.0, 1.0);
  vec4 Vertex = gl_Vertex;
  vec4 ht = texture2D(HeightMap, gl_Vertex.xz / TerrainSize);
  Vertex.y = 256.0 * ht.g + ht.r;
  dist = length(gl_ModelViewMatrix * gl_Vertex);
  gl_Position = gl_ModelViewProjectionMatrix * Vertex;
}