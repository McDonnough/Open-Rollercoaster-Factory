#version 120

uniform sampler2D HeightMap;
uniform sampler2D Autoplant;
uniform vec2 TerrainSize;

varying float dist;
varying vec4 Vertex;
varying vec4 BaseVertex;
varying vec3 normal;

void main(void) {
  if (dist > 30.0)
    discard;
  gl_FragColor = texture2D(Autoplant, gl_TexCoord[0].xy);
  vec4 Lighting = vec4(0.0, 0.0, 0.0, 1.0);
  Lighting = gl_LightSource[0].diffuse * (dot(normalize(gl_NormalMatrix * normal), normalize(gl_LightSource[0].position.xyz - Vertex.xyz)) + 0.2) + gl_LightSource[0].ambient;
  gl_FragColor.rgb *= Lighting.rgb;
  gl_FragColor.a *= 1.2 * clamp(0.2 * (30 - dist), 0.0, 1.0);
  gl_FragDepth = sqrt(dist / 10000.0);
}