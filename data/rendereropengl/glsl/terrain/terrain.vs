#version 120

uniform vec2 offset;

varying float dist;

void main(void) {
  vec4 Vertex = gl_Vertex;
  Vertex.xz += offset;
  gl_TexCoord[0] = vec4(Vertex.xz, 0.0, 1.0);
  dist = length(gl_ModelViewMatrix * Vertex);
  gl_Position = gl_ModelViewProjectionMatrix * Vertex;
}