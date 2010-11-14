#version 120

varying vec3 Vertex;
varying vec3 VData;

void main(void) {
  gl_FragData[0] = vec4(1.0, 1.0, 1.0, VData.y);
  gl_FragDepth = 1.0 - VData.y / 1000.0;
}