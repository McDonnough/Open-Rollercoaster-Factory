#version 120

uniform sampler2D HeightMap;
uniform sampler2D BumpMap;
uniform sampler2D ReflectionMap;
uniform sampler2D RefractionMap;
uniform sampler2D SunShadowMap;
uniform vec2 TerrainSize;
uniform float HeightLineToHighlight;
uniform int UseReflection;
uniform int UseRefraction;

uniform vec2 ShadowQuadA;
uniform vec2 ShadowQuadB;
uniform vec2 ShadowQuadC;
uniform vec2 ShadowQuadD;

varying vec4 Vertex;
varying vec4 v;

vec4 Specular = vec4(0.0, 0.0, 0.0, 1.0);
vec3 normal = vec3(0.0, 0.0, 0.0);
vec3 Eye = vec3(0.0, 0.0, 0.0);

vec2 LineIntersection(vec2 p1, vec2 p2, vec2 p3, vec2 p4) {
  float divisor = (p1.x - p2.x) * (p3.y - p4.y) - (p1.y - p2.y) * (p3.x - p4.x);
  float fac1 = p1.x * p2.y - p1.y * p2.x;
  float fac2 = p3.x * p4.y - p3.y * p4.x;
  return vec2((fac1 * (p3.x - p4.x) - fac2 * (p1.x - p2.x)) / divisor,
              (fac1 * (p3.y - p4.y) - fac2 * (p1.y - p2.y)) / divisor);
}
vec2 mapPixelToQuad(vec2 P) {
  vec2 result;
  vec2 ABtoP = cross(vec3(0.0, 1.0, 0.0), vec3(ShadowQuadA.x - ShadowQuadB.x, 0.0, ShadowQuadA.y - ShadowQuadB.y)).xz;
  vec2 CtoD = ShadowQuadD - ShadowQuadC;
  vec2 B1 = LineIntersection(ShadowQuadA, ShadowQuadB, P, P + ABtoP);
  vec2 B2 = LineIntersection(ShadowQuadD, ShadowQuadC, P, P + ABtoP);
  vec2 D1 = LineIntersection(ShadowQuadA, ShadowQuadD, P, P + CtoD);
  vec2 C1 = LineIntersection(ShadowQuadB, ShadowQuadC, P, P + CtoD);
  result.x = distance(D1, P) / distance(D1, C1);
  if (distance(C1, P) > distance(C1, D1) && distance(C1, P) > distance(D1, P))
    result.x = -result.x;
  result.y = distance(B1, P) / distance(B1, B2);
  if (distance(B2, P) > distance(B2, B1) && distance(B2, P) > distance(B1, P))
    result.y = -result.y;
  return result;
}

void AddLight(int ID) {
  vec3 DistVector = gl_LightSource[ID].position.xyz - Vertex.xyz;
  float lnrDistVector = max(0.5, DistVector.x * DistVector.x + DistVector.y * DistVector.y + DistVector.z * DistVector.z);
  vec3 Reflected = normalize(reflect(-normalize((gl_ModelViewMatrix * vec4(gl_LightSource[ID].position.xyz, 1.0) - v).xyz), normalize(gl_NormalMatrix * normal)));
  Specular += gl_LightSource[ID].diffuse * gl_LightSource[ID].position.w * gl_LightSource[ID].position.w / lnrDistVector * pow(max(dot(Reflected, Eye), 0.0), 100.0);
}

float fpart(float a) {
  return a - floor(a);
}

float fetchHeight(int index) {
  return mix(
          mix(texture2D(HeightMap, 5.0 * (Vertex.xz  + vec2(0.0, 0.0)) / TerrainSize)[index], texture2D(HeightMap, 5.0 * (Vertex.xz  + vec2(0.2, 0.0)) / TerrainSize)[index], fpart(5.0 * Vertex.x)),
          mix(texture2D(HeightMap, 5.0 * (Vertex.xz  + vec2(0.0, 0.2)) / TerrainSize)[index], texture2D(HeightMap, 5.0 * (Vertex.xz  + vec2(0.2, 0.2)) / TerrainSize)[index], fpart(5.0 * Vertex.x)),
          fpart(5.0 * Vertex.z)) * 256.0;
}

void main(void) {
  float h = fetchHeight(1);
  if (h < Vertex.y - 0.01 || h > Vertex.y + 0.01)
    discard;
  float dist = length(v);
  float terrainHeight = fetchHeight(3);
  vec4 Position = gl_ModelViewProjectionMatrix * Vertex;
  vec2 RealPosition = 0.5 + 0.5 * (Position.xy / Position.w);
  vec4 bumpColor = (-1.0 + 2.0 * texture2D(BumpMap, Vertex.xz / 15.0 + gl_TexCoord[0].xy)) - (-1.0 + 2.0 * texture2D(BumpMap, Vertex.xz / 7.5 + 0.5 * gl_TexCoord[0].yx));
  normal = normalize((bumpColor.rbg) + vec3(0.0, 1.0, 0.0));
  vec2 reflectionOffset = normal.xz / 10.0;
  vec4 SunShadow = vec4(0.0, 0.0, 0.0, 0.0);
  vec4 LightVec = Vertex - gl_LightSource[0].position;
  vec2 tc = mapPixelToQuad(Vertex.xz + LightVec.xz / abs(LightVec.y) * Vertex.y);
  if (tc == clamp(tc, vec2(0.0, 0.0), vec2(1.0, 1.0))) {
    SunShadow = texture2D(SunShadowMap, tc);
    if (SunShadow.a - 0.1 <= Vertex.y)
      SunShadow = vec4(0.0, 0.0, 0.0, 0.0);
  }
  vec4 ShadowFactor = 1.0 - vec4(SunShadow.rgb, 0.0);
  Eye       = normalize(-v.xyz);
  vec3 Reflected = normalize(reflect(-normalize((gl_ModelViewMatrix * gl_LightSource[0].position - v).xyz), normalize(gl_NormalMatrix * normal)));
  vec4 Specular = gl_LightSource[0].diffuse * ShadowFactor * pow(max(dot(Reflected, Eye), 0.0), 100.0);
  float MirrorFactor = 0.0;
  vec4 RefractColor = vec4(0.0, 0.0, 0.0, 1.0);
  if (UseRefraction == 1) {
    RefractColor.a = Vertex.y - texture2D(RefractionMap, RealPosition).a;
    RefractColor.rgb = texture2D(RefractionMap, RealPosition + reflectionOffset * clamp(RefractColor.a, 0.0, 1.0)).rgb * pow((1.0 - clamp(0.1 * RefractColor.a, 0.0, 1.0)), 2.0);
  }
  vec4 ReflectColor = 3.0 * gl_LightSource[0].ambient * gl_LightSource[0].ambient;
  if (UseReflection == 1) {
    ReflectColor = texture2D(ReflectionMap, RealPosition + reflectionOffset * clamp(RefractColor.a, 0.0, 1.0));
    MirrorFactor = 0.2 + 0.6 * dot(normalize(gl_NormalMatrix * normal), normalize(-v.xyz));
  }
  AddLight(1);
  AddLight(2);
  AddLight(3);
  AddLight(4);
  AddLight(5);
  AddLight(6);
  AddLight(7);
  gl_FragColor = (1.0 - MirrorFactor) * ReflectColor;
  gl_FragColor += RefractColor * MirrorFactor;
  gl_FragColor *= (0.5 + 0.5 * ShadowFactor);
  gl_FragColor += Specular;
  if (HeightLineToHighlight >= 0)
    gl_FragColor = mix(gl_FragColor, vec4(0.0, 1.0, 1.0, 1.0), 0.5 * min(1.0, 1.0 - min(20.0 * abs(Vertex.y - HeightLineToHighlight), 1.0)));
  gl_FragColor.a = (0.5 + 3.5 * UseRefraction) * max(Vertex.y - terrainHeight, 0.0);
}