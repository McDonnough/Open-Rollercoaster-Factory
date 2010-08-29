#version 120

uniform sampler2D HeightMap;
uniform sampler2D BumpMap;
uniform sampler2D ReflectionMap;
uniform sampler2D RefractionMap;
uniform sampler2D SunShadowMap;
uniform vec2 TerrainSize;
uniform float HeightLineToHighlight;

varying float dist;
varying float SDist;
varying vec4 Vertex;
varying vec4 v;

vec4 Specular = vec4(0.0, 0.0, 0.0, 1.0);
vec3 normal = vec3(0.0, 0.0, 0.0);
vec3 Eye = vec3(0.0, 0.0, 0.0);

void AddLight(int ID) {
  vec3 DistVector = gl_LightSource[ID].position.xyz - Vertex.xyz;
  float lnrDistVector = max(0.5, DistVector.x * DistVector.x + DistVector.y * DistVector.y + DistVector.z * DistVector.z);
  vec3 Reflected = normalize(reflect(-normalize((gl_ModelViewMatrix * gl_LightSource[ID].position - v).xyz), normalize(gl_NormalMatrix * normal)));
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
  float terrainHeight = fetchHeight(3);
  vec4 Position = gl_ModelViewProjectionMatrix * Vertex;
  vec2 RealPosition = 0.5 + 0.5 * (Position.xy / Position.w);
  normal = normalize((-1.0 + 2.0 * texture2D(BumpMap, Vertex.xz / 30.0 + gl_TexCoord[0].xy).rbg) - (-1.0 + 2.0 * texture2D(BumpMap, Vertex.xz / 15.0 + 0.5 * gl_TexCoord[0].yx).rbg) + vec3(0.0, 1.0, 0.0));
  vec2 reflectionOffset = normal.xz / 10.0;
  vec4 result = gl_TextureMatrix[0] * Vertex;
  result = sqrt(abs(result)) * sign(result);
  vec4 SunShadow = vec4(0.0, 0.0, 0.0, 0.0);
  if (length(result.xy / result.w) < 1.0)
    SunShadow = texture2D(SunShadowMap, 0.5 + 0.5 * result.xy / result.w);
  if (SunShadow.a + 0.1 >= SDist)
    SunShadow = vec4(0.0, 0.0, 0.0, 0.0);
  vec4 ShadowFactor = 1.0 - vec4(SunShadow.rgb * clamp(SDist - SunShadow.a, 0.0, 1.0), 0.0);
  Eye       = normalize(-v.xyz);
  vec3 Reflected = normalize(reflect(-normalize((gl_ModelViewMatrix * gl_LightSource[0].position - v).xyz), normalize(gl_NormalMatrix * normal)));
  vec4 Specular = gl_LightSource[0].diffuse * ShadowFactor * pow(max(dot(Reflected, Eye), 0.0), 100.0);
  float MirrorFactor = 0.2 + 0.6 * dot(normalize(gl_NormalMatrix * normal), normalize(-v.xyz));
  vec4 RefractColor;
  RefractColor.a = Vertex.y - texture2D(RefractionMap, RealPosition).a;
  RefractColor.rgb = texture2D(RefractionMap, RealPosition + reflectionOffset * clamp(RefractColor.a, 0.0, 1.0)).rgb * pow((1.0 - clamp(0.1 * RefractColor.a, 0.0, 1.0)), 2.0);
  AddLight(1);
  gl_FragColor = (1.0 - MirrorFactor) * texture2D(ReflectionMap, RealPosition + reflectionOffset * clamp(RefractColor.a, 0.0, 1.0));
  gl_FragColor += RefractColor * MirrorFactor;
  gl_FragColor *= (0.5 + 0.5 * ShadowFactor);
  gl_FragColor += Specular;
  gl_FragColor.a = 1.0;
  if (HeightLineToHighlight >= 0)
    gl_FragColor = mix(gl_FragColor, vec4(0.0, 1.0, 1.0, 1.0), min(1.0, 1.0 - min(20.0 * abs(Vertex.y - HeightLineToHighlight), 1.0)));
}