#version 120

uniform mat4 TransformMatrix;
uniform vec3 Mirror;

varying vec3 _Vertex;
varying vec3 _OrigVertex;
varying vec3 _Normal;
varying vec3 _TransformedVertex;

void main(void) {
  _OrigVertex = (TransformMatrix * vec4(gl_Vertex.xyz, 0.0)).xyz;
  _Vertex = vec3(TransformMatrix * vec4(gl_Vertex.xyz * Mirror, 1.0));
  _Normal = vec3(TransformMatrix * vec4(gl_Normal * Mirror, 0.0));
  _TransformedVertex = (gl_ModelViewMatrix * vec4(_Vertex, 1.0)).xyz;
  gl_TexCoord[0] = gl_MultiTexCoord0;
  gl_Position = gl_ModelViewProjectionMatrix * vec4(_Vertex, 1.0);
}