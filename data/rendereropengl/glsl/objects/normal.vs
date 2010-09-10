#version 120

uniform vec3 Position;
uniform mat3 Rotation;

varying vec4 Vertex;
varying float dist;
varying float SDist;
varying vec3 Normal;

void main(void) {
  Normal = Rotation * gl_Normal;
  gl_TexCoord[0] = vec4(gl_MultiTexCoord0.xy, gl_Color.xz);
  Vertex = vec4(Rotation * gl_Vertex.xyz, gl_Vertex.w);
  Vertex.xyz += Position;
  gl_ClipVertex = gl_ModelViewMatrix * Vertex;
  dist = length(gl_ClipVertex);
  SDist = distance(gl_LightSource[0].position, Vertex);
  gl_Position = gl_ModelViewProjectionMatrix * Vertex;
}