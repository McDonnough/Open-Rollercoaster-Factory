#version 120

varying vec3 dir;

void main(void) {
  gl_FragColor = vec4(1.0, 1.0, 1.0, length(dir));
}