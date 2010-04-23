#version 120

varying vec3 Vertex;
varying vec3 EndlessVertex;

void main(void) {
  Vertex = (gl_ModelViewMatrix * gl_Vertex).xyz;
  EndlessVertex = Vertex / (2500.0 - Vertex.y);
  gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
}