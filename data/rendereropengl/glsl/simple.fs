#version 120

varying vec4 Vertex;

void main(void) {
  gl_FragColor = vec4(1.0, 1.0, 1.0, Vertex.y);
}