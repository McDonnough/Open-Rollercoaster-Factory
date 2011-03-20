#version 120

varying float DirectionFactor;

void main(void) {
  gl_Position = vec4(gl_Vertex.xy, 1.0, 1.0);
  gl_TexCoord[0].xy = 0.5 + 0.5 * gl_Vertex.xy;
  DirectionFactor = 1.0 - abs(dot(gl_NormalMatrix * vec3(0.0, 0.0, 1.0), vec3(0.0, 1.0, 0.0)));
}