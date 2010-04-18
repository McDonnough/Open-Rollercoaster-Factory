#version 120

varying float dist;

void main(void) {
  dist = length(gl_ModelViewMatrix * gl_Vertex);
  gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
}