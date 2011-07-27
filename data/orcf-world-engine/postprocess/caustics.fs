#version 120

#extension GL_EXT_gpu_shader4 : require

uniform sampler2D GeometryTexture;
uniform sampler2D NormalTexture;
uniform sampler2D HeightMap;

uniform vec2 TerrainSize;
uniform vec2 BumpOffset;

void main(void) {
  gl_FragData[0] = vec4(0.0, 0.0, 0.0, 0.0);

  ivec2 Coords = ivec2(floor(gl_FragCoord.xy));

  vec4 Vertex = texelFetch2D(GeometryTexture, Coords, 0);
  vec4 Normal = texelFetch2D(NormalTexture, Coords, 0);
  vec3 Sun = gl_LightSource[0].position.xyz - Vertex.xyz;
  float dotprod = max(0.0, dot(normalize(Normal.xyz), normalize(Sun)));

  float factor = 1.0;

  if (dotprod != 0.0) {
    vec2 FakeVertex = Vertex.xz;
    if (Vertex.x < 0.0) FakeVertex.x = Vertex.x * Vertex.x / 1638.4;
    if (Vertex.z < 0.0) FakeVertex.y = Vertex.z * Vertex.z / 1638.4;
    if (Vertex.x > TerrainSize.x) FakeVertex.x = TerrainSize.x - (Vertex.x - TerrainSize.x) * (Vertex.x - TerrainSize.x) / 1638.4;
    if (Vertex.z > TerrainSize.y) FakeVertex.y = TerrainSize.y - (Vertex.z - TerrainSize.y) * (Vertex.z - TerrainSize.y) / 1638.4;

    vec2 Height = 256.0 * texture2D(HeightMap, FakeVertex / TerrainSize).gb;

    if (Height.r > Vertex.y) {
      factor = pow(0.9, (Height.r - Vertex.y));
      float lf = pow(0.95,  Vertex.w);
      vec2 XZPos = Vertex.xz + (Height.r - Vertex.y) * Sun.xz / -Sun.y;
      XZPos += 0.2 * vec2(sin(XZPos.y + 4.0 * BumpOffset.x + 0.32 * XZPos.x), cos(3.1416 * XZPos.x + 3.67 * BumpOffset.y + 0.68 * XZPos.y));
      XZPos = vec2(sin(3.0 * XZPos.x), sin(3.0 * XZPos.y));
      XZPos *= XZPos;
      XZPos *= XZPos;
      XZPos *= XZPos;
      XZPos *= pow(0.6, (Height.r - Vertex.y)) * lf;
      factor *= (1.0 - 0.2 * lf + XZPos.x);
      factor *= (1.0 - 0.2 * lf + XZPos.y);
      factor = mix(1.0, factor, min(3.0 * abs(Height.r - Vertex.y) * dotprod, 1.0));
    }
  }
  gl_FragData[0].a = 1.0 - factor;
  gl_FragData[1] = gl_FragData[0];
}