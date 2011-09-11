#version 120

uniform mat4 TransformMatrix;
uniform mat4 MeshTransformMatrix;
uniform mat4 DeformMatrix;
uniform vec3 Mirror;
uniform vec3 VirtScale;

varying vec3 _Vertex;
varying vec3 _OrigVertex;
varying vec3 _Normal;
varying vec3 _TransformedVertex;

void main(void) {
  _OrigVertex = (TransformMatrix * (DeformMatrix * ((MeshTransformMatrix * vec4(gl_Vertex.xyz, 0.0)) * vec4(VirtScale * Mirror, 1.0)))).xyz;
  _Vertex = _OrigVertex + TransformMatrix[3].xyz + MeshTransformMatrix[3].xyz;
  mat4 transposedInverseDeformMatrix = transpose(DeformMatrix);
  transposedInverseDeformMatrix[1].x = -transposedInverseDeformMatrix[1].x;
  transposedInverseDeformMatrix[1].z = -transposedInverseDeformMatrix[1].z;
  _Normal = normalize(vec3(TransformMatrix * (transposedInverseDeformMatrix * (MeshTransformMatrix * vec4(gl_Normal * Mirror / VirtScale, 0.0)))));
  _TransformedVertex = (gl_ModelViewMatrix * vec4(_Vertex, 1.0)).xyz;
  gl_TexCoord[0] = gl_MultiTexCoord0;
  gl_Position = gl_ModelViewProjectionMatrix * vec4(_Vertex, 1.0);
}