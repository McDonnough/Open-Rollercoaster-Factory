#version 120

varying vec3 Vertex;

void main(void) {
  Vertex = gl_Vertex.xyz;
  gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
  gl_ClipVertex = gl_ModelViewMatrix * gl_Vertex;
}
