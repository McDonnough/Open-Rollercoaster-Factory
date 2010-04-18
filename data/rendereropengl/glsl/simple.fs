#version 120

varying float dist;

void main(void) {
  gl_FragColor =  vec4(0.0, 0.0, 0.0, 1.0);
  gl_FragDepth = sqrt(dist / 10000.0);
}