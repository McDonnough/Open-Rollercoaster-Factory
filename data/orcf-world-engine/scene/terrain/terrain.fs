#version 120

#extension GL_EXT_gpu_shader4 : enable

uniform sampler2D TerrainMap;
uniform sampler2D TerrainTexture;
uniform float TerrainTesselationDistance;
uniform float TerrainBumpmapDistance;
uniform float HeightLine;
uniform vec2 TerrainSize;
uniform vec2 Min;
uniform vec2 Max;
uniform vec2 Camera;
uniform vec2 PointToHighlight;
uniform vec4 NormalMod;
uniform int Border;

varying vec3 Vertex;
varying vec2 FakeVertex;
varying vec3 NormalFactor;
varying float YFactor;

ivec2 iVertex;

mat4 TexCoord;
mat4 texColors = mat4(1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0);
mat4 bumpColors = mat4(1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0);

float fetchHeightAtOffset(ivec2 O) {
  return mix(
    mix(texture2D(TerrainMap, (iVertex + O + ivec2(0, 0)) / TerrainSize / 5.0).b,
        texture2D(TerrainMap, (iVertex + O + ivec2(1, 0)) / TerrainSize / 5.0).b,
        (5.0 * Vertex.x - floor(5.0 * Vertex.x))),
    mix(texture2D(TerrainMap, (iVertex + O + ivec2(0, 1)) / TerrainSize / 5.0).b,
        texture2D(TerrainMap, (iVertex + O + ivec2(1, 1)) / TerrainSize / 5.0).b,
        (5.0 * Vertex.x - floor(5.0 * Vertex.x))),
    (5.0 * Vertex.z - floor(5.0 * Vertex.z))) * 256.0;
}

void main(void) {
  gl_FragData[3] = vec4(0.0, 0.0, 0.0, 1.0);
//   if (clamp(Vertex.xz, vec2(0.0, 0.0), TerrainSize) != Vertex.xz && Border != 1)
//     discard;

  // IF [ EQ owe.terrain.tesselation 1 ]
  if (Vertex.x > 1.0 && Vertex.z > 1.0 && Vertex.x < TerrainSize.x - 1.0 && Vertex.z < TerrainSize.y - 1.0)
    if (Border == 0 && max(abs(Camera.x - Vertex.x), abs(Camera.y - Vertex.z)) < TerrainTesselationDistance - 2.0)
      discard;
  // END

  iVertex = ivec2(floor(5.0 * FakeVertex + 0.001));

  float VY = mix(64.0, fetchHeightAtOffset(ivec2(0, 0)), YFactor);

  gl_FragData[2].rgb = Vertex;
  gl_FragData[2].a = length(gl_ModelViewMatrix * vec4(Vertex, 1.0));

  float TexIDs[4];
  TexIDs[0] = texture2D(TerrainMap, (iVertex + ivec2(0, 0)) / TerrainSize / 5.0).r * 65536.0;
  TexIDs[1] = texture2D(TerrainMap, (iVertex + ivec2(1, 0)) / TerrainSize / 5.0).r * 65536.0;
  TexIDs[2] = texture2D(TerrainMap, (iVertex + ivec2(0, 1)) / TerrainSize / 5.0).r * 65536.0;
  TexIDs[3] = texture2D(TerrainMap, (iVertex + ivec2(1, 1)) / TerrainSize / 5.0).r * 65536.0;

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
    normalize(cross(vec3(+0.0, mix(0.0, fetchHeightAtOffset(ivec2(+0, -1)) - VY, YFactor), -0.2), vec3(-0.2, mix(0.0, fetchHeightAtOffset(ivec2(-1, +0)) - VY, YFactor), +0.0)))
  + normalize(cross(vec3(+0.2, mix(0.0, fetchHeightAtOffset(ivec2(+1, +0)) - VY, YFactor), +0.0), vec3(+0.0, mix(0.0, fetchHeightAtOffset(ivec2(+0, -1)) - VY, YFactor), -0.2)))
  + normalize(cross(vec3(+0.0, mix(0.0, fetchHeightAtOffset(ivec2(+0, +1)) - VY, YFactor), +0.2), vec3(+0.2, mix(0.0, fetchHeightAtOffset(ivec2(+1, +0)) - VY, YFactor), -0.0)))
  + normalize(cross(vec3(-0.2, mix(0.0, fetchHeightAtOffset(ivec2(-1, +0)) - VY, YFactor), +0.0), vec3(+0.0, mix(0.0, fetchHeightAtOffset(ivec2(+0, +1)) - VY, YFactor), +0.2))));
  normal = normalize(mix(normal * NormalFactor, NormalMod.xyz, NormalMod.a));

  // IF [ EQ owe.terrain.bumpmap 1 ]
  if (gl_FragData[2].a < TerrainBumpmapDistance) {
    bumpColors = mat4(
      texture2D(TerrainTexture, clamp((Vertex.xz / 8.0 - floor(Vertex.xz / 8.0)), 1.0 / 512.0, 1.0 - 1.0 / 512.0) / 4.0 + TexCoord[0].xy + vec2(0.0, 0.5)),
      texture2D(TerrainTexture, clamp((Vertex.xz / 8.0 - floor(Vertex.xz / 8.0)), 1.0 / 512.0, 1.0 - 1.0 / 512.0) / 4.0 + TexCoord[1].xy + vec2(0.0, 0.5)),
      texture2D(TerrainTexture, clamp((Vertex.xz / 8.0 - floor(Vertex.xz / 8.0)), 1.0 / 512.0, 1.0 - 1.0 / 512.0) / 4.0 + TexCoord[2].xy + vec2(0.0, 0.5)),
      texture2D(TerrainTexture, clamp((Vertex.xz / 8.0 - floor(Vertex.xz / 8.0)), 1.0 / 512.0, 1.0 - 1.0 / 512.0) / 4.0 + TexCoord[3].xy + vec2(0.0, 0.5)));
    vec3 bumpNormal = -1.0 + 2.0 * (mix(mix(bumpColors[0], bumpColors[1], (FakeVertex.x * 5.0 - floor(FakeVertex.x * 5.0))), mix(bumpColors[2], bumpColors[3], (FakeVertex.x * 5.0 - floor(FakeVertex.x * 5.0))), (FakeVertex.y * 5.0 - floor(FakeVertex.y * 5.0)))).rbg;
    float angle = acos(normal.x);
    vec3 tangent = normalize(vec3(sin(angle), -cos(angle), 0.0));
    vec3 bitangent = normalize(cross(normal, tangent));
    normal = normalize(mix(normal, normalize(tangent * bumpNormal.x + normal * bumpNormal.y + bitangent * bumpNormal.z), clamp((TerrainBumpmapDistance - gl_FragData[2].a) / (TerrainBumpmapDistance / 2.0), 0.0, 1.0)));
  }
  // END

  gl_FragData[1] = vec4(normal, 2.0);
  gl_FragData[0] = mix(mix(texColors[0], texColors[1], (FakeVertex.x * 5.0 - floor(FakeVertex.x * 5.0))), mix(texColors[2], texColors[3], (FakeVertex.x * 5.0 - floor(FakeVertex.x * 5.0))), (FakeVertex.y * 5.0 - floor(FakeVertex.y * 5.0)));
  gl_FragData[0].a = 0.02;
  gl_FragData[0].rgb *= clamp(1.0 + 0.8 * dot(normal, normalize(gl_LightSource[0].position.xyz - Vertex)), 0.0, 1.0);
  float lf1 = clamp(pow(abs(VY - HeightLine) * 10.0, 4.0), 0.0, 1.0);
  float lf2 = clamp(1.0 - min(1.0, 1.0 - min(20.0 * abs(Vertex.x - PointToHighlight.x), 1.0) + 1.0 - min(20.0 * abs(Vertex.z - PointToHighlight.y), 1.0)), 0.0, 1.0);
  gl_FragData[0].rgb = mix(vec3(0.0, 1.0, 1.0), gl_FragData[0].rgb, lf1);
  gl_FragData[0].rgb = mix(vec3(0.0, 1.0, 1.0), gl_FragData[0].rgb, lf2);
  if (clamp(Vertex.xz, Min, Max) != Vertex.xz)
    gl_FragData[0].rgb *= 0.5;
  gl_FragData[0].a = mix(-0.5, gl_FragData[0].a, lf1);
  gl_FragData[0].a = mix(-0.5, gl_FragData[0].a, lf2);
}