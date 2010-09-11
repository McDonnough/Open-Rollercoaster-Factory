#version 120

uniform sampler2D HeightMap;
uniform vec2 TerrainSize;

uniform vec2 offset;
uniform vec2 VOffset;
uniform int LOD;

uniform vec3 ShadowQuadA;
uniform vec3 ShadowQuadB;
uniform vec3 ShadowQuadC;
uniform vec3 ShadowQuadD;

varying float dist;

vec4 Vertex;
float rhf;

vec2 LineIntersection(vec2 p1, vec2 p2, vec2 p3, vec2 p4) {
  float divisor = (p1.x - p2.x) * (p3.y - p4.y) - (p1.y - p2.y) * (p3.x - p4.x);
  float fac1 = p1.x * p2.y - p1.y * p2.x;
  float fac2 = p3.x * p4.y - p3.y * p4.x;
  return vec2((fac1 * (p3.x - p4.x) - fac2 * (p1.x - p2.x)) / divisor,
              (fac1 * (p3.y - p4.y) - fac2 * (p1.y - p2.y)) / divisor);
}
vec4 mapPixelToQuad(vec2 P) {
  vec2 result = P / 204.8;
  result *= 2.0;
  result -= 1.0;
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
  rhf = Vertex.y;
  Vertex.xz *= LODMap[LOD];
  Vertex.xz += VOffset;
  Vertex.y = fetchHeightAtOffset(vec2(0.0, 0.0));
  gl_TexCoord[0] = vec4(Vertex.xz * 8.0, 0.0, 1.0);
  dist = Vertex.y;
  vec4 LightVec = Vertex - gl_LightSource[0].position;
  gl_Position = mapPixelToQuad(Vertex.xz + LightVec.xz / abs(LightVec.y) * Vertex.y);
//   gl_Position = gl_TextureMatrix[0] * Vertex;
//   gl_Position = sqrt(abs(gl_Position)) * sign(gl_Position);
}