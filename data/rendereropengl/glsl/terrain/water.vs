#version 120

uniform sampler2D HeightMap;
uniform vec2 TerrainSize;

// varying float SDist;
varying vec4 Vertex;
varying vec4 v;

void main(void) {
  gl_TexCoord[0] = gl_MultiTexCoord0;
  Vertex = gl_Vertex;
  Vertex.y = gl_TexCoord[0].z;
  v = gl_ModelViewMatrix * Vertex;
  gl_Position = gl_ModelViewProjectionMatrix * Vertex;
}