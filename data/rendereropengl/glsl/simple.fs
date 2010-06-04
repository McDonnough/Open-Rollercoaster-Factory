#version 120

varying vec4 Vertex;
varying float dist;

float fpart(float a) {
  return a - floor(a);
}

void main(void) {
  gl_FragColor = vec4(dist / 256.0, fpart(dist), 1.0, Vertex.y);
}