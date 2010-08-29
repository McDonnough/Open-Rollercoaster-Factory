#version 120

uniform sampler2D HeightMap;
uniform vec2 TerrainSize;

varying float dist;
varying vec4 Vertex;

void main(void) {
  gl_TexCoord[0] = gl_MultiTexCoord0;
  Vertex = gl_Vertex;
  Vertex.y = gl_TexCoord[0].z;
  dist = distance(gl_LightSource[0].position, Vertex);
  gl_Position = gl_TextureMatrix[0] * Vertex;
//   gl_Position = sqrt(abs(gl_Position)) * sign(gl_Position);
}