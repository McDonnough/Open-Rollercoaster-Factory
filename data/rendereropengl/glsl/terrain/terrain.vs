#version 120

varying float dist;

void main(void) {
  gl_TexCoord[0] = vec4(gl_Vertex.xz, 0.0, 1.0);
  dist = length(gl_ModelViewMatrix * gl_Vertex);
  gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
}