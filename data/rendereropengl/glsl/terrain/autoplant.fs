#version 120

uniform sampler2D HeightMap;
uniform sampler2D Autoplant;
uniform vec2 TerrainSize;
uniform vec3 lightdir;

varying float dist;
varying vec4 Vertex;
varying vec4 BaseVertex;
varying vec3 normal;

void main(void) {
  gl_FragColor = texture2D(Autoplant, gl_TexCoord[0].xy);
  gl_FragColor.rgb *= dot(normalize(lightdir), normal);
  gl_FragColor.a *= clamp(0.2 * (30 - dist), 0.0, 1.0);
  gl_FragDepth = sqrt(dist / 10000.0);
}