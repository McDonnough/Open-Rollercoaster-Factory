#version 120

uniform sampler2D Tex;
uniform sampler2D Bump;
uniform sampler2D Reflections;
uniform sampler2D SunShadowMap;
uniform sampler2D ShadowMap1;
uniform sampler2D ShadowMap2;
uniform sampler2D ShadowMap3;
uniform int UseBumpMap;
uniform int UseReflections;
uniform int UseTexture;
uniform float Reflective;
uniform vec4 MeshColor;

varying vec4 Vertex;
varying vec4 DVertex;
varying vec3 Normal;
varying vec3 v;

vec4 Shadows[7];

vec3 Eye = vec3(0.0, 0.0, 0.0);
vec3 normal = vec3(0.0, 1.0, 0.0);
vec4 Diffuse = vec4(0.0, 0.0, 0.0, 1.0);
vec4 Specular = vec4(0.0, 0.0, 0.0, 1.0);
vec4 Ambient = vec4(0.0, 0.0, 0.0, 1.0);

vec2 GetShadowCoord(vec3 vector) {
  vector = -normalize(vector);
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
  return texCoord;
}

void AddLight(int ID) {
  vec3 DistVector = gl_LightSource[ID].position.xyz - Vertex.xyz;
  float lnrDistVector = max(0.5, dot(DistVector, DistVector));
  Diffuse += gl_LightSource[ID].diffuse * gl_LightSource[ID].diffuse.a * ((1.0 - vec4(Shadows[ID - 1].rgb, 0.0)) * max(-length(Shadows[ID - 1].rgb) / sqrt(3.0), dot(normal, normalize(DistVector))) * gl_LightSource[ID].position.w * gl_LightSource[ID].position.w / lnrDistVector);
  Ambient += gl_LightSource[ID].ambient * gl_LightSource[ID].ambient.a * gl_LightSource[ID].position.w * gl_LightSource[ID].position.w / lnrDistVector;
  vec3 Reflected = normalize(reflect(-normalize((gl_ModelViewMatrix * vec4(gl_LightSource[ID].position.xyz, 1.0) - DVertex).xyz), normalize(gl_NormalMatrix * normal)));
  Specular += clamp(gl_FrontMaterial.shininess, 0.0, 1.0) * gl_LightSource[ID].diffuse * gl_LightSource[ID].diffuse.a * (1.0 - vec4(Shadows[ID - 1].rgb, 0.0)) * max(-length(Shadows[ID - 1].rgb) / sqrt(3.0), pow(dot(Reflected, Eye), gl_FrontMaterial.shininess)) * gl_LightSource[ID].position.w * gl_LightSource[ID].position.w / lnrDistVector;
}

vec3 GetReflectionColor(vec3 vector) {
  vector = reflect(normalize(v), -vector);
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
  return texture2D(Reflections, texCoord).rgb;
}

void main(void) {
  normal = normalize(Normal);
  vec4 result = gl_TextureMatrix[0] * Vertex;
  if (UseBumpMap == 1) {
    vec3 q0 = dFdx(Vertex.xyz);
    vec3 q1 = dFdy(Vertex.xyz);
    vec2 st0 = dFdx(gl_TexCoord[0].st);
    vec2 st1 = dFdy(gl_TexCoord[0].st);

    vec3 S = normalize( q0 * st1.t - q1 * st0.t);
    vec3 T = normalize(-q0 * st1.s + q1 * st0.s);

    mat3 M = mat3(-T, -S, normal);
    normal = normalize(M * (vec3(texture2D(Bump, gl_TexCoord[0].zw)) - vec3(0.5, 0.5, 0.5)));
  }
  vec4 SunShadow = vec4(0.0, 0.0, 0.0, 0.0);
  if (gl_TexCoord[7].xy == clamp(gl_TexCoord[7].xy, vec2(0.0, 0.0), vec2(1.0, 1.0))) {
    SunShadow = texture2D(SunShadowMap, gl_TexCoord[7].xy);
    if (SunShadow.a - 0.1 <= Vertex.y)
      SunShadow = vec4(0.0, 0.0, 0.0, 0.0);
    SunShadow.rgb *= max(0.0, dot(normal, normalize(gl_LightSource[0].position.xyz - Vertex.xyz)));
    SunShadow.rgb *= clamp(abs(SunShadow.a - Vertex.y), 0.0, 1.0);
  }
  Eye       = normalize(-DVertex.xyz);
  vec3 Reflected = normalize(reflect(-normalize((gl_ModelViewMatrix * gl_LightSource[0].position - DVertex).xyz), normalize(gl_NormalMatrix * normal)));
  vec4 color = vec4(1.0, 1.0, 1.0, 1.0);
  if (UseTexture == 1)
    color = texture2D(Tex, gl_TexCoord[0].xy);
  color *= MeshColor;
  Diffuse = gl_LightSource[0].diffuse * max(vec4(0.0, 0.0, 0.0, 0.0), (((1.0 - vec4(SunShadow.rgb, 0.0)) * max(-length(SunShadow.rgb) / sqrt(3.0), mix(1.0, dot(normal, normalize(gl_LightSource[0].position.xyz - Vertex.xyz)), color.a)))));
  Specular = clamp(gl_FrontMaterial.shininess, 0.0, 1.0) * gl_LightSource[0].diffuse * max(vec4(0.0, 0.0, 0.0, 0.0), (((1.0 - vec4(SunShadow.rgb, 0.0)) * max(-length(SunShadow.rgb) / sqrt(3.0), pow(max(0.0, dot(Reflected, Eye)), gl_FrontMaterial.shininess)))));
  Ambient = gl_LightSource[0].ambient * (0.4 + 0.6 * dot(normal, vec3(0.0, 1.0, 0.0)));
  vec3 ReflectionColor = Ambient.rgb;
  if (UseReflections == 1)
    ReflectionColor = GetReflectionColor(normal);
  Diffuse *= (1.0 - Reflective);
  Ambient *= (1.0 - Reflective);
  color.rgb *= (1.0 - Reflective);
  Shadows[0] = texture2D(ShadowMap1, GetShadowCoord(gl_LightSource[1].position.xyz - Vertex.xyz));
  if (Shadows[0].a + 0.1 > distance(gl_LightSource[1].position.xyz, Vertex.xyz))
    Shadows[0] = vec4(0.0, 0.0, 0.0, 0.0);
  Shadows[1] = texture2D(ShadowMap2, GetShadowCoord(gl_LightSource[2].position.xyz - Vertex.xyz));
  if (Shadows[1].a + 0.1 > distance(gl_LightSource[2].position.xyz, Vertex.xyz))
    Shadows[1] = vec4(0.0, 0.0, 0.0, 0.0);
  Shadows[2] = texture2D(ShadowMap3, GetShadowCoord(gl_LightSource[3].position.xyz - Vertex.xyz));
  if (Shadows[2].a + 0.1 > distance(gl_LightSource[3].position.xyz, Vertex.xyz))
    Shadows[2] = vec4(0.0, 0.0, 0.0, 0.0);
  Shadows[3] = vec4(0.0, 0.0, 0.0, 0.0);
  Shadows[4] = vec4(0.0, 0.0, 0.0, 0.0);
  Shadows[5] = vec4(0.0, 0.0, 0.0, 0.0);
  Shadows[6] = vec4(0.0, 0.0, 0.0, 0.0);
  AddLight(1);
  AddLight(2);
  AddLight(3);
  AddLight(4);
  AddLight(5);
  AddLight(6);
  AddLight(7);
  Specular.a = 0.0;
  Diffuse.a = 0.0;
  Ambient.a = 1.0;
  gl_FragColor = color * (Diffuse + Ambient) + Reflective * vec4(ReflectionColor, 0.0) + Specular;
}