#version 120

uniform vec2 offset;
uniform int HighLOD;

varying float dist;
varying vec4 vertex;

void main(void) {
  vertex = gl_Vertex;
  if (HighLOD == 1)
    vertex.xz += offset;
  gl_TexCoord[0] = vec4(vertex.xz, 0.0, 1.0);
  dist = length(gl_ModelViewMatrix * vertex);
  gl_Position = gl_ModelViewProjectionMatrix * vertex;
}