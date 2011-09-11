#version 120

uniform vec3 ShadowOffset;
uniform float ShadowSize;
uniform mat4 TransformMatrix;
uniform mat4 MeshTransformMatrix;
uniform mat4 DeformMatrix;
uniform vec3 Mirror;
uniform vec3 VirtScale;

varying vec3 VData;

void main(void) {
  vec3 Vertex = (TransformMatrix * (DeformMatrix * ((MeshTransformMatrix * vec4(gl_Vertex.xyz, 1.0)) * vec4(VirtScale * Mirror, 1.0)))).xyz;
  VData = Vertex;
  vec3 dir = Vertex - gl_LightSource[0].position.xyz;
  dir /= abs(dir.y);
  Vertex += (Vertex.y - ShadowOffset.y) * dir;
  Vertex -= ShadowOffset;
  gl_Position = vec4((Vertex / ShadowSize).xz, 1.0, 1.0);
}