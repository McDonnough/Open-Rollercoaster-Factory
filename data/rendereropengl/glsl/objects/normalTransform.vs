#version 120

uniform mat4 TransformMatrix;

varying vec4 Vertex;
varying float dist;

void main(void) {
  gl_TexCoord[0] = vec4(gl_MultiTexCoord0.xy, gl_Color.xz);
  Vertex = TransformMatrix * gl_Vertex;
  gl_ClipVertex = gl_ModelViewMatrix * Vertex;
  dist = length(gl_ClipVertex);
  gl_Position = gl_ModelViewProjectionMatrix * Vertex;
}