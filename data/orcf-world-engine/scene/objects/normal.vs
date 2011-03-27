#version 120

uniform mat4 TransformMatrix;

varying vec3 Vertex;
varying vec3 Normal;

void main(void) {
  Vertex = vec3(TransformMatrix * gl_Vertex);
  Normal = mat3(TransformMatrix) * gl_Normal;
  gl_TexCoord[0] = gl_MultiTexCoord0;
  gl_Position = gl_ModelViewProjectionMatrix * vec4(Vertex, 1.0);
  gl_ClipVertex = gl_ModelViewMatrix * vec4(Vertex, 1.0);
}