#version 120

uniform vec2 Offset;

void main(void) {
  gl_Position.xz = Offset + gl_Vertex.xz;
  gl_Position.yw = vec2(0.0, 1.0);
}