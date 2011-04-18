#version 120

uniform int Border;
uniform vec2 TerrainSize;
uniform vec2 Camera;
uniform float TerrainTesselationDistance;
uniform vec3 ShadowOffset;

varying vec3 VData;

void main(void) {
  if (clamp(VData.xz, vec2(0.0, 0.0), TerrainSize) != VData.xz && Border != 1)
    discard;

  if (Border == 0 && max(abs(Camera.x - VData.x), abs(Camera.y - VData.z)) < TerrainTesselationDistance - 1.0)
    discard;

  float Dist = length(VData - gl_LightSource[0].position.xyz);
  Dist -= length(ShadowOffset - gl_LightSource[0].position.xyz);
  gl_FragColor = vec4(1.0, 1.0, 1.0, Dist);
  gl_FragDepth = 0.5 + 0.5 * (Dist / 256.0);
}