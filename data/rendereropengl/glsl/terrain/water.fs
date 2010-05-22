#version 120

uniform sampler2D HeightMap;
uniform vec2 TerrainSize;

varying float dist;
varying float diff;
varying float SDist;
varying vec4 result;
varying vec4 Vertex;

void main(void) {
  if (diff <= 0.0)
    discard;
  gl_FragDepth = sqrt(dist / 10000.0);
  gl_FragColor = vec4(min(diff, 1.0), min(diff, 1.0), min(diff, 1.0), 1.0);
  gl_FragColor.a = 1.0;
}