#version 120

uniform sampler2D GeometryTexture;
uniform sampler2D NormalTexture;
uniform sampler2D ShadowTexture;
uniform float ShadowSize;
uniform vec3 ShadowOffset;
uniform int BlurSamples;

vec2 ProjectShadowVertex(vec3 V) {
  vec3 dir = V - gl_LightSource[0].position.xyz;
  dir /= abs(dir.y);
  V += (V.y - ShadowOffset.y) * dir;
  V -= ShadowOffset;
  return (V / ShadowSize).xz;
}

void main(void) {
  vec3 Vertex = texture2D(GeometryTexture, gl_TexCoord[0].xy).rgb;
  vec3 Normal = texture2D(NormalTexture, gl_TexCoord[0].xy).rgb;
  vec3 Sun = gl_LightSource[0].position.xyz;
  gl_FragColor.rgb = max(0.0, dot(normalize(Normal), normalize(Sun - Vertex))) * gl_LightSource[0].diffuse.rgb;
  vec2 ShadowCoord = 0.5 + 0.5 * ProjectShadowVertex(Vertex);
  vec4 ShadowColor = texture2D(ShadowTexture, ShadowCoord);
  if (ShadowColor.a > Vertex.y + 0.1) {
    vec3 factor = vec3(2.0, 2.0, 2.0);
    float CoordFactor = (ShadowColor.a - Vertex.y) * 100.0 / ShadowSize;
    int Samples = (2 * BlurSamples + 1) * (2 * BlurSamples + 1);
    for (int i = -BlurSamples; i <= BlurSamples; i++)
      for (int j = -BlurSamples; j <= BlurSamples; j++) {
        ShadowColor = texture2D(ShadowTexture, ShadowCoord + 0.0004 * CoordFactor * vec2(i, j));
        if (ShadowColor.a > Vertex.y + 0.1)
          factor -= 2.0 * ShadowColor.rgb / Samples;
      }
    factor = min(factor, vec3(1.0, 1.0, 1.0));
    gl_FragColor.rgb *= factor;
  }
  gl_FragColor.rgb += (0.3 + 0.7 * max(0.0, dot(normalize(Normal), vec3(0.0, 1.0, 0.0)))) * gl_LightSource[0].ambient.rgb;
  gl_FragColor.a = 0.0;
  if (max(Normal.x, max(Normal.y, Normal.z)) == 0.0)
    gl_FragColor.a = -1.0;
}