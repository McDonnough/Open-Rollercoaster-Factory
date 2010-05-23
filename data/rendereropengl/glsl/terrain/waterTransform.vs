#version 120

uniform sampler2D HeightMap;
uniform vec2 TerrainSize;

varying float dist;
varying vec4 Vertex;

void main(void) {
  Vertex = gl_Vertex;
  dist = length(gl_ModelViewMatrix * Vertex);
  gl_Position = gl_ModelViewProjectionMatrix * Vertex;
}