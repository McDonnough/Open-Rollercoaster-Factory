#version 120

uniform sampler2D Tex;
uniform sampler2D Bump;
uniform sampler2D Reflections;
uniform sampler2D SunShadowMap;
uniform int UseBumpMap;
uniform int UseReflections;
uniform int UseTexture;
uniform float Reflective;
uniform vec4 MeshColor;

varying vec4 Vertex;
varying vec4 DVertex;
varying vec3 Normal;
varying vec3 v;

vec3 GetReflectionColor(vec3 normal) {
  normal = reflect(normalize(v), -normal);
  float mx = max(abs(normal.x), max(abs(normal.y), abs(normal.z)));
  normal = normal / mx;
  vec2 texCoord = vec2(0, 0);
  if (normal.z <= -0.99)
    texCoord = 0.5 + 0.5 * normal.xy * vec2(0.99, 0.99);
  if (normal.z >= 0.99)
    texCoord = 0.5 + 0.5 * normal.xy * vec2(-0.99, 0.99) + vec2(2.0, 0.0);
  if (normal.x <= -0.99)
    texCoord = 0.5 + 0.5 * normal.zy * vec2(-0.99, 0.99) + vec2(0.0, 1.0);
  if (normal.x >= 0.99)
    texCoord = 0.5 + 0.5 * normal.zy * vec2(0.99, 0.99) + vec2(1.0, 0.0);
  if (normal.y <= -0.99)
    texCoord = 0.5 + 0.5 * normal.xz * vec2(0.99, -0.99) + vec2(1.0, 1.0);
  if (normal.y >= 0.99)
    texCoord = 0.5 + 0.5 * normal.xz * vec2(0.99, 0.99) + vec2(2.0, 1.0);
  texCoord /= vec2(3.0, 2.0);
  return texture2D(Reflections, texCoord).rgb;
}

void main(void) {
  vec4 Diffuse = vec4(0.0, 0.0, 0.0, 1.0);
  vec4 Specular = vec4(0.0, 0.0, 0.0, 1.0);
  vec4 Ambient = vec4(0.0, 0.0, 0.0, 1.0);
  vec3 normal = normalize(Normal);
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
  vec3 Eye       = normalize(-DVertex.xyz);
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
  Diffuse.a = 0.0;
  Ambient.a = 1.0;
  gl_FragColor = color * (Diffuse + Ambient) + Reflective * vec4(ReflectionColor, 0.0) + Specular;
}