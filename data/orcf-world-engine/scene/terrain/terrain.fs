#version 120

#extension GL_EXT_gpu_shader4 : require

uniform sampler2D TerrainMap;
uniform sampler2DArray TerrainTexture;
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
ivec2 iTerrainSize;

float fetchHeightAtOffset(vec2 O) {
  return 256.0 * texture2D(TerrainMap, (Vertex.xz + O) / TerrainSize).b;
}

void main(void) {
  gl_FragData[5] = vec4(0.0, 0.0, 0.0, 5.0);
  gl_FragData[4] = vec4(0.0, 0.0, 0.0, 0.0);

  gl_FragData[3] = vec4(0.0, 0.0, 0.0, 1.0);
//   if (clamp(Vertex.xz, vec2(0.0, 0.0), TerrainSize) != Vertex.xz && Border != 1)
//     discard;

  // IF [ EQ owe.terrain.tesselation 1 ]
  if (Vertex.x > 1.0 && Vertex.z > 1.0 && Vertex.x < TerrainSize.x - 1.0 && Vertex.z < TerrainSize.y - 1.0)
    if (Border == 0 && max(abs(Camera.x - Vertex.x), abs(Camera.y - Vertex.z)) < TerrainTesselationDistance - 2.0)
      discard;
  // END

  iVertex = ivec2(floor(5.0 * FakeVertex));
  iTerrainSize = ivec2(floor(5.0 * TerrainSize)) - 1;

  float VY = mix(64.0, fetchHeightAtOffset(ivec2(0, 0)), YFactor);

  gl_FragData[2].rgb = Vertex;
  gl_FragData[2].a = length(vec3(gl_ModelViewMatrix * vec4(Vertex, 1.0)));

  float TexIDs[4];
  TexIDs[0] = texelFetch2DOffset(TerrainMap, iVertex, 0, ivec2(0, 0)).r * 65536.0;
  TexIDs[1] = texelFetch2DOffset(TerrainMap, iVertex, 0, ivec2(1, 0)).r * 65536.0;
  TexIDs[2] = texelFetch2DOffset(TerrainMap, iVertex, 0, ivec2(0, 1)).r * 65536.0;
  TexIDs[3] = texelFetch2DOffset(TerrainMap, iVertex, 0, ivec2(1, 1)).r * 65536.0;

  vec3 texColors[4];
  texColors[0] = texture2DArray(TerrainTexture, vec3(Vertex.xz / 48.0, TexIDs[0])).rgb;
  texColors[1] = texture2DArray(TerrainTexture, vec3(Vertex.xz / 48.0, TexIDs[1])).rgb;
  texColors[2] = texture2DArray(TerrainTexture, vec3(Vertex.xz / 48.0, TexIDs[2])).rgb;
  texColors[3] = texture2DArray(TerrainTexture, vec3(Vertex.xz / 48.0, TexIDs[3])).rgb;

  float heightLevels[4];
  heightLevels[0] = fetchHeightAtOffset(vec2( 0.0, -0.2));
  heightLevels[1] = fetchHeightAtOffset(vec2(-0.2,  0.0));
  heightLevels[2] = fetchHeightAtOffset(vec2( 0.2,  0.0));
  heightLevels[3] = fetchHeightAtOffset(vec2( 0.0,  0.2));

  vec3 normal = normalize(
    normalize(cross(vec3(+0.0, mix(0.0, heightLevels[0] - VY, YFactor), -0.2), vec3(-0.2, mix(0.0, heightLevels[1] - VY, YFactor), +0.0)))
  + normalize(cross(vec3(+0.2, mix(0.0, heightLevels[2] - VY, YFactor), +0.0), vec3(+0.0, mix(0.0, heightLevels[0] - VY, YFactor), -0.2)))
  + normalize(cross(vec3(+0.0, mix(0.0, heightLevels[3] - VY, YFactor), +0.2), vec3(+0.2, mix(0.0, heightLevels[2] - VY, YFactor), -0.0)))
  + normalize(cross(vec3(-0.2, mix(0.0, heightLevels[1] - VY, YFactor), +0.0), vec3(+0.0, mix(0.0, heightLevels[3] - VY, YFactor), +0.2))));
  normal = normalize(mix(normal * NormalFactor, NormalMod.xyz, NormalMod.a));

  // IF [ EQ owe.terrain.bumpmap 1 ]
  vec3 bumpColors[4];
  if (gl_FragData[2].a < TerrainBumpmapDistance) {
    bumpColors[0] = texture2DArray(TerrainTexture, vec3(Vertex.xz / 3.0, 8.0 + TexIDs[0])).rgb;
    bumpColors[1] = texture2DArray(TerrainTexture, vec3(Vertex.xz / 3.0, 8.0 + TexIDs[1])).rgb;
    bumpColors[2] = texture2DArray(TerrainTexture, vec3(Vertex.xz / 3.0, 8.0 + TexIDs[2])).rgb;
    bumpColors[3] = texture2DArray(TerrainTexture, vec3(Vertex.xz / 3.0, 8.0 + TexIDs[3])).rgb;
    vec3 bumpNormal = -1.0 + 2.0 * (mix(mix(bumpColors[0], bumpColors[1], (FakeVertex.x * 5.0 - floor(FakeVertex.x * 5.0))), mix(bumpColors[2], bumpColors[3], (FakeVertex.x * 5.0 - floor(FakeVertex.x * 5.0))), (FakeVertex.y * 5.0 - floor(FakeVertex.y * 5.0)))).rbg;
    float angle = acos(normal.x);
    vec3 tangent = normalize(vec3(sin(angle), -cos(angle), 0.0));
    vec3 bitangent = normalize(cross(normal, tangent));
    normal = normalize(mix(normal, normalize(tangent * bumpNormal.x + normal * bumpNormal.y + bitangent * bumpNormal.z), clamp((TerrainBumpmapDistance - gl_FragData[2].a) / (TerrainBumpmapDistance / 2.0), 0.0, 1.0)));
  }
  // END

  gl_FragData[1] = vec4(normal, 2.0);
  gl_FragData[0].rgb = mix(mix(texColors[0], texColors[1], (FakeVertex.x * 5.0 - floor(FakeVertex.x * 5.0))), mix(texColors[2], texColors[3], (FakeVertex.x * 5.0 - floor(FakeVertex.x * 5.0))), (FakeVertex.y * 5.0 - floor(FakeVertex.y * 5.0)));
  gl_FragData[0].a = 0.0;
  gl_FragData[0].rgb *= clamp(1.0 + 0.8 * dot(normal, normalize(gl_LightSource[0].position.xyz - Vertex)), 0.0, 1.0);
/*  float lf1 = clamp(pow(abs(VY - HeightLine) * 10.0, 4.0), 0.0, 1.0);
  float lf2 = clamp(1.0 - min(1.0, 1.0 - min(20.0 * abs(Vertex.x - PointToHighlight.x), 1.0) + 1.0 - min(20.0 * abs(Vertex.z - PointToHighlight.y), 1.0)), 0.0, 1.0);
  gl_FragData[0].rgb = mix(vec3(0.0, 1.0, 1.0), gl_FragData[0].rgb, lf1);
  gl_FragData[0].rgb = mix(vec3(0.0, 1.0, 1.0), gl_FragData[0].rgb, lf2);
  gl_FragData[5].rgb = mix(vec3(1.0, 1.0, 1.0), gl_FragData[5].rgb, lf1);
  gl_FragData[5].rgb = mix(vec3(1.0, 1.0, 1.0), gl_FragData[5].rgb, lf2);
  if (clamp(Vertex.xz, Min, Max) != Vertex.xz)
    gl_FragData[0].rgb *= 0.5;
  gl_FragData[0].a = mix(0.0, gl_FragData[0].a, lf1);
  gl_FragData[0].a = mix(0.0, gl_FragData[0].a, lf2);*/
}