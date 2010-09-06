#version 120

uniform sampler2D TerrainTexture;
uniform sampler2D HeightMap;
uniform sampler2D SunShadowMap;
uniform int LOD;
uniform vec2 offset;
uniform float maxBumpDistance;
uniform vec2 TerrainSize;
uniform vec2 PointToHighlight;
uniform float HeightLineToHighlight;
uniform vec2 Min;
uniform vec2 Max;
uniform float NFactor;

varying float SDist;
varying vec4 Vertex;
varying vec2 fragCoord;
varying vec4 DVertex;
varying float rhf;

mat4 TexCoord;
mat4 texColors = mat4(1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0);
mat4 bumpColors = mat4(1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0);

vec4 Diffuse = vec4(0.0, 0.0, 0.0, 1.0);
vec4 Ambient = vec4(0.0, 0.0, 0.0, 1.0);
vec3 normal = vec3(0.0, 1.0, 0.0);

void AddLight(int ID) {
  vec3 DistVector = gl_LightSource[ID].position.xyz - Vertex.xyz;
  float lnrDistVector = max(0.5, DistVector.x * DistVector.x + DistVector.y * DistVector.y + DistVector.z * DistVector.z);
  Diffuse += gl_LightSource[ID].diffuse * gl_LightSource[ID].diffuse.a * dot(normal, normalize(DistVector)) * gl_LightSource[ID].position.w * gl_LightSource[ID].position.w / lnrDistVector;
}

float fpart(float a) {
  return a - floor(a);
}

vec2 trunc(vec2 a) {
  return a - floor(a);
}

vec2 getRightTexCoord(float fac) {
  vec2 result = clamp(trunc(gl_TexCoord[0].xy * 2.0 * fac), 1.0 / 512.0, 1.0 - 1.0 / 512.0) / 4.0;
  vec2 iparts = gl_TexCoord[0].xy * 4.0 * fac - trunc(gl_TexCoord[0].xy * 4.0 * fac);
  return result;
}

vec4 processTexCoord(float texID) {
  return vec4(fpart(texID / 4.0), floor(texID / 4.0) / 4.0, 0.0, 1.0);
}

float fetchHeightAtOffset(vec2 O) {
  float result = mix(
          mix(texture2D(HeightMap, 5.0 * (Vertex.xz + O + vec2(0.0, 0.0)) / TerrainSize).a, texture2D(HeightMap, 5.0 * (Vertex.xz + O + vec2(0.2, 0.0)) / TerrainSize).a, fpart(5.0 * Vertex.x)),
          mix(texture2D(HeightMap, 5.0 * (Vertex.xz + O + vec2(0.0, 0.2)) / TerrainSize).a, texture2D(HeightMap, 5.0 * (Vertex.xz + O + vec2(0.2, 0.2)) / TerrainSize).a, fpart(5.0 * Vertex.x)),
          fpart(5.0 * Vertex.z)) * 256.0;
  result = mix(64.0, result, (0.5 - 0.5 * cos(3.141 * pow(1.0 - rhf, 5.0))));
  return result;
}

vec4 fetchTextureColor(int id) {
  return texColors[id];
}

void main(void) {
  if ((clamp(Vertex.xz, offset + 0.8, offset + 50.4) == Vertex.xz) && (LOD != 2))
    discard;
  float dist = length(DVertex);

  TexCoord = mat4(
    processTexCoord(texture2D(HeightMap, (5.0 * Vertex.xz + vec2(0.0, 0.0)) / TerrainSize).r * 8.0),
    processTexCoord(texture2D(HeightMap, (5.0 * Vertex.xz + vec2(1.0, 0.0)) / TerrainSize).r * 8.0),
    processTexCoord(texture2D(HeightMap, (5.0 * Vertex.xz + vec2(0.0, 1.0)) / TerrainSize).r * 8.0),
    processTexCoord(texture2D(HeightMap, (5.0 * Vertex.xz + vec2(1.0, 1.0)) / TerrainSize).r * 8.0));
  texColors = mat4(
    texture2D(TerrainTexture, getRightTexCoord(1.0 / 512.0) + TexCoord[0].xy).rgba,
    texture2D(TerrainTexture, getRightTexCoord(1.0 / 512.0) + TexCoord[1].xy).rgba,
    texture2D(TerrainTexture, getRightTexCoord(1.0 / 512.0) + TexCoord[2].xy).rgba,
    texture2D(TerrainTexture, getRightTexCoord(1.0 / 512.0) + TexCoord[3].xy).rgba);
  float VY = fetchHeightAtOffset(vec2(0.0, 0.0));
  normal = normalize(
    normalize(cross(vec3(+0.0, fetchHeightAtOffset(vec2(+ 0.0, - 0.2 * NFactor)) - VY, -0.2 * NFactor), vec3(-0.2 * NFactor, fetchHeightAtOffset(vec2(- 0.2 * NFactor, + 0.0)) - VY, +0.0)))
  + normalize(cross(vec3(+0.2 * NFactor, fetchHeightAtOffset(vec2(+ 0.2 * NFactor, + 0.0)) - VY, +0.0), vec3(+0.0, fetchHeightAtOffset(vec2(+ 0.0, - 0.2 * NFactor)) - VY, -0.2 * NFactor)))
  + normalize(cross(vec3(+0.0, fetchHeightAtOffset(vec2(+ 0.0, + 0.2 * NFactor)) - VY, +0.2 * NFactor), vec3(+0.2 * NFactor, fetchHeightAtOffset(vec2(+ 0.2 * NFactor, + 0.0)) - VY, -0.0)))
  + normalize(cross(vec3(-0.2 * NFactor, fetchHeightAtOffset(vec2(- 0.2 * NFactor, + 0.0)) - VY, +0.0), vec3(+0.0, fetchHeightAtOffset(vec2(+ 0.0, + 0.2 * NFactor)) - VY, +0.2 * NFactor))));
  normal.y *= NFactor;
  normal.xz *= pow(1.0 - rhf, 5.0);
  vec3 onormal = normal;
  vec3 bumpNormal = vec3(0.0, 1.0, 0.0);
  vec4 result = gl_TextureMatrix[0] * Vertex;
//   result = sqrt(abs(result)) * sign(result);
  if (dist < maxBumpDistance) {
    bumpColors = mat4(
      texture2D(TerrainTexture, getRightTexCoord(1.0 / 64.0) + TexCoord[0].xy + vec2(0.0, 0.5)).rgba,
      texture2D(TerrainTexture, getRightTexCoord(1.0 / 64.0) + TexCoord[1].xy + vec2(0.0, 0.5)).rgba,
      texture2D(TerrainTexture, getRightTexCoord(1.0 / 64.0) + TexCoord[2].xy + vec2(0.0, 0.5)).rgba,
      texture2D(TerrainTexture, getRightTexCoord(1.0 / 64.0) + TexCoord[3].xy + vec2(0.0, 0.5)).rgba);
    bumpNormal = normalize(2.0 * mix(mix(bumpColors[0], bumpColors[1], fpart(Vertex.x / (3.2 / pow(4, float(LOD))))), mix(bumpColors[2], bumpColors[3], fpart(Vertex.x / (3.2 / pow(4, float(LOD))))), fpart(Vertex.z / (3.2 / pow(4, float(LOD))))).rbg - 1.0);
    float angle = acos(normal.x);
    vec3 tangent = normalize(vec3(sin(angle), sin(angle - 1.5705), 0.0));
    vec3 bitangent = normalize(cross(normal, tangent));
    normal = mix(normal, normalize(tangent * bumpNormal.x + normal * bumpNormal.y + bitangent * bumpNormal.z), clamp((maxBumpDistance - dist) / (maxBumpDistance / 2.0), 0.0, 1.0));
  }
  normal = normalize(normal);
  vec4 SunShadow = vec4(0.0, 0.0, 0.0, 0.0);
  if (length(result.xy / result.w) < 1.0)
    SunShadow = texture2D(SunShadowMap, 0.5 + 0.5 * result.xy / result.w);
  if (SunShadow.a + 0.1 >= SDist)
    SunShadow = vec4(0.0, 0.0, 0.0, 0.0);
  Diffuse = gl_LightSource[0].diffuse * (((1.0 - vec4(SunShadow.rgb * clamp(SDist - SunShadow.a, 0.0, 1.0), 0.0)) * max(-length(SunShadow.rgb) / sqrt(3.0), dot(normal, normalize(gl_LightSource[0].position.xyz - Vertex.xyz)))));
  Ambient = gl_LightSource[0].ambient * (0.3 + 0.7 * dot(normal, vec3(0.0, 1.0, 0.0)));
  AddLight(1);
  AddLight(2);
  AddLight(3);
  AddLight(4);
  AddLight(5);
  AddLight(6);
  AddLight(7);
  gl_FragColor = mix(mix(texColors[0], texColors[1], fpart(Vertex.x * 5.0)), mix(texColors[2], texColors[3], fpart(Vertex.x * 5.0)), fpart(Vertex.z * 5.0)) * (Diffuse + Ambient);
  gl_FragColor.a = 1.0;
  if (PointToHighlight.x >= 0)
    gl_FragColor = mix(gl_FragColor, vec4(0.0, 1.0, 1.0, 1.0), min(1.0, 1.0 - min(20.0 * abs(Vertex.x - PointToHighlight.x), 1.0) + 1.0 - min(20.0 * abs(Vertex.z - PointToHighlight.y), 1.0)));
  if (HeightLineToHighlight >= 0)
    gl_FragColor = mix(gl_FragColor, vec4(0.0, 1.0, 1.0, 1.0), min(1.0, 1.0 - min(20.0 * abs(Vertex.y - HeightLineToHighlight), 1.0)));
  if (clamp(Vertex.xz, Min, Max) != Vertex.xz)
    gl_FragColor.rgb *= 0.5;
  gl_FragColor = mix(gl_FragColor, vec4(gl_FragColor.xyz, 0.0), pow(dist / 3000.0, 2.0));
}
