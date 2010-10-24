#version 120

void main(void) {
  gl_Position = vec4(gl_Vertex.xy, 1.0, 1.0);
  gl_TexCoord[0].xy = 0.5 + 0.5 * gl_Vertex.xy;
}