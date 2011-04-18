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

varying vec3 Vertex;

float Fresnel(float x) {
  float theSQRT = sqrt(max(0.0, 1.0 - pow(Mediums.x / Mediums.y * sin(x), 2.0)));
  float Rs = pow((Mediums.x * cos(x) - Mediums.y * theSQRT) / (Mediums.x * cos(x) + Mediums.y * theSQRT), 2.0);
  float Rp = pow((Mediums.x * theSQRT - Mediums.y * cos(x)) / (Mediums.x * theSQRT + Mediums.y * cos(x)), 2.0);
  return min(1.0, 0.5 * (Rs + Rp));
}

void main(void) {
  vec2 FakeVertex = Vertex.xz;
  if (Vertex.x < 0.0) FakeVertex.x = Vertex.x * Vertex.x / 1638.4;
  if (Vertex.z < 0.0) FakeVertex.y = Vertex.z * Vertex.z / 1638.4;
  if (Vertex.x > TerrainSize.x) FakeVertex.x = TerrainSize.x - (Vertex.x - TerrainSize.x) * (Vertex.x - TerrainSize.x) / 1638.4;
  if (Vertex.z > TerrainSize.y) FakeVertex.y = TerrainSize.y - (Vertex.z - TerrainSize.y) * (Vertex.z - TerrainSize.y) / 1638.4;
  if (Vertex.x < -204.8) FakeVertex.x = 25.6;
  if (Vertex.z < -204.8) FakeVertex.y = 25.6;
  if (Vertex.x > TerrainSize.x + 204.8) FakeVertex.x = TerrainSize.x - 25.6;
  if (Vertex.z > TerrainSize.y + 204.8) FakeVertex.y = TerrainSize.y - 25.6;

  vec2 hm = texture2D(HeightMap, FakeVertex / TerrainSize).gb;
  if (abs(256.0 * hm.r - Height) > 0.1)
    discard;

  vec3 Position = vec3(Vertex.x, Height, Vertex.z);

  vec4 bumpColor = (-1.0 + 2.0 * texture2D(BumpMap, (Vertex.xz + BumpOffset) / 30.0)) - (-1.0 + 2.0 * texture2D(BumpMap, (Vertex.xz + BumpOffset.yx) / 15.0 + 0.5));
  vec3 normal = normalize((bumpColor.rbg) + vec3(0.0, 1.0, 0.0));
  vec3 Eye = normalize((gl_ModelViewMatrix * vec4(Position, 1.0)).xyz);

  vec4 RealPosition = gl_ModelViewProjectionMatrix * vec4(Position, 1.0);
  float OffsetFactor = 1.0 - clamp(pow(0.5, Height - texture2D(GeometryMap, 0.5 + 0.5 * RealPosition.xy / RealPosition.w).y), 0.0, 1.0);

  normal = normalize(UnderWaterFactor * mix(vec3(0.0, 1.0, 0.0), normal, OffsetFactor));

  vec4 RefractedPosition = gl_ModelViewProjectionMatrix * vec4(Position + normal * vec3(1.0, 0.0, 1.0), 1.0);
  vec4 ReflectedPosition = gl_ModelViewProjectionMatrix * vec4(Position + normal * vec3(1.0, 0.0, 1.0), 1.0);

  float WaterColorFactor = 0.9 + 0.1 * dot(normal, normalize(gl_LightSource[0].position.xyz));

  float ReflectionCoefficient = Fresnel(acos(max(0.0, dot(-Eye, normalize(gl_NormalMatrix * normal)))));
  gl_FragData[3] = vec4(0.0, 0.0, 0.0, 1.0);
  gl_FragData[2] = vec4(Vertex, length(vec3(gl_ModelViewMatrix * vec4(Vertex, 1.0))));
  gl_FragData[1] = vec4(UnderWaterFactor * normal, 250.0);
  gl_FragData[5] = vec4(0.0, 0.0, 0.0, 0.0);
  gl_FragData[0] = vec4(0.0, 0.0, 0.0, 1.0);
  gl_FragData[4].rgb = ReflectionCoefficient * texture2D(ReflectTex, 0.5 + 0.5 * ReflectedPosition.xy / ReflectedPosition.w).rgb;
  gl_FragData[4].rgb += (1.0 - ReflectionCoefficient) * texture2D(RefractTex, 0.5 + 0.5 * RefractedPosition.xy / RefractedPosition.w).rgb;
  gl_FragData[4].a = WaterColorFactor;
  
//   gl_FragData[4] = vec4(0.0, 0.0, 0.0, 0.0);
//   gl_FragData[3] = vec4(0.0, 0.0, 0.0, 1.0);
//   gl_FragData[2] = vec4(Vertex.x, Height + Displacement, Vertex.z, length(vec3(gl_ModelViewMatrix * vec4(Vertex.x, Height + Displacement, Vertex.z, 1.0))));
//   gl_FragData[1] = vec4(UnderWaterFactor * vec3(0.0, 1.0, 0.0), 250.0);
//   gl_FragData[0] = vec4(vec3(0.2, 0.3, 0.27) * 3.0 * gl_LightSource[0].ambient.rgb, -1.0);
}
