#version 120

uniform sampler2D HeightMap;
uniform vec2 TerrainSize;

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

const vec4 LODMap = vec4(8.0, 4.0, 1.0, 1.0);

void main(void) {
  Vertex = gl_Vertex;
  rhf = Vertex.y;
  Vertex.xz *= LODMap[LOD];
  Vertex.xz += VOffset;
  Vertex.y = fetchHeightAtOffset(vec2(0.0, 0.0));
  gl_TexCoord[0] = vec4(Vertex.xz * 8.0, 0.0, 1.0);
  dist = distance(gl_LightSource[0].position, Vertex);
  gl_Position = gl_TextureMatrix[0] * Vertex;
//   gl_Position = sqrt(abs(gl_Position)) * sign(gl_Position);
}