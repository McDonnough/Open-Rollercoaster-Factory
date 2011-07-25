#version 120

uniform sampler2D TerrainMap;
uniform float TerrainTesselationDistance;
uniform int Tesselation;
uniform vec2 TerrainSize;
uniform vec2 TOffset;
uniform vec3 ShadowOffset;
uniform float ShadowSize;
uniform vec2 Offset;

varying vec3 VData;

void main(void) {
  vec2 FakeVertex = Offset + gl_Vertex.xz;
  VData = vec3(Offset.x + gl_Vertex.x, texture2D(TerrainMap, FakeVertex / TerrainSize + TOffset).b * 256.0, Offset.y + gl_Vertex.z);
  vec3 Vertex = VData;
  vec3 dir = Vertex - gl_LightSource[0].position.xyz;
  dir /= abs(dir.y);
  Vertex += (Vertex.y - ShadowOffset.y) * dir;
  Vertex -= ShadowOffset;
  gl_Position = vec4((Vertex / ShadowSize).xz, 1.0, 1.0);
}

