#version 120

uniform float Height;

varying vec3 Vertex;

void main(void) {
  Vertex.y = Height;
  Vertex.xz = gl_Vertex.xy;
  gl_Position = gl_ModelViewProjectionMatrix * vec4(Vertex, 1.0);
  gl_ClipVertex = gl_ModelViewMatrix * vec4(Vertex, 1.0);
}
