#version 120

uniform sampler2D Tex;
uniform sampler2D Bump;
uniform sampler2D SunShadowMap;
uniform int UseBumpMap;
uniform int UseTexture;

varying vec4 Vertex;
varying vec3 Normal;
varying float SDist;

void main(void) {
  vec4 Diffuse = vec4(0.0, 0.0, 0.0, 1.0);
  vec4 Ambient = vec4(0.0, 0.0, 0.0, 1.0);
  vec3 normal = normalize(Normal);
  vec4 result = gl_TextureMatrix[0] * Vertex;
  vec4 SunShadow = vec4(0.0, 0.0, 0.0, 0.0);
  if (UseBumpMap == 1) {
    vec4 BumpColor = texture2D(Bump, gl_TexCoord[0].zw) * 2.0 - 1.0;
    vec3 tangent = normalize(cross(abs(normal), vec3(0.01, 1.0, 0.01)));
    vec3 bitangent = normalize(cross(tangent, normal));
    normal = normalize(BumpColor.r * tangent + BumpColor.b * normal + BumpColor.g * bitangent);
  }
  if (length(result.xy / result.w) < 1.0)
    SunShadow = texture2D(SunShadowMap, 0.5 + 0.5 * result.xy / result.w);
  if (SunShadow.a + 0.1 >= SDist)
    SunShadow = vec4(0.0, 0.0, 0.0, 0.0);
  Diffuse = gl_LightSource[0].diffuse * max(vec4(0.0, 0.0, 0.0, 0.0), (((1.0 - vec4(SunShadow.rgb * clamp(abs(SDist - SunShadow.a), 0.0, 1.0), 0.0)) * max(-length(SunShadow.rgb) / sqrt(3.0), dot(normal, normalize(gl_LightSource[0].position.xyz - Vertex.xyz))))));
  Ambient = gl_LightSource[0].ambient * (0.3 + 0.7 * dot(normal, vec3(0.0, 1.0, 0.0)));
  Diffuse.a = 0.0;
  Ambient.a = 1.0;
  vec4 color = vec4(1.0, 1.0, 1.0, 1.0);
  if (UseTexture == 1)
    color = texture2D(Tex, gl_TexCoord[0].xy);
  gl_FragColor = color * (Diffuse + Ambient);
}