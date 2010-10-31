#version 120

#extension GL_EXT_gpu_shader4 : enable

uniform sampler2D TerrainMap;
uniform sampler2D TerrainTexture;
uniform float TerrainTesselationDistance;
uniform float TerrainBumpmapDistance;
uniform float HeightLine;
uniform vec2 TerrainSize;

varying vec3 Vertex;

ivec2 iVertex;

mat4 TexCoord;
mat4 texColors = mat4(1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0);
mat4 bumpColors = mat4(1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0);

float fetchHeightAtOffset(ivec2 O) {
  return mix(
    mix(texelFetch2DOffset(TerrainMap, iVertex, 0, O + ivec2(0, 0)).b,
        texelFetch2DOffset(TerrainMap, iVertex, 0, O + ivec2(1, 0)).b,
        (5.0 * Vertex.x - floor(5.0 * Vertex.x))),
    mix(texelFetch2DOffset(TerrainMap, iVertex, 0, O + ivec2(0, 1)).b,
        texelFetch2DOffset(TerrainMap, iVertex, 0, O + ivec2(1, 1)).b,
        (5.0 * Vertex.x - floor(5.0 * Vertex.x))),
    (5.0 * Vertex.z - floor(5.0 * Vertex.z))) * 256.0;
}

void main(void) {
  iVertex = ivec2(floor(5.0 * Vertex.xz + 0.001));

  gl_FragData[0].rgb = Vertex;
  gl_FragData[0].a = length(gl_ModelViewMatrix * vec4(Vertex, 1.0));

  float TexIDs[4];
  TexIDs[0] = texelFetch2DOffset(TerrainMap, iVertex, 0, ivec2(0, 0)).r * 65536.0;
  TexIDs[1] = texelFetch2DOffset(TerrainMap, iVertex, 0, ivec2(1, 0)).r * 65536.0;
  TexIDs[2] = texelFetch2DOffset(TerrainMap, iVertex, 0, ivec2(0, 1)).r * 65536.0;
  TexIDs[3] = texelFetch2DOffset(TerrainMap, iVertex, 0, ivec2(1, 1)).r * 65536.0;

  float VY = fetchHeightAtOffset(ivec2(0, 0));
  TexCoord = mat4(
    vec4((TexIDs[0] / 4.0 - floor(TexIDs[0] / 4.0)), floor(TexIDs[0] / 4.0) / 4.0, 0.0, 1.0),
    vec4((TexIDs[1] / 4.0 - floor(TexIDs[1] / 4.0)), floor(TexIDs[1] / 4.0) / 4.0, 0.0, 1.0),
    vec4((TexIDs[2] / 4.0 - floor(TexIDs[2] / 4.0)), floor(TexIDs[2] / 4.0) / 4.0, 0.0, 1.0),
    vec4((TexIDs[3] / 4.0 - floor(TexIDs[3] / 4.0)), floor(TexIDs[3] / 4.0) / 4.0, 0.0, 1.0));
  texColors = mat4(
    texture2D(TerrainTexture, clamp((Vertex.xz / 32.0 - floor(Vertex.xz / 32.0)), 1.0 / 512.0, 1.0 - 1.0 / 512.0) / 4.0 + TexCoord[0].xy),
    texture2D(TerrainTexture, clamp((Vertex.xz / 32.0 - floor(Vertex.xz / 32.0)), 1.0 / 512.0, 1.0 - 1.0 / 512.0) / 4.0 + TexCoord[1].xy),
    texture2D(TerrainTexture, clamp((Vertex.xz / 32.0 - floor(Vertex.xz / 32.0)), 1.0 / 512.0, 1.0 - 1.0 / 512.0) / 4.0 + TexCoord[2].xy),
    texture2D(TerrainTexture, clamp((Vertex.xz / 32.0 - floor(Vertex.xz / 32.0)), 1.0 / 512.0, 1.0 - 1.0 / 512.0) / 4.0 + TexCoord[3].xy));
  vec3 normal = normalize(
    normalize(cross(vec3(+0.0, fetchHeightAtOffset(ivec2(+0, -1)) - VY, -0.2), vec3(-0.2, fetchHeightAtOffset(ivec2(-1, +0)) - VY, +0.0)))
  + normalize(cross(vec3(+0.2, fetchHeightAtOffset(ivec2(+1, +0)) - VY, +0.0), vec3(+0.0, fetchHeightAtOffset(ivec2(+0, -1)) - VY, -0.2)))
  + normalize(cross(vec3(+0.0, fetchHeightAtOffset(ivec2(+0, +1)) - VY, +0.2), vec3(+0.2, fetchHeightAtOffset(ivec2(+1, +0)) - VY, -0.0)))
  + normalize(cross(vec3(-0.2, fetchHeightAtOffset(ivec2(-1, +0)) - VY, +0.0), vec3(+0.0, fetchHeightAtOffset(ivec2(+0, +1)) - VY, +0.2))));

  if (gl_FragData[0].a < TerrainBumpmapDistance) {
    bumpColors = mat4(
      texture2D(TerrainTexture, clamp((Vertex.xz / 8.0 - floor(Vertex.xz / 8.0)), 1.0 / 512.0, 1.0 - 1.0 / 512.0) / 4.0 + TexCoord[0].xy + vec2(0.0, 0.5)),
      texture2D(TerrainTexture, clamp((Vertex.xz / 8.0 - floor(Vertex.xz / 8.0)), 1.0 / 512.0, 1.0 - 1.0 / 512.0) / 4.0 + TexCoord[1].xy + vec2(0.0, 0.5)),
      texture2D(TerrainTexture, clamp((Vertex.xz / 8.0 - floor(Vertex.xz / 8.0)), 1.0 / 512.0, 1.0 - 1.0 / 512.0) / 4.0 + TexCoord[2].xy + vec2(0.0, 0.5)),
      texture2D(TerrainTexture, clamp((Vertex.xz / 8.0 - floor(Vertex.xz / 8.0)), 1.0 / 512.0, 1.0 - 1.0 / 512.0) / 4.0 + TexCoord[3].xy + vec2(0.0, 0.5)));
    vec3 bumpNormal = -1.0 + 2.0 * (mix(mix(bumpColors[0], bumpColors[1], (Vertex.x * 5.0 - floor(Vertex.x * 5.0))), mix(bumpColors[2], bumpColors[3], (Vertex.x * 5.0 - floor(Vertex.x * 5.0))), (Vertex.z * 5.0 - floor(Vertex.z * 5.0)))).rbg;
    float angle = acos(normal.x);
    vec3 tangent = normalize(vec3(sin(angle), -cos(angle), 0.0));
    vec3 bitangent = normalize(cross(normal, tangent));
    normal = normalize(mix(normal, normalize(tangent * bumpNormal.x + normal * bumpNormal.y + bitangent * bumpNormal.z), clamp((TerrainBumpmapDistance - gl_FragData[0].a) / (TerrainBumpmapDistance / 2.0), 0.0, 1.0)));
  }

  gl_FragData[1] = vec4(normal, 2.0);
  gl_FragData[2] = mix(mix(texColors[0], texColors[1], (Vertex.x * 5.0 - floor(Vertex.x * 5.0))), mix(texColors[2], texColors[3], (Vertex.x * 5.0 - floor(Vertex.x * 5.0))), (Vertex.z * 5.0 - floor(Vertex.z * 5.0)));
  gl_FragData[2].a = 0.5;
  gl_FragData[2].rgb *= clamp(1.0 + 0.8 * dot(normal, normalize(gl_LightSource[0].position.xyz - Vertex)), 0.0, 1.0);
}