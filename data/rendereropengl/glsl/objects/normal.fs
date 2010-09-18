#version 120

uniform sampler2D Tex;
uniform sampler2D Bump;
uniform sampler2D SunShadowMap;
uniform int UseBumpMap;
uniform int UseTexture;

varying vec4 Vertex;
varying vec4 DVertex;
varying vec3 Normal;
varying vec3 StandardTangent;

void main(void) {
  vec4 Diffuse = vec4(0.0, 0.0, 0.0, 1.0);
  vec4 Specular = vec4(0.0, 0.0, 0.0, 1.0);
  vec4 Ambient = vec4(0.0, 0.0, 0.0, 1.0);
  vec3 normal = normalize(Normal);
  vec4 result = gl_TextureMatrix[0] * Vertex;
  if (UseBumpMap == 1) {
    vec4 BumpColor = texture2D(Bump, gl_TexCoord[0].zw) * 2.0 - 1.0;
    vec3 tangent;
    if (abs(dot(normal, vec3(0.0, 1.0, 0.0))) >= 0.99)
      tangent = normalize(dot(normal, vec3(0.0, 1.0, 0.0)) * StandardTangent);
    else
      tangent = normalize(cross(normal, vec3(0.0, 1.0, 0.0)));
    vec3 bitangent = normalize(cross(StandardTangent, normal));
    tangent = normalize(cross(bitangent, normal));
    normal = normalize(BumpColor.r * tangent + BumpColor.b * normal + BumpColor.g * bitangent);
  }
  vec4 SunShadow = vec4(0.0, 0.0, 0.0, 0.0);
  if (gl_TexCoord[7].xy == clamp(gl_TexCoord[7].xy, vec2(0.0, 0.0), vec2(1.0, 1.0))) {
    SunShadow = texture2D(SunShadowMap, gl_TexCoord[7].xy);
    if (SunShadow.a - 0.1 <= Vertex.y)
      SunShadow = vec4(0.0, 0.0, 0.0, 0.0);
    SunShadow.rgb *= max(0.0, dot(normal, normalize(gl_LightSource[0].position.xyz - Vertex.xyz)));
    SunShadow.rgb *= clamp(abs(SunShadow.a - Vertex.y), 0.0, 1.0);
  }
  Diffuse = gl_LightSource[0].diffuse * max(vec4(0.0, 0.0, 0.0, 0.0), (((1.0 - vec4(SunShadow.rgb, 0.0)) * max(-length(SunShadow.rgb) / sqrt(3.0), dot(normal, normalize(gl_LightSource[0].position.xyz - Vertex.xyz))))));
  Specular = gl_LightSource[0].diffuse * max(vec4(0.0, 0.0, 0.0, 0.0), (((1.0 - vec4(SunShadow.rgb, 0.0)) * max(-length(SunShadow.rgb) / sqrt(3.0), pow(max(0.0, dot(normalize(reflect(normalize(DVertex.xyz), normal)), normalize(gl_LightSource[0].position.xyz - Vertex.xyz))), 20.0)))));
  Ambient = gl_LightSource[0].ambient * (0.3 + 0.7 * dot(normal, vec3(0.0, 1.0, 0.0)));
  Diffuse.a = 0.0;
  Specular.a = 0.0;
  Ambient.a = 1.0;
  vec4 color = vec4(1.0, 1.0, 1.0, 1.0);
  if (UseTexture == 1)
    color = texture2D(Tex, gl_TexCoord[0].xy);
  gl_FragColor = color * (Diffuse + Ambient) + Specular;
}