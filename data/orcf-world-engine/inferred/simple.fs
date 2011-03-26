#version 120

varying vec3 Vertex;

void main(void) {
  gl_FragData[0] = vec4(0.0, 0.0, 0.0, 1.0);
  gl_FragData[1] = vec4(0.0, 0.0, 0.0, 0.0);
  gl_FragData[2] = vec4(Vertex, length(Vertex));
  gl_FragData[3] = vec4(0.0, 0.0, 0.0, 1.0);
}
