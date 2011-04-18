#version 120

uniform sampler2D TerrainMap;
uniform float TerrainTesselationDistance;
uniform int Tesselation;
uniform vec2 TerrainSize;
uniform vec2 TOffset;
uniform vec3 ShadowOffset;
uniform vec3 ShadowVectorX;
uniform vec3 ShadowVectorY;
uniform float ShadowSize;
uniform float ShadowFactor;
uniform vec2 Offset;

varying vec3 VData;

void main(void) {
  vec2 FakeVertex = Offset + gl_MultiTexCoord0.xy;
  vec3 Vertex = vec3(Offset.x + gl_Vertex.x, texture2D(TerrainMap, FakeVertex / TerrainSize + TOffset).b * 256.0, Offset.y + gl_Vertex.z);
  VData = Vertex;
  vec3 dir = normalize(Vertex - gl_LightSource[0].position.xyz);
  gl_Position = vec4(dot(dir, ShadowVectorX) * ShadowFactor, dot(dir, ShadowVectorY) * ShadowFactor, 1.0, 1.0);
}

