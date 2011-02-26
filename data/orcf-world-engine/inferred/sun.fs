#version 120

#extension GL_EXT_gpu_shader4 : enable

uniform sampler2D GeometryTexture;
uniform sampler2D NormalTexture;
uniform sampler2D ShadowTexture;
uniform sampler2D MaterialTexture;
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
  ivec2 Coords = ivec2(floor(gl_FragCoord.xy));

  vec3 Vertex = texelFetch2D(GeometryTexture, Coords, 0).rgb;
  vec4 Normal = texelFetch2D(NormalTexture, Coords, 0);
  vec4 Material = texelFetch2D(MaterialTexture, Coords, 0);
  vec3 Sun = gl_LightSource[0].position.xyz;
  gl_FragColor.rgb = max(0.0, dot(normalize(Normal.xyz), normalize(Sun - Vertex))) * gl_LightSource[0].diffuse.rgb;
  vec2 ShadowCoord = 0.5 + 0.5 * ProjectShadowVertex(Vertex);
  vec4 ShadowColor = texture2D(ShadowTexture, ShadowCoord);
  vec3 factor = vec3(2.0, 2.0, 2.0);
  if (ShadowColor.a > Vertex.y + 0.1 && clamp(ShadowCoord.x, 0.0, 1.0) == ShadowCoord.x && clamp(ShadowCoord.y, 0.0, 1.0) == ShadowCoord.y) {
    float CoordFactor = (ShadowColor.a - Vertex.y) * 100.0 / ShadowSize * 2 / max(1.0, 1.0 * BlurSamples);
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
  gl_FragColor.rgb += (0.3 + 0.7 * max(0.0, dot(normalize(Normal.xyz), vec3(0.0, 1.0, 0.0)))) * gl_LightSource[0].ambient.rgb;
  gl_FragColor.rgb = mix(gl_FragColor.rgb, vec3(1.0, 1.0, 1.0), max(0.0, -Material.a));
  vec4 v = (gl_ModelViewMatrix * vec4(Vertex, 1.0));
  vec3 Eye = normalize(-v.xyz);
  vec3 Reflected = normalize(reflect(-normalize((gl_ModelViewMatrix * vec4(gl_LightSource[0].position.xyz, 1.0) - v).xyz), normalize(gl_NormalMatrix * Normal.xyz)));
  gl_FragColor.a = pow(max(dot(Reflected, Eye), 0.0), Normal.a) * length(factor) / sqrt(3.0);
  if (max(Normal.x, max(Normal.y, Normal.z)) == 0.0)
    gl_FragColor.a = -1.0;
}