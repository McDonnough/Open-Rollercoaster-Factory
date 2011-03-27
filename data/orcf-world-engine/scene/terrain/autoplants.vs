#version 120

uniform sampler2D TerrainMap;
uniform vec2 TerrainSize;
uniform vec2 BumpOffset;

varying vec3 normal;
varying vec3 Vertex;
varying vec2 texCoord;

float fetchHeightAtOffset(vec2 O) {
  return texture2D(TerrainMap, (gl_Vertex.xy + O) / TerrainSize).b * 256.0;
}

void main(void) {
  float VY = fetchHeightAtOffset(vec2(0.0, 0.0));
  normal = normalize(
    normalize(cross(vec3(+0.0, fetchHeightAtOffset(vec2(+0.0, -0.2)) - VY, -0.2), vec3(-0.2, fetchHeightAtOffset(vec2(-0.2, +0.0)) - VY, +0.0)))
  + normalize(cross(vec3(+0.2, fetchHeightAtOffset(vec2(+0.2, +0.0)) - VY, +0.0), vec3(+0.0, fetchHeightAtOffset(vec2(+0.0, -0.2)) - VY, -0.2)))
  + normalize(cross(vec3(+0.0, fetchHeightAtOffset(vec2(+0.0, +0.2)) - VY, +0.2), vec3(+0.2, fetchHeightAtOffset(vec2(+0.2, +0.0)) - VY, -0.0)))
  + normalize(cross(vec3(-0.2, fetchHeightAtOffset(vec2(-0.2, +0.0)) - VY, +0.0), vec3(+0.0, fetchHeightAtOffset(vec2(+0.0, +0.2)) - VY, +0.2))));

  Vertex = vec3(gl_Vertex.x, VY, gl_Vertex.y) + gl_Vertex.z * 0.8 * normal;
  texCoord = gl_MultiTexCoord0.xy;
  Vertex.xz += (1.0 - texCoord.y) * vec2(0.1 * sin(0.1 * (Vertex.x + Vertex.z) + BumpOffset.x + BumpOffset.y), 0.03 * sin(0.1 * (Vertex.x + Vertex.z) + BumpOffset.x + BumpOffset.y));
  gl_ClipVertex = gl_ModelViewMatrix * vec4(Vertex, 1.0);
  gl_Position = gl_ModelViewProjectionMatrix * vec4(Vertex, 1.0);
}