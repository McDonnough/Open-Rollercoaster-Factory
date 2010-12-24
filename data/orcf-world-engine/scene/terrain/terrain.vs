#version 120

uniform sampler2D TerrainMap;
uniform float TerrainTesselationDistance;
uniform int Tesselation;
uniform vec2 TerrainSize;
uniform vec2 TOffset;
uniform vec2 Offset;

varying vec3 Vertex;
varying vec3 NormalFactor;
varying vec2 FakeVertex;
varying float YFactor;

void main(void) {
  FakeVertex = Offset + gl_MultiTexCoord0.xy;
  Vertex = vec3(Offset.x + gl_Vertex.x, mix(64.0, texture2D(TerrainMap, FakeVertex / TerrainSize + TOffset).b * 256.0, gl_Vertex.y), Offset.y + gl_Vertex.z);
  YFactor = gl_Vertex.y;
  NormalFactor = gl_Normal;
  gl_Position = gl_ModelViewProjectionMatrix * vec4(Vertex, 1.0);
  gl_ClipVertex = gl_ModelViewMatrix * vec4(Vertex, 1.0);
}