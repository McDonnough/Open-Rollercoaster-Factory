#version 120

uniform sampler2D HeightMap;
uniform vec2 TerrainSize;

varying vec4 Vertex;
varying vec4 v;

vec4 mapPixelToQuad(vec2 P) {
  vec2 result = P / 204.8;
  return vec4(result, 1.0, 1.0);
}

void main(void) {
  gl_TexCoord[0] = gl_MultiTexCoord0;
  Vertex = gl_Vertex;
  Vertex.y = gl_TexCoord[0].z;
  v = gl_ModelViewMatrix * Vertex;
  vec4 LightVec = Vertex - gl_LightSource[0].position;
  gl_TexCoord[7] = mapPixelToQuad(Vertex.xz + LightVec.xz / abs(LightVec.y) * Vertex.y);
  gl_Position = gl_ModelViewProjectionMatrix * Vertex;
}