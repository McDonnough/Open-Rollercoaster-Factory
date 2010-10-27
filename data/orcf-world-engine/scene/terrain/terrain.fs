#version 120

uniform sampler2D TerrainMap;
uniform sampler2D TerrainTexture;
uniform float TerrainTesselationDistance;
uniform float HeightLine;

void main(void) {
  gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);
}