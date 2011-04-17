#version 120

uniform vec3 ShadowOffset;
uniform float ShadowSize;
uniform mat4 TransformMatrix;

varying vec3 VData;

void main(void) {
  vec3 Vertex = vec3(TransformMatrix * gl_Vertex);
  VData = Vertex;
  vec3 dir = Vertex - gl_LightSource[0].position.xyz;
  dir /= abs(dir.y);
  Vertex += (Vertex.y - ShadowOffset.y) * dir;
  Vertex -= ShadowOffset;
  gl_Position = vec4((Vertex / ShadowSize).xz, 1.0, 1.0);
}