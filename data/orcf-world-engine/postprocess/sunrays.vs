#version 120

uniform vec3 VecToFront;

varying vec2 lightPositionOnScreen;
varying float angleFactor;

void main(void) {
  angleFactor = clamp(3.0 * dot(normalize(VecToFront), normalize(gl_LightSource[0].position.xyz)), 0.0, 1.0);
  vec4 vec = gl_ModelViewProjectionMatrix * gl_LightSource[0].position;
  lightPositionOnScreen = 0.5 + 0.5 * vec.xy / vec.w;
  gl_Position = vec4(gl_Vertex.xy, 1.0, 1.0);
  gl_TexCoord[0].xy = 0.5 + 0.5 * gl_Vertex.xy;
}