#version 120

uniform float LeftOffset;

varying vec3 Vertex;

void main(void) {
  gl_TexCoord[0] = gl_MultiTexCoord0;
  gl_FrontColor = gl_Color;
  gl_BackColor = gl_Color;
  gl_Position = ftransform();
  Vertex = gl_Vertex.xyz;
  Vertex.x -= LeftOffset;
}