#version 120

uniform vec3 ShadowOffset;
uniform float ShadowSize;
uniform mat4 TransformMatrix;

varying vec3 dir;

void main(void) {
  vec3 Vertex = vec3(TransformMatrix * gl_Vertex);
  dir = Vertex - gl_LightSource[1].position.xyz;
  gl_Position = gl_ModelViewProjectionMatrix * vec4(Vertex, 1.0);
}