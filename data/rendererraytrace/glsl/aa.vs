#version 120

uniform ivec2 Size;
uniform int Samples;

void main(void) {
  gl_TexCoord[0] = 1000.0 * (0.5 + 0.5 * gl_Vertex);
  gl_TexCoord[0].xy *= (1.0 - (1.0 / Size - 1.0 / (Samples * Size)));
  gl_Position = gl_Vertex;
}