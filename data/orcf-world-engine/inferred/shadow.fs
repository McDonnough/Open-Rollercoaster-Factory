#version 120

varying vec3 Vertex;
varying vec3 VData;

void main(void) {
  gl_FragData[0] = vec4(1.0, 1.0, 1.0, 1.0);
  gl_FragData[1] = vec4(VData.y, distance(gl_LightSource[0].position.xyz, VData), distance(Vertex, VData), 1.0);
  gl_FragDepth = 1.0 - VData.y / 1000.0;
}