#version 120

uniform sampler2D HeightMap;
uniform vec2 TerrainSize;
uniform float TexToDo;

uniform vec2 ShadowQuadA;
uniform vec2 ShadowQuadB;
uniform vec2 ShadowQuadC;
uniform vec2 ShadowQuadD;

varying float dist;
varying vec4 result;
varying vec4 Vertex;
varying vec4 BaseVertex;
varying vec3 normal;
varying float Texture;

float fpart(float a) {
  return a - floor(a);
}

vec2 LineIntersection(vec2 p1, vec2 p2, vec2 p3, vec2 p4) {
  float divisor = (p1.x - p2.x) * (p3.y - p4.y) - (p1.y - p2.y) * (p3.x - p4.x);
  float fac1 = p1.x * p2.y - p1.y * p2.x;
  float fac2 = p3.x * p4.y - p3.y * p4.x;
  return vec2((fac1 * (p3.x - p4.x) - fac2 * (p1.x - p2.x)) / divisor,
              (fac1 * (p3.y - p4.y) - fac2 * (p1.y - p2.y)) / divisor);
}
vec4 mapPixelToQuad(vec2 P) {
  vec2 result;
  vec2 ABtoP = cross(vec3(0.0, 1.0, 0.0), vec3(ShadowQuadA.x - ShadowQuadB.x, 0.0, ShadowQuadA.y - ShadowQuadB.y)).xz;
  vec2 CtoD = ShadowQuadD - ShadowQuadC;
  vec2 B1 = LineIntersection(ShadowQuadA, ShadowQuadB, P, P + ABtoP);
  vec2 B2 = LineIntersection(ShadowQuadD, ShadowQuadC, P, P + ABtoP);
  vec2 D1 = LineIntersection(ShadowQuadA, ShadowQuadD, P, P + CtoD);
  vec2 C1 = LineIntersection(ShadowQuadB, ShadowQuadC, P, P + CtoD);
  result.x = distance(D1, P) / distance(D1, C1);
  if (distance(C1, P) > distance(C1, D1) && distance(C1, P) > distance(D1, P))
    result.x = -result.x;
  result.y = distance(B1, P) / distance(B1, B2);
  if (distance(B2, P) > distance(B2, B1) && distance(B2, P) > distance(B1, P))
    result.y = -result.y;
  return vec4(result, 1.0, 1.0);
}

float fetchHeightAtOffset(vec2 O) {
  vec2 TexCoord = 5.0 * (Vertex.xz + O + vec2(0.1, 0.1));
  return texture2D(HeightMap, TexCoord / TerrainSize).a * 256.0;
}

void main(void) {
  BaseVertex = gl_Vertex;
  Vertex = gl_Vertex;
  vec4 no = texture2D(HeightMap, 5.0 * (Vertex.xz + vec2(0.1, 0.1)) / TerrainSize);
  float VY = no.a * 256.0;
  Texture = no.r;
  normal = normalize(
    normalize(cross(vec3(+0.0, fetchHeightAtOffset(vec2(+ 0.0, - 0.2)) - VY, -0.2), vec3(-0.2, fetchHeightAtOffset(vec2(- 0.2, + 0.0)) - VY, +0.0)))
  + normalize(cross(vec3(+0.2, fetchHeightAtOffset(vec2(+ 0.2, + 0.0)) - VY, +0.0), vec3(+0.0, fetchHeightAtOffset(vec2(+ 0.0, - 0.2)) - VY, -0.2)))
  + normalize(cross(vec3(+0.0, fetchHeightAtOffset(vec2(+ 0.0, + 0.2)) - VY, +0.2), vec3(+0.2, fetchHeightAtOffset(vec2(+ 0.2, + 0.0)) - VY, -0.0)))
  + normalize(cross(vec3(-0.2, fetchHeightAtOffset(vec2(- 0.2, + 0.0)) - VY, +0.0), vec3(+0.0, fetchHeightAtOffset(vec2(+ 0.0, + 0.2)) - VY, +0.2))));
  Vertex.xyz += normal * Vertex.y;
  Vertex.y += VY;
  dist = length(gl_ModelViewMatrix * Vertex);
  vec4 LightVec = Vertex - gl_LightSource[0].position;
  gl_TexCoord[7] = mapPixelToQuad(Vertex.xz + LightVec.xz / abs(LightVec.y) * Vertex.y);
  gl_TexCoord[0] = gl_MultiTexCoord0;
  gl_ClipVertex = gl_ModelViewMatrix * Vertex;
  gl_Position = gl_ModelViewProjectionMatrix * Vertex;
}