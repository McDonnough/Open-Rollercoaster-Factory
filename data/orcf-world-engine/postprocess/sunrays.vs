#version 120

varying vec2 lightPositionOnScreen;

void main(void) {
  vec4 vec = gl_ProjectionMatrix * vec4(gl_NormalMatrix * gl_LightSource[0].position.xyz, 1.0);
  lightPositionOnScreen = 0.5 + 0.5 * vec.xy / vec.w;
  gl_Position = vec4(gl_Vertex.xy, 1.0, 1.0);
  gl_TexCoord[0].xy = 0.5 + 0.5 * gl_Vertex.xy;
}