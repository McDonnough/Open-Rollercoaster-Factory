#version 120

uniform int Border;
uniform vec2 TerrainSize;
uniform vec2 Camera;
uniform float TerrainTesselationDistance;

varying vec3 VData;

void main(void) {
  if (clamp(VData.xz, vec2(0.0, 0.0), TerrainSize) != VData.xz && Border != 1)
    discard;

  if (Border == 0 && max(abs(Camera.x - VData.x), abs(Camera.y - VData.z)) < TerrainTesselationDistance - 1.0)
    discard;

  gl_FragColor = vec4(1.0, 1.0, 1.0, VData.y);
  gl_FragDepth = 1.0 - VData.y / 1000.0;
}