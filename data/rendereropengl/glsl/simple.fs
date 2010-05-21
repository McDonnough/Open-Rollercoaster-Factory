#version 120

varying float dist;

void main(void) {
  gl_FragDepth = sqrt(dist / 10000.0);
  gl_FragColor = vec4(gl_FragDepth, gl_FragDepth, gl_FragDepth, gl_FragDepth);
}