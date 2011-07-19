#version 120

uniform mat4 TransformMatrix;
uniform vec3 Mirror;

varying vec3 Vertex;
varying vec3 OrigVertex;
varying vec3 Normal;

void main(void) {
  OrigVertex = gl_Vertex.xyz;
  Vertex = vec3(TransformMatrix * vec4(gl_Vertex.xyz * Mirror, 1.0));
  Normal = vec3(TransformMatrix * vec4(gl_Normal * Mirror, 0.0));
  gl_TexCoord[0] = gl_MultiTexCoord0;
  gl_Position = gl_ModelViewProjectionMatrix * vec4(Vertex, 1.0);
  gl_ClipVertex = gl_ModelViewMatrix * vec4(Vertex, 1.0);
}