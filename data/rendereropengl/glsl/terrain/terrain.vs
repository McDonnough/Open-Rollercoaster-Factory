#version 120

uniform vec2 offset;
uniform int LOD;

varying float dist;
varying vec4 Vertex;
varying vec3 Normal;
varying vec4 TexMap;

float fpart(float a) {
  return a - floor(a);
}

vec4 processTexCoord(float texID) {
  return vec4(fpart(texID / 4.0), floor(texID / 4.0) / 4.0, 0.0, 1.0);
}

void main(void) {
  TexMap = gl_Color;
  Normal = gl_Normal;
  Vertex = gl_Vertex;
  if (LOD == 2)
    Vertex.xz += offset;
  gl_TexCoord[0] = vec4(Vertex.xz * 4.0, 0.0, 1.0);
  gl_TexCoord[1] = processTexCoord(gl_Color.r);
  gl_TexCoord[2] = processTexCoord(gl_Color.g);
  gl_TexCoord[3] = processTexCoord(gl_Color.b);
  gl_TexCoord[4] = processTexCoord(gl_Color.a);
  dist = length(gl_ModelViewMatrix * Vertex);
  gl_Position = gl_ModelViewProjectionMatrix * Vertex;
}