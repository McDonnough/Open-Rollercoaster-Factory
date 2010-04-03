#version 120

uniform sampler2D TerrainTexture;
uniform int LOD;
uniform vec2 offset;

varying float dist;
varying vec4 Vertex;
varying vec3 Normal;
varying vec4 TexMap;

float fpart(float a) {
  return a - floor(a);
}

vec2 trunc(vec2 a) {
  return a - floor(a);
}

vec2 getRightTexCoord(float fac) {
  return clamp(trunc(gl_TexCoord[0].xy * 4.0 * fac), 1.0 / 512.0, 1.0 - 1.0 / 512.0) / 4.0;
}

void main(void) {
  if ((clamp(Vertex.xz, offset, offset + 51.2) == Vertex.xz) && (LOD < 2))
    discard;
  mat4 texColors = mat4(
    vec4(texture2D(TerrainTexture, getRightTexCoord(1.0 / 483) + gl_TexCoord[1].xy) + texture2D(TerrainTexture, getRightTexCoord(1.0 / 128.0) + gl_TexCoord[1].xy)),
    vec4(texture2D(TerrainTexture, getRightTexCoord(1.0 / 483) + gl_TexCoord[2].xy) + texture2D(TerrainTexture, getRightTexCoord(1.0 / 128.0) + gl_TexCoord[2].xy)),
    vec4(texture2D(TerrainTexture, getRightTexCoord(1.0 / 483) + gl_TexCoord[3].xy) + texture2D(TerrainTexture, getRightTexCoord(1.0 / 128.0) + gl_TexCoord[3].xy)),
    vec4(texture2D(TerrainTexture, getRightTexCoord(1.0 / 483) + gl_TexCoord[4].xy) + texture2D(TerrainTexture, getRightTexCoord(1.0 / 128.0) + gl_TexCoord[4].xy)));
  mat4 bumpColors = mat4(
    vec4(texture2D(TerrainTexture, getRightTexCoord(1.0 / 128.0) + gl_TexCoord[1].xy + vec2(0.0, 0.5))),
    vec4(texture2D(TerrainTexture, getRightTexCoord(1.0 / 128.0) + gl_TexCoord[2].xy + vec2(0.0, 0.5))),
    vec4(texture2D(TerrainTexture, getRightTexCoord(1.0 / 128.0) + gl_TexCoord[3].xy + vec2(0.0, 0.5))),
    vec4(texture2D(TerrainTexture, getRightTexCoord(1.0 / 128.0) + gl_TexCoord[4].xy + vec2(0.0, 0.5))));
  vec3 bumpNormal = normalize(2.0 * mix(mix(bumpColors[0], bumpColors[1], fpart(Vertex.x / (3.2 / pow(4, float(LOD))))), mix(bumpColors[2], bumpColors[3], fpart(Vertex.x / (3.2 / pow(4, float(LOD))))), fpart(Vertex.z / (3.2 / pow(4, float(LOD))))).rgb - 1.0);
  bumpNormal.xz *= 0.2;
  bumpNormal.y *= 0.5;
  bumpNormal.y += 0.5;
  bumpNormal = normalize(bumpNormal);
  vec3 normal = normalize(Normal);
  float angle = acos(Normal.x);
  vec3 tangent = normalize(vec3(sin(angle), sin(angle - 1.5705), 0.0));
  vec3 bitangent = normalize(cross(Normal, tangent));
  normal = normalize(tangent * bumpNormal.x + normal * bumpNormal.y + bitangent * bumpNormal.z);
  gl_FragColor = mix(mix(texColors[0], texColors[1], fpart(Vertex.x / (3.2 / pow(4, float(LOD))))), mix(texColors[2], texColors[3], fpart(Vertex.x / (3.2 / pow(4, float(LOD))))), fpart(Vertex.z / (3.2 / pow(4, float(LOD))))) * 0.5 * dot(normalize(normal), normalize(vec3(1.0, 1.0, 0.0)));
  gl_FragColor.a = 1.0;
  gl_FragDepth = sqrt(dist / 10000.0);
}
