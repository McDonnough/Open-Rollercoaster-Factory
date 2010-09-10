#version 120

uniform vec3 Position;
uniform mat3 Rotation;

varying vec4 Vertex;
varying float dist;

void main(void) {
  gl_TexCoord[0] = vec4(gl_MultiTexCoord0.xy, gl_Color.xz);
  Vertex = vec4(Rotation * gl_Vertex.xyz, gl_Vertex.w);
  Vertex.xyz += Position;
  dist = distance(gl_LightSource[0].position, Vertex);
  gl_Position = gl_TextureMatrix[0] * Vertex;
}