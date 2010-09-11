#version 120

uniform mat4 TransformMatrix;

varying vec4 Vertex;
varying float dist;

vec4 mapPixelToQuad(vec2 P) {
  vec2 result = P / 204.8;
  result *= 2.0;
  result -= 1.0;
  return vec4(result, 1.0, 1.0);
}

void main(void) {
  gl_TexCoord[0] = vec4(gl_MultiTexCoord0.xy, gl_Color.xz);
  Vertex = TransformMatrix * gl_Vertex;
  dist = Vertex.y;
  vec4 LightVec = Vertex - gl_LightSource[0].position;
  gl_Position = mapPixelToQuad(Vertex.xz + LightVec.xz / abs(LightVec.y) * Vertex.y);
}