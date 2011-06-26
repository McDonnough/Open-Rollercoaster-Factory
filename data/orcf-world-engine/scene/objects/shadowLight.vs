#version 120

uniform vec3 ShadowOffset;
uniform float ShadowSize;
uniform mat4 TransformMatrix;
uniform vec3 Mirror;

varying vec3 dir;

void main(void) {
  vec3 Vertex = vec3(TransformMatrix * vec4(gl_Vertex.xyz * Mirror, 1.0));
  dir = Vertex - gl_LightSource[1].position.xyz;
  gl_Position = gl_ModelViewProjectionMatrix * vec4(Vertex, 1.0);
}