#version 120

void main(void) {
  gl_TexCoord[0] = vec4(gl_Vertex.xz, 0.0, 1.0);
  gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
}