#version 120

uniform ivec3 SelectionMeshID;

varying vec3 Vertex;

void main(void) {
  gl_FragData[0] = vec4(Vertex, 1.0);
  gl_FragData[1] = vec4(SelectionMeshID, 1.0);
}