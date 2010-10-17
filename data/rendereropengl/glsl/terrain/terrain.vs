#version 120

uniform sampler2D HeightMap;
uniform vec2 TerrainSize;

uniform vec2 offset;
uniform vec2 VOffset;
uniform vec2 Scale;
uniform int LOD;

uniform vec2 ShadowQuadA;
uniform vec2 ShadowQuadB;
uniform vec2 ShadowQuadC;
uniform vec2 ShadowQuadD;

varying vec4 Vertex;
varying vec4 DVertex;

varying float rhf;

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
  float result = texture2D(HeightMap, TexCoord / TerrainSize).a * 256.0;
  result = mix(64.0, result, (0.5 - 0.5 * cos(3.141 * pow(1.0 - rhf, 5.0))));
  return result;
}

const vec4 LODMap = vec4(8.0, 4.0, 1.0, 1.0);

void main(void) {
  Vertex = gl_Vertex;
  Vertex.xz *= Scale;
  rhf = Vertex.y;
  Vertex.xz *= LODMap[LOD];
  Vertex.xz += VOffset;
  Vertex.y = fetchHeightAtOffset(vec2(0.0, 0.0));
  gl_TexCoord[0] = vec4(Vertex.xz * 8.0, 0.0, 1.0);
  gl_ClipVertex = gl_ModelViewMatrix * Vertex;
  DVertex = gl_ClipVertex;
  vec4 LightVec = Vertex - gl_LightSource[0].position;
  gl_TexCoord[7] = mix(vec4(-1.0,-1.0, 0.0, 0.0), mapPixelToQuad(Vertex.xz + LightVec.xz / abs(LightVec.y) * Vertex.y), min(1.0, 3.0 - LOD));
  gl_Position = gl_ModelViewProjectionMatrix * Vertex;
}