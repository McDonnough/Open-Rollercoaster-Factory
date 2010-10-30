#version 120

uniform sampler2D TerrainMap;
uniform sampler2D TerrainTexture;
uniform float TerrainTesselationDistance;
uniform float HeightLine;
uniform vec2 TerrainSize;

varying vec3 Vertex;

float fpart(float a) {
  return a - floor(a);
}

float fetchHeightAtOffset(vec2 O) {
  float result = mix(
          mix(texture2D(TerrainMap, (Vertex.xz + O + vec2(0.0, 0.0)) / TerrainSize).b, texture2D(TerrainMap, (Vertex.xz + O + vec2(0.2, 0.0)) / TerrainSize).b, fpart(5.0 * Vertex.x)),
          mix(texture2D(TerrainMap, (Vertex.xz + O + vec2(0.0, 0.2)) / TerrainSize).b, texture2D(TerrainMap, (Vertex.xz + O + vec2(0.2, 0.2)) / TerrainSize).b, fpart(5.0 * Vertex.x)),
          fpart(5.0 * Vertex.z)) * 256.0;
  return result;
}

void main(void) {
  float VY = fetchHeightAtOffset(vec2(0.0, 0.0));
  vec3 normal = normalize(
    normalize(cross(vec3(+0.0, fetchHeightAtOffset(vec2(+ 0.0, - 0.2)) - VY, -0.2), vec3(-0.2, fetchHeightAtOffset(vec2(- 0.2, + 0.0)) - VY, +0.0)))
  + normalize(cross(vec3(+0.2, fetchHeightAtOffset(vec2(+ 0.2, + 0.0)) - VY, +0.0), vec3(+0.0, fetchHeightAtOffset(vec2(+ 0.0, - 0.2)) - VY, -0.2)))
  + normalize(cross(vec3(+0.0, fetchHeightAtOffset(vec2(+ 0.0, + 0.2)) - VY, +0.2), vec3(+0.2, fetchHeightAtOffset(vec2(+ 0.2, + 0.0)) - VY, -0.0)))
  + normalize(cross(vec3(-0.2, fetchHeightAtOffset(vec2(- 0.2, + 0.0)) - VY, +0.0), vec3(+0.0, fetchHeightAtOffset(vec2(+ 0.0, + 0.2)) - VY, +0.2))));
  gl_FragData[0].rgb = Vertex;
  gl_FragData[0].a = length(gl_ModelViewMatrix * vec4(Vertex, 1.0));
  gl_FragData[1] = vec4(normal, 1.0);
  gl_FragData[2] = vec4(1.0, 1.0, 1.0, 1.0);
}