#version 120

uniform mat4 TransformMatrix;

varying vec4 Vertex;
varying float dist;
varying float SDist;
varying vec3 Normal;

void main(void) {
  Normal = mat3(TransformMatrix) * gl_Normal;
  gl_TexCoord[0] = vec4(gl_MultiTexCoord0.xy, gl_Color.rg);
  Vertex = TransformMatrix * gl_Vertex;
  gl_ClipVertex = gl_ModelViewMatrix * Vertex;
  dist = length(gl_ClipVertex);
  SDist = distance(gl_LightSource[0].position, Vertex);
  gl_Position = gl_ModelViewProjectionMatrix * Vertex;
}