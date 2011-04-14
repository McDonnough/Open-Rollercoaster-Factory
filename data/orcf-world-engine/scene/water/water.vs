#version 120

uniform sampler2D BumpMap;
uniform sampler2D HeightMap;
uniform float Height;
uniform vec2 Offset;
uniform vec2 BumpOffset;
uniform vec2 TerrainSize;

varying vec2 Vertex;
varying float Displacement;

void main(void) {
  Vertex = gl_Vertex.xy + Offset;
  float hm = clamp(Height - texture2D(HeightMap, Vertex / TerrainSize).b * 256.0 - 0.1, 0.0, 1.0);
  vec4 bumpColor = (-1.0 + 2.0 * texture2D(BumpMap, (Vertex + BumpOffset) / 30.0)) - (-1.0 + 2.0 * texture2D(BumpMap, (Vertex + BumpOffset.yx) / 15.0 + 0.5));
  Displacement = (0.5 + 0.5 * bumpColor.a) * gl_Vertex.z * 0.4 * hm;
  vec4 DestVector = vec4(gl_Vertex.x + Offset.x, Height + Displacement, gl_Vertex.y + Offset.y, 1.0);
  gl_Position = gl_ModelViewProjectionMatrix * DestVector;
  gl_ClipVertex = gl_ModelViewMatrix * DestVector;
}
