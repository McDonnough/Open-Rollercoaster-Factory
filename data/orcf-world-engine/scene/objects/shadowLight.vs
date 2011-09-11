#version 120

uniform vec3 ShadowOffset;
uniform float ShadowSize;
uniform mat4 TransformMatrix;
uniform mat4 MeshTransformMatrix;
uniform mat4 DeformMatrix;
uniform vec3 Mirror;
uniform vec3 VirtScale;

varying vec3 dir;

void main(void) {
  vec3 Vertex = (TransformMatrix * (DeformMatrix * ((MeshTransformMatrix * vec4(gl_Vertex.xyz, 1.0)) * vec4(VirtScale * Mirror, 1.0)))).xyz;
  dir = Vertex - gl_LightSource[1].position.xyz;
  gl_Position = gl_ModelViewProjectionMatrix * vec4(Vertex, 1.0);
}