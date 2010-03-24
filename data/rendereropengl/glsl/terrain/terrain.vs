#version 120

uniform vec2 offset;
uniform int HighLOD;

varying float dist;
varying vec4 Vertex;
varying vec3 Normal;

void main(void) {
  Normal = gl_Normal;
  Vertex = gl_Vertex;
  if (HighLOD == 1)
    Vertex.xz += offset;
  gl_TexCoord[0] = vec4(Vertex.xz * 4.0, 0.0, 1.0);
  dist = length(gl_ModelViewMatrix * Vertex);
  gl_Position = gl_ModelViewProjectionMatrix * Vertex;
}