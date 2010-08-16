#version 120

uniform sampler2D HeightMap;
uniform vec2 TerrainSize;

varying float dist;
varying vec4 distv;
varying vec4 Vertex;

void main(void) {
  gl_TexCoord[0] = gl_MultiTexCoord0;
  Vertex = gl_Vertex;
  Vertex.y = gl_TexCoord[0].z;
  dist = length(gl_ModelViewMatrix * Vertex);
  distv = gl_ModelViewMatrix * Vertex;
  gl_Position = gl_ModelViewProjectionMatrix * Vertex;
}