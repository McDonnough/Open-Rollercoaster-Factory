#version 120

uniform vec2 offset;
uniform int LOD;

varying float dist;
varying vec4 Vertex;
varying vec3 Normal;

float fpart(float a) {
  return a - floor(a);
}

void main(void) {
  Normal = gl_Normal;
  Vertex = gl_Vertex;
  if (LOD == 2)
    Vertex.xz += offset;
  gl_TexCoord[0] = vec4(Vertex.xz * 4.0, 0.0, 1.0);
  dist = length(gl_ModelViewMatrix * Vertex);
  gl_Position = gl_ModelViewProjectionMatrix * Vertex;
}