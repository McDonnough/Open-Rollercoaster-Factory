#version 120

uniform sampler2D HeightMap;
uniform vec2 TerrainSize;

varying float dist;
varying float SDist;
varying vec4 result;
varying vec4 Vertex;
varying vec4 BaseVertex;
varying vec3 normal;

float fpart(float a) {
  return a - floor(a);
}

float fetchHeightAtOffset(vec2 O) {
  vec2 TexCoord = 5.0 * (Vertex.xz + O + vec2(0.1, 0.1));
  return texture2D(HeightMap, TexCoord / TerrainSize).a * 256.0;
}

void main(void) {
  BaseVertex = gl_Vertex;
  Vertex = gl_Vertex;
  float VY = fetchHeightAtOffset(vec2(0.0, 0.0));
  normal = normalize(
    normalize(cross(vec3(+0.0, fetchHeightAtOffset(vec2(+ 0.0, - 0.2)) - VY, -0.2), vec3(-0.2, fetchHeightAtOffset(vec2(- 0.2, + 0.0)) - VY, +0.0)))
  + normalize(cross(vec3(+0.2, fetchHeightAtOffset(vec2(+ 0.2, + 0.0)) - VY, +0.0), vec3(+0.0, fetchHeightAtOffset(vec2(+ 0.0, - 0.2)) - VY, -0.2)))
  + normalize(cross(vec3(+0.0, fetchHeightAtOffset(vec2(+ 0.0, + 0.2)) - VY, +0.2), vec3(+0.2, fetchHeightAtOffset(vec2(+ 0.2, + 0.0)) - VY, -0.0)))
  + normalize(cross(vec3(-0.2, fetchHeightAtOffset(vec2(- 0.2, + 0.0)) - VY, +0.0), vec3(+0.0, fetchHeightAtOffset(vec2(+ 0.0, + 0.2)) - VY, +0.2))));
  Vertex.xyz += normal * Vertex.y;
  Vertex.y += VY;
  dist = length(gl_ModelViewMatrix * Vertex);
  result = gl_TextureMatrix[0] * Vertex;
  result = sqrt(abs(result)) * sign(result);
  SDist = distance(gl_LightSource[0].position, Vertex);
  gl_TexCoord[0] = gl_MultiTexCoord0;
  gl_ClipVertex = gl_ModelViewMatrix * Vertex;
  gl_Position = gl_ModelViewProjectionMatrix * Vertex;
}