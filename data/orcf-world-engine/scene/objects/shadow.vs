#version 120

uniform vec3 ShadowOffset;
uniform float ShadowSize;
uniform mat4 TransformMatrix;
uniform vec3 Mirror;

varying vec3 VData;

void main(void) {
  vec3 Vertex = vec3(TransformMatrix * vec4(gl_Vertex.xyz * Mirror, 1.0));
  VData = Vertex;
  vec3 dir = Vertex - gl_LightSource[0].position.xyz;
  dir /= abs(dir.y);
  Vertex += (Vertex.y - ShadowOffset.y) * dir;
  Vertex -= ShadowOffset;
  gl_Position = vec4((Vertex / ShadowSize).xz, 1.0, 1.0);
}