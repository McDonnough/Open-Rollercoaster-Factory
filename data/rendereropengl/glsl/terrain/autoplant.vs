#version 120

uniform sampler2D HeightMap;
uniform vec2 TerrainSize;
uniform float TexToDo;

varying float dist;
varying vec4 result;
varying vec4 Vertex;
varying vec4 BaseVertex;
varying vec3 normal;
varying float Texture;

float fpart(float a) {
  return a - floor(a);
}

vec4 mapPixelToQuad(vec2 P) {
  vec2 result = P / 204.8;
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