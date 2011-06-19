#version 120

uniform ivec3 SelectionMeshID;

varying vec3 Vertex;

void main(void) {
  gl_FragData[0] = vec4(Vertex, 1.0);
  gl_FragData[1] = vec4(SelectionMeshID, 1.0);
  float dist = length(vec3(gl_ModelViewMatrix * vec4(Vertex, 1.0)));
  gl_FragDepth = dist / 10000.0;
}