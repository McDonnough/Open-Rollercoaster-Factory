#version 120

uniform mat4 TransformMatrix;
uniform vec3 Mirror;

varying vec3 Vertex;
varying vec3 OrigVertex;
varying vec3 Normal;
varying vec3 Tangent;
varying vec3 Bitangent;
varying vec3 TransformedVertex;
varying vec3 TransformedNormal;

void main(void) {
  OrigVertex = (TransformMatrix * vec4(gl_Vertex.xyz, 0.0)).xyz;
  Vertex = vec3(TransformMatrix * vec4(gl_Vertex.xyz * Mirror, 1.0));
  Normal = vec3(TransformMatrix * vec4(gl_Normal * Mirror, 0.0));
  Tangent = vec3(TransformMatrix * vec4(gl_Color.xyz * Mirror, 0.0));
  Bitangent = cross(Normal, Tangent) * gl_Color.w * Mirror;
  TransformedVertex = (gl_ModelViewMatrix * vec4(Vertex, 1.0)).xyz;
  TransformedNormal = gl_NormalMatrix * Normal;
  gl_TexCoord[0] = gl_MultiTexCoord0;
  gl_Position = gl_ModelViewProjectionMatrix * vec4(Vertex, 1.0);
  gl_ClipVertex = vec4(TransformedVertex, 1.0);
}