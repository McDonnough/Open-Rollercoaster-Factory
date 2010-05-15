#version 120

uniform sampler2D ModelTexture;

varying float dist;

void main(void) {
  gl_FragColor = vec4(1.0, 1.0, 1.0, dist);
  gl_FragDepth = dist / 20000.0;
}
