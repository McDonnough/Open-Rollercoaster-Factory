#version 120

uniform sampler2D HeightMap;
uniform sampler2D ReflectTex;
uniform sampler2D RefractTex;
uniform sampler2D BumpMap;
uniform sampler2D GeometryMap;
uniform float Height;
uniform vec2 TerrainSize;
uniform vec2 ScreenSize;
uniform vec2 BumpOffset;
uniform float UnderWaterFactor;
uniform vec2 Mediums;

varying vec2 Vertex;
varying float Displacement;

float Fresnel(float x) {
  float Rs = pow((Mediums.x * cos(x) - Mediums.y * sqrt(1.0 - pow(Mediums.x / Mediums.y * sin(x), 2.0))) / (Mediums.x * cos(x) + Mediums.y * sqrt(1.0 - pow(Mediums.x / Mediums.y * sin(x), 2.0))), 2.0);
  float Rp = pow((Mediums.x * sqrt(1.0 - pow(Mediums.x / Mediums.y * sin(x), 2.0)) - Mediums.y * cos(x)) / (Mediums.x * sqrt(1.0 - pow(Mediums.x / Mediums.y * sin(x), 2.0)) + Mediums.y * cos(x)), 2.0);
  return 0.5 * (min(1.0, Rs) + min(1.0, Rp));
}

void main(void) {
  vec2 FakeVertex = Vertex;
  if (Vertex.x < 0.0) FakeVertex.x = Vertex.x * Vertex.x / 1638.4;
  if (Vertex.y < 0.0) FakeVertex.y = Vertex.y * Vertex.y / 1638.4;
  if (Vertex.x > TerrainSize.x) FakeVertex.x = TerrainSize.x - (Vertex.x - TerrainSize.x) * (Vertex.x - TerrainSize.x) / 1638.4;
  if (Vertex.y > TerrainSize.y) FakeVertex.y = TerrainSize.y - (Vertex.y - TerrainSize.y) * (Vertex.y - TerrainSize.y) / 1638.4;
  if (Vertex.x < -204.8) FakeVertex.x = 25.6;
  if (Vertex.y < -204.8) FakeVertex.y = 25.6;
  if (Vertex.x > TerrainSize.x + 204.8) FakeVertex.x = TerrainSize.x - 25.6;
  if (Vertex.y > TerrainSize.y + 204.8) FakeVertex.y = TerrainSize.y - 25.6;

  vec2 hm = texture2D(HeightMap, FakeVertex / TerrainSize).gb;
  if (abs(256.0 * hm.r - Height) > 0.1)
    discard;

  vec3 Position = vec3(Vertex.x, Height, Vertex.y);

  vec4 bumpColor = (-1.0 + 2.0 * texture2D(BumpMap, (Vertex + BumpOffset) / 30.0)) - (-1.0 + 2.0 * texture2D(BumpMap, (Vertex + BumpOffset.yx) / 15.0 + 0.5));
  vec3 normal = normalize((bumpColor.rbg) + vec3(0.0, 1.0, 0.0));
  vec3 Eye = normalize((gl_ModelViewMatrix * vec4(Position, 1.0)).xyz);

  vec4 RealPosition = gl_ModelViewProjectionMatrix * vec4(Position, 1.0);
  float PixelSceneHeight = texture2D(GeometryMap, 0.5 + 0.5 * RealPosition.xy / RealPosition.w).y;
  float OffsetFactor = 1.0 - clamp(pow(0.5, Height - PixelSceneHeight), 0.0, 1.0);

  normal = UnderWaterFactor * mix(vec3(0.0, 1.0, 0.0), normal, OffsetFactor);

  vec3 RefractedOffset = normal * vec3(1.0, 0.0, 1.0);
  vec4 RefractedPosition = gl_ModelViewProjectionMatrix * vec4(Position + RefractedOffset, 1.0);

  vec3 ReflectedOffset = normal * vec3(1.0, 0.0, 1.0);
  vec4 ReflectedPosition = gl_ModelViewProjectionMatrix * vec4(Position + ReflectedOffset, 1.0);

  vec3 SceneVertex = texture2D(GeometryMap, 0.5 + 0.5 * RefractedPosition.xy / RefractedPosition.w).xyz;
  float HeightFactor = clamp(pow(0.9, distance(SceneVertex, vec3(Vertex.x, Height, Vertex.y))), 0.0, 1.0);

  float WaterColorFactor = 0.9 + 0.1 * dot(normal, normalize(gl_LightSource[0].position.xyz));

  gl_FragData[3] = vec4(0.0, 0.0, 0.0, 1.0);
  gl_FragData[2] = vec4(Vertex.x, Height + Displacement, Vertex.y, length(vec3(gl_ModelViewMatrix * vec4(Vertex.x, Height + Displacement, Vertex.y, 1.0))));
  gl_FragData[1] = vec4(UnderWaterFactor * normal, 250.0);
  gl_FragData[0] = vec4(1.0, 1.0, 1.0, -1.0);
  float ReflectionCoefficient = Fresnel(acos(dot(-Eye, normalize(gl_NormalMatrix * normal))));
  gl_FragData[0].rgb = ReflectionCoefficient * texture2D(ReflectTex, 0.5 + 0.5 * ReflectedPosition.xy / ReflectedPosition.w).rgb;
  gl_FragData[0].rgb += (1.0 - ReflectionCoefficient) * (mix(vec3(0.20, 0.30, 0.27) * 3.0 * gl_LightSource[0].ambient.rgb, texture2D(RefractTex, 0.5 + 0.5 * RefractedPosition.xy / RefractedPosition.w).rgb, HeightFactor));
  gl_FragData[0].rgb *= WaterColorFactor;
}
