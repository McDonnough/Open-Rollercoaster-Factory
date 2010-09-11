#version 120

varying vec4 Vertex;
varying float dist;

float fpart(float a) {
  return a - floor(a);
}

void main(void) {
  gl_FragColor = vec4(dist / 1024.0, fpart(dist / 4), 1.0, Vertex.y);
}