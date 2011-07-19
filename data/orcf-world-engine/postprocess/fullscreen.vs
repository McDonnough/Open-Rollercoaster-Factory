#version 120

void main(void) {
  gl_Position = vec4(gl_Vertex.xy, 1.0, 1.0);
  gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;
  gl_FrontColor = gl_Color;
  gl_BackColor = gl_Color;
}