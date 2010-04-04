#version 120

uniform sampler2D TerrainTexture;
uniform sampler2D NormalTexture;
uniform sampler2D LayerTexture;
uniform int LOD;
uniform vec2 offset;
uniform float maxBumpDistance;
uniform vec2 TerrainSize;
uniform vec3 lightdir;

varying float dist;
varying vec4 Vertex;
varying vec3 Normal;

float fpart(float a) {
  return a - floor(a);
}

vec2 trunc(vec2 a) {
  return a - floor(a);
}

vec2 getRightTexCoord(float fac) {
  return clamp(trunc(gl_TexCoord[0].xy * 4.0 * fac), 1.0 / 512.0, 1.0 - 1.0 / 512.0) / 4.0;
}

vec4 processTexCoord(float texID) {
  return vec4(fpart(texID / 4.0), floor(texID / 4.0) / 4.0, 0.0, 1.0);
}

vec2 round(vec2 a) {
  vec2 result;
  result.x = (fpart(a.x) >= 0.5) ? ceil(a.x) : floor(a.x);
  result.y = (fpart(a.y) >= 0.5) ? ceil(a.y) : floor(a.y);
  return result;
}

void main(void) {
  if ((clamp(Vertex.xz, offset, offset + 51.2) == Vertex.xz) && (LOD < 2))
    discard;
  mat4 TexCoord = mat4(
    processTexCoord(texture2D(LayerTexture, (5.0 * Vertex.xz + vec2(0.0, 0.0)) / TerrainSize).r * 8.0),
    processTexCoord(texture2D(LayerTexture, (5.0 * Vertex.xz + vec2(1.0, 0.0)) / TerrainSize).r * 8.0),
    processTexCoord(texture2D(LayerTexture, (5.0 * Vertex.xz + vec2(0.0, 1.0)) / TerrainSize).r * 8.0),
    processTexCoord(texture2D(LayerTexture, (5.0 * Vertex.xz + vec2(1.0, 1.0)) / TerrainSize).r * 8.0));
  mat4 texColors = mat4(
    vec4(texture2D(TerrainTexture, getRightTexCoord(1.0 / 483) + TexCoord[0].xy) + texture2D(TerrainTexture, getRightTexCoord(1.0 / 128.0) + TexCoord[0].xy)),
    vec4(texture2D(TerrainTexture, getRightTexCoord(1.0 / 483) + TexCoord[1].xy) + texture2D(TerrainTexture, getRightTexCoord(1.0 / 128.0) + TexCoord[1].xy)),
    vec4(texture2D(TerrainTexture, getRightTexCoord(1.0 / 483) + TexCoord[2].xy) + texture2D(TerrainTexture, getRightTexCoord(1.0 / 128.0) + TexCoord[2].xy)),
    vec4(texture2D(TerrainTexture, getRightTexCoord(1.0 / 483) + TexCoord[3].xy) + texture2D(TerrainTexture, getRightTexCoord(1.0 / 128.0) + TexCoord[3].xy)));
  vec3 normal = normalize(Normal);
  normal = normalize(2.0 * texture2D(NormalTexture, 5.0 * Vertex.xz / TerrainSize).rgb - 1.0);
  if (dist < maxBumpDistance) {
    mat4 bumpColors = mat4(
      vec4(texture2D(TerrainTexture, getRightTexCoord(1.0 / 128.0) + TexCoord[0].xy + vec2(0.0, 0.5))),
      vec4(texture2D(TerrainTexture, getRightTexCoord(1.0 / 128.0) + TexCoord[1].xy + vec2(0.0, 0.5))),
      vec4(texture2D(TerrainTexture, getRightTexCoord(1.0 / 128.0) + TexCoord[2].xy + vec2(0.0, 0.5))),
      vec4(texture2D(TerrainTexture, getRightTexCoord(1.0 / 128.0) + TexCoord[3].xy + vec2(0.0, 0.5))));
    vec3 bumpNormal = normalize(2.0 * mix(mix(bumpColors[0], bumpColors[1], fpart(Vertex.x / (3.2 / pow(4, float(LOD))))), mix(bumpColors[2], bumpColors[3], fpart(Vertex.x / (3.2 / pow(4, float(LOD))))), fpart(Vertex.z / (3.2 / pow(4, float(LOD))))).rbg - 1.0);
    float angle = acos(Normal.x);
    vec3 tangent = normalize(vec3(sin(angle), sin(angle - 1.5705), 0.0));
    vec3 bitangent = normalize(cross(Normal, tangent));
    normal = mix(normal, normalize(tangent * bumpNormal.x + normal * bumpNormal.y + bitangent * bumpNormal.z), clamp((maxBumpDistance - dist) / (maxBumpDistance / 3.0), 0.0, 1.0));
  }
  gl_FragColor = mix(mix(texColors[0], texColors[1], fpart(Vertex.x * 5.0)), mix(texColors[2], texColors[3], fpart(Vertex.x * 5.0)), fpart(Vertex.z * 5.0)) * 0.5 * (dot(normalize(normal), normalize(lightdir)));
  gl_FragColor.a = 1.0;
  gl_FragDepth = sqrt(dist / 10000.0);
}
