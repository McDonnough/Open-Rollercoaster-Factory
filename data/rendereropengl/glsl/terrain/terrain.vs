#version 120

uniform sampler2D HeightMap;
uniform vec2 TerrainSize;

uniform vec2 offset;
uniform vec2 VOffset;
uniform int LOD;

varying float dist;
varying float SDist;
varying float diff;
varying vec4 Vertex;
varying vec4 DVertex;

float fetchHeightAtOffset(vec2 O) {
  vec2 TexCoord = 5.0 * (Vertex.xz + O + vec2(0.1, 0.1));
  return texture2D(HeightMap, TexCoord / TerrainSize).a * 256.0;
}

const vec4 LODMap = vec4(8.0, 4.0, 1.0, 1.0);

void main(void) {
  Vertex = gl_Vertex;
  Vertex.xz *= LODMap[LOD];
  Vertex.xz += VOffset;
  Vertex.y = fetchHeightAtOffset(vec2(0.0, 0.0));
  gl_TexCoord[1] = vec4(0.0, 0.0, 0.0, 0.0);
  if (LOD == 3) {
    gl_TexCoord[1] = gl_MultiTexCoord0;
    Vertex.xz += gl_TexCoord[1].xy;
  }
  gl_TexCoord[0] = vec4(Vertex.xz * 8.0, 0.0, 1.0);
  diff = (Vertex.y - texture2D(HeightMap, (5.0 * (Vertex.xz + vec2(0.1, 0.1))) / TerrainSize).g * 256.0);
  gl_ClipVertex = gl_ModelViewMatrix * Vertex;
  DVertex = gl_ClipVertex;
  gl_Position = gl_ModelViewProjectionMatrix * Vertex;
}