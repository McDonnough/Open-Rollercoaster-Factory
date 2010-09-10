#version 120

uniform sampler2D Tex;
uniform sampler2D Bump;
uniform sampler2D SunShadowMap;

varying vec4 Vertex;
varying vec3 Normal;
varying float SDist;

void main(void) {
  vec4 Diffuse = vec4(0.0, 0.0, 0.0, 1.0);
  vec4 Ambient = vec4(0.0, 0.0, 0.0, 1.0);
  vec3 normal = normalize(Normal);
  vec4 result = gl_TextureMatrix[0] * Vertex;
  vec4 SunShadow = vec4(0.0, 0.0, 0.0, 0.0);
  if (length(result.xy / result.w) < 1.0)
    SunShadow = texture2D(SunShadowMap, 0.5 + 0.5 * result.xy / result.w);
  if (SunShadow.a + 0.1 >= SDist)
    SunShadow = vec4(0.0, 0.0, 0.0, 0.0);
  Diffuse = gl_LightSource[0].diffuse * max(vec4(0.0, 0.0, 0.0, 0.0), (((1.0 - vec4(SunShadow.rgb * clamp(abs(SDist - SunShadow.a), 0.0, 1.0), 0.0)) * max(-length(SunShadow.rgb) / sqrt(3.0), dot(normal, normalize(gl_LightSource[0].position.xyz - Vertex.xyz))))));
  Ambient = gl_LightSource[0].ambient * (0.3 + 0.7 * dot(normal, vec3(0.0, 1.0, 0.0)));
  gl_FragColor = vec4(vec3(1.0, 1.0, 1.0) * (Diffuse + Ambient).rgb, 1.0);
}