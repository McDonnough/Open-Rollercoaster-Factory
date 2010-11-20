#version 120

varying vec3 Vertex;

void main(void) {
  Vertex = gl_Vertex.xyz;
  gl_Position = gl_ProjectionMatrix * vec4(gl_NormalMatrix * Vertex.xyz, 1.0);
}