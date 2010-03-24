#version 120

uniform sampler2D TerrainTexture;
uniform int HighLOD;
uniform vec2 offset;

varying float dist;
varying vec4 Vertex;
varying vec3 Normal;

vec2 trunc(vec2 a) {
  return a - floor(a);
}

vec2 getRightTexCoord(float fac) {
  return clamp(trunc(gl_TexCoord[0].xy * 4.0 * fac), 1.0 / 512.0, 1.0 - 1.0 / 512.0) / 4.0;
}

void main(void) {
  if ((clamp(Vertex.xz, offset, offset + 51.2) == Vertex.xz) && (HighLOD == 0))
    discard;
  gl_FragColor = (texture2D(TerrainTexture, getRightTexCoord(1.0 / 483)) + texture2D(TerrainTexture, getRightTexCoord(1.0 / 128.0))) * 0.5 * dot(normalize(Normal), normalize(vec3(1.0, 1.0, 1.0)));
  gl_FragColor.a = 1.0;
  gl_FragDepth = sqrt(dist / 10000.0);
}