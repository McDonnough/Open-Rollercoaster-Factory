#version 120

uniform int Border;
uniform vec2 TerrainSize;
uniform vec2 Camera;
uniform float TerrainTesselationDistance;

varying vec3 dir;
varying vec3 Vertex;

void main(void) {
  if (clamp(Vertex.xz, vec2(0.0, 0.0), TerrainSize) != Vertex.xz && Border != 1)
    discard;

  if (Border == 0 && max(abs(Camera.x - Vertex.x), abs(Camera.y - Vertex.z)) < TerrainTesselationDistance - 1.0)
    discard;

  gl_FragColor = vec4(1.0, 1.0, 1.0, length(dir));
}