#version 120

uniform sampler2D HeightMap;
uniform vec2 TerrainSize;

uniform vec2 ShadowQuadA;
uniform vec2 ShadowQuadB;
uniform vec2 ShadowQuadC;
uniform vec2 ShadowQuadD;

uniform vec2 offset;
uniform vec2 VOffset;
uniform int LOD;

varying float dist;

vec4 Vertex;
float rhf;

float fetchHeightAtOffset(vec2 O) {
  vec2 TexCoord = 5.0 * (Vertex.xz + O + vec2(0.1, 0.1));
  float result = texture2D(HeightMap, TexCoord / TerrainSize).a * 256.0;
  result = mix(64.0, result, (0.5 - 0.5 * cos(3.141 * pow(1.0 - rhf, 5.0))));
  return result;
}

vec2 LineLineIntersection(vec2 p1, vec2 p2, vec2 p3, vec2 p4) {
  return vec2(
    ((p1.x * p2.y - p1.y * p2.x) * (p3.x - p4.x) - (p1.x - p2.x) * (p3.x * p4.y - p3.y * p4.x)) / ((p1.x - p2.x) * (p3.y - p4.y) - (p1.y - p2.y) * (p3.x - p4.x)),
    ((p1.x * p2.y - p1.y * p2.x) * (p3.y - p4.y) - (p1.y - p2.y) * (p3.x * p4.y - p3.y * p4.x)) / ((p1.x - p2.x) * (p3.y - p4.y) - (p1.y - p2.y) * (p3.x - p4.x)));
}

vec2 ShadowTransformPointToQuad(vec2 Point) {
//   return -1.0 + 2.0 * Point / 204.8;
  vec2 Orth = cross(vec3(0.0, 0.0, 1.0), vec3(ShadowQuadA - ShadowQuadB, 0.0)).xy;
  vec2 d1 = LineLineIntersection(ShadowQuadA, ShadowQuadD, Point, Point + ShadowQuadB - ShadowQuadA);
  vec2 c1 = LineLineIntersection(ShadowQuadB, ShadowQuadC, Point, Point + ShadowQuadB - ShadowQuadA);
  vec2 b1 = LineLineIntersection(ShadowQuadA, ShadowQuadB, Point, Point - Orth);
  vec2 b2 = LineLineIntersection(ShadowQuadC, ShadowQuadD, Point, Point - Orth);
  vec2 result = vec2(distance(d1, Point) / distance(d1, c1), distance(b1, Point) / distance(b1, b2));
  return -1.0 + 2.0 * result;
}

const vec4 LODMap = vec4(8.0, 4.0, 1.0, 1.0);

void main(void) {
  Vertex = gl_Vertex;
  rhf = Vertex.y;
  Vertex.xz *= LODMap[LOD];
  Vertex.xz += VOffset;
  Vertex.y = fetchHeightAtOffset(vec2(0.0, 0.0));
  gl_TexCoord[0] = vec4(Vertex.xz * 8.0, 0.0, 1.0);
  vec3 LightVec = Vertex.xyz - gl_LightSource[0].position.xyz;
  dist = length(LightVec);
  gl_Position.xy = ShadowTransformPointToQuad((Vertex.xyz - Vertex.y * LightVec / LightVec.y).xz);
  gl_Position.zw = vec2(1.0, 1.0);
//   gl_Position = sqrt(abs(gl_Position)) * sign(gl_Position);
}