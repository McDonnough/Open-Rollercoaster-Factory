#version 120

uniform sampler2D HeightMap;
uniform sampler2D EnvironmentMap;
uniform sampler2D BumpMap;
uniform float Height;

uniform vec2 TerrainSize;
uniform vec2 BumpOffset;

uniform vec3 ViewPoint;

varying vec2 Vertex;

float Fresnel(float x) {
  float Rs = pow((cos(x) - 1.33 * sqrt(1.0 - pow(1.0 / 1.33 * sin(x), 2.0))) / (cos(x) + 1.33 * sqrt(1.0 - pow(1.0 / 1.33 * sin(x), 2.0))), 2.0);
  float Rp = pow((sqrt(1.0 - pow(1.0 / 1.33 * sin(x), 2.0)) - 1.33 * cos(x)) / (sqrt(1.0 - pow(1.0 / 1.33 * sin(x), 2.0)) + 1.33 * cos(x)), 2.0);
  return 0.5 * (Rs + Rp);
}

vec3 GetReflectionColor(vec3 vector) {
  vector = reflect(normalize(vec3(Vertex.x, Height, Vertex.y) - ViewPoint), -vector);
  float mx = max(abs(vector.x), max(abs(vector.y), abs(vector.z)));
  vector = vector / mx;
  vec2 texCoord = vec2(0, 0);
  if (vector.z <= -0.99)
    texCoord = 0.5 + 0.5 * vector.xy * vec2(0.99, 0.99);
  if (vector.z >= 0.99)
    texCoord = 0.5 + 0.5 * vector.xy * vec2(-0.99, 0.99) + vec2(2.0, 0.0);
  if (vector.x <= -0.99)
    texCoord = 0.5 + 0.5 * vector.zy * vec2(-0.99, 0.99) + vec2(0.0, 1.0);
  if (vector.x >= 0.99)
    texCoord = 0.5 + 0.5 * vector.zy * vec2(0.99, 0.99) + vec2(1.0, 0.0);
  if (vector.y <= -0.99)
    texCoord = 0.5 + 0.5 * vector.xz * vec2(0.99, -0.99) + vec2(1.0, 1.0);
  if (vector.y >= 0.99)
    texCoord = 0.5 + 0.5 * vector.xz * vec2(0.99, 0.99) + vec2(2.0, 1.0);
  texCoord /= vec2(3.0, 2.0);
  return texture2D(EnvironmentMap, texCoord).rgb;
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

  float WaterColorFactor = 0.9 + 0.1 * dot(normal, normalize(gl_LightSource[0].position.xyz));

  gl_FragData[3] = vec4(0.0, 0.0, 0.0, 1.0);
  gl_FragData[2] = vec4(Vertex.x, Height, Vertex.y, length(vec3(gl_ModelViewMatrix * vec4(Vertex.x, Height, Vertex.y, 1.0))));
  gl_FragData[1] = vec4(normal, 250.0);
  gl_FragData[0] = vec4(1.0, 1.0, 1.0, -1.0);
  float ReflectionCoefficient = Fresnel(acos(dot(-Eye, normalize(gl_NormalMatrix * normal))));
  gl_FragData[0].rgb = ReflectionCoefficient * GetReflectionColor(normal);
  gl_FragData[0].rgb += (1.0 - ReflectionCoefficient) * (vec3(0.20, 0.30, 0.27) * 3.0 * gl_LightSource[0].ambient.rgb);
  gl_FragData[0].rgb *= WaterColorFactor;
}