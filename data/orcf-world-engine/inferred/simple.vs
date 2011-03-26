#version 120

varying vec3 Vertex;

void main(void) {
  Vertex = (gl_ModelViewMatrix * gl_Vertex).xyz;
  gl_Position = gl_ProjectionMatrix * gl_Vertex;
}
