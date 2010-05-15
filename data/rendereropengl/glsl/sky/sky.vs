#version 120

varying vec3 Vertex;
varying vec3 BaseVertex;

void main(void) {
  BaseVertex = gl_Vertex.xyz;
  Vertex = (gl_ModelViewMatrix * gl_Vertex).xyz;
  gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
}