#version 120

uniform sampler2D TerrainMap;
uniform float TerrainTesselationDistance;
uniform int Tesselation;
uniform vec2 TerrainSize;
uniform vec2 TOffset;
uniform vec3 ShadowOffset;
uniform float ShadowSize;
uniform vec2 Offset;

varying vec3 dir;
varying vec3 Vertex;

void main(void) {
  vec2 FakeVertex = Offset + gl_Vertex.xz;
  Vertex = vec3(Offset.x + gl_Vertex.x, mix(64.0, texture2D(TerrainMap, FakeVertex / TerrainSize + TOffset).b * 256.0, gl_Vertex.y), Offset.y + gl_Vertex.z);
  dir = Vertex - gl_LightSource[1].position.xyz;
  gl_Position = gl_ModelViewProjectionMatrix * vec4(Vertex, 1.0);
}

