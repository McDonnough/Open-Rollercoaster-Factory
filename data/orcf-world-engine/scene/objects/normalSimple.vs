#version 120

uniform mat4 TransformMatrix;
uniform mat4 MeshTransformMatrix;
uniform vec3 Mirror;
uniform vec3 VirtScale;

varying vec3 Vertex;
varying vec3 OrigVertex;
varying vec3 Normal;

void main(void) {
  OrigVertex = (TransformMatrix * ((MeshTransformMatrix * vec4(gl_Vertex.xyz, 0.0)) * vec4(VirtScale * Mirror, 1.0))).xyz;
  Vertex = vec3(TransformMatrix * ((MeshTransformMatrix * vec4(gl_Vertex.xyz, 1.0)) * vec4(VirtScale * Mirror, 1.0)));
  Normal = vec3(TransformMatrix * vec4(gl_Normal * Mirror / VirtScale, 0.0));
  gl_TexCoord[0] = gl_MultiTexCoord0;
  gl_Position = gl_ModelViewProjectionMatrix * vec4(Vertex, 1.0);
  gl_ClipVertex = gl_ModelViewMatrix * vec4(Vertex, 1.0);
}