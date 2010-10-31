#version 120

uniform sampler2D GeometryTexture;
uniform sampler2D NormalTexture;
uniform sampler2D ShadowTexture;

void main(void) {
  vec3 Vertex = texture2D(GeometryTexture, gl_TexCoord[0].xy).rgb;
  vec3 Normal = texture2D(NormalTexture, gl_TexCoord[0].xy).rgb;
  vec3 Sun = gl_LightSource[0].position.xyz;
  gl_FragColor.rgb = (0.3 + 0.7 * max(0.0, dot(normalize(Normal), vec3(0.0, 1.0, 0.0)))) * gl_LightSource[0].ambient.rgb;
  gl_FragColor.rgb += max(0.0, dot(normalize(Normal), normalize(Sun - Vertex))) * gl_LightSource[0].diffuse.rgb;
  gl_FragColor.a = 0.0;
  if (max(Normal.x, max(Normal.y, Normal.z)) == 0.0)
    gl_FragColor.a = -1.0;
}