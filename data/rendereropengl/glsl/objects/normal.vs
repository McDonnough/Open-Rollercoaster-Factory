#version 120

uniform mat4 TransformMatrix;

uniform vec2 ShadowQuadA;
uniform vec2 ShadowQuadB;
uniform vec2 ShadowQuadC;
uniform vec2 ShadowQuadD;

varying vec4 Vertex;
varying float dist;
varying vec3 Normal;

vec2 LineIntersection(vec2 p1, vec2 p2, vec2 p3, vec2 p4) {
  float divisor = (p1.x - p2.x) * (p3.y - p4.y) - (p1.y - p2.y) * (p3.x - p4.x);
  float fac1 = p1.x * p2.y - p1.y * p2.x;
  float fac2 = p3.x * p4.y - p3.y * p4.x;
  return vec2((fac1 * (p3.x - p4.x) - fac2 * (p1.x - p2.x)) / divisor,
              (fac1 * (p3.y - p4.y) - fac2 * (p1.y - p2.y)) / divisor);
}
vec4 mapPixelToQuad(vec2 P) {
  vec2 result = P / 204.8;
  return vec4(result, 1.0, 1.0);
}

void main(void) {
  Normal = mat3(TransformMatrix) * gl_Normal;
  gl_TexCoord[0] = vec4(gl_MultiTexCoord0.xy, gl_Color.rg);
  Vertex = TransformMatrix * gl_Vertex;
  gl_ClipVertex = gl_ModelViewMatrix * Vertex;
  dist = length(gl_ClipVertex);
  vec4 LightVec = Vertex - gl_LightSource[0].position;
  gl_TexCoord[7] = mapPixelToQuad(Vertex.xz + LightVec.xz / abs(LightVec.y) * Vertex.y);
  gl_Position = gl_ModelViewProjectionMatrix * Vertex;
}