#version 120

#extension GL_EXT_gpu_shader4 : require

uniform sampler2D GeometryTexture;
uniform sampler2D NormalTexture;
uniform sampler2D ShadowTexture;
uniform sampler2D MaterialTexture;
uniform sampler2D HeightMap;
uniform sampler2D SSAOTexture;
uniform sampler2D EmissionTexture;

uniform vec2 BumpOffset;

uniform vec2 TerrainSize;
uniform float ShadowSize;
uniform vec3 ShadowOffset;
uniform int UseSSAO;

const int BlurSamples = {{{owe.shadows.blur}}};

// IF [ EQ owe.shadows.sun 1 ]
vec2 ProjectShadowVertex(vec3 V) {
  vec3 dir = V - gl_LightSource[0].position.xyz;
  dir /= abs(dir.y);
  V += (V.y - ShadowOffset.y) * dir;
  V -= ShadowOffset;
  return (V / ShadowSize).xz;
}
// END

void main(void) {
  ivec2 Coords = ivec2(floor(gl_FragCoord.xy));

  vec4 AllCoord = texelFetch2D(GeometryTexture, Coords, 0);
  vec4 Emission = texelFetch2D(EmissionTexture, Coords, 0);
  // IF [ EQ owe.ssao 1 ]
  vec4 ssaoColor = texture2D(SSAOTexture, gl_TexCoord[0].xy);
    // IF [ EQ owe.ssao.indirectlighting 1 ]
    if (UseSSAO == 1)
      Emission.rgb += ssaoColor.rgb;
    // END
  // END

  vec3 Vertex = AllCoord.rgb;
  vec4 Normal = texelFetch2D(NormalTexture, Coords, 0);
  vec4 Material = texelFetch2D(MaterialTexture, Coords, 0);
  vec3 Sun = gl_LightSource[0].position.xyz - Vertex;
  float dotprod = max(0.0, dot(normalize(Normal.xyz), normalize(Sun)));
  gl_FragData[0].rgb = dotprod * gl_LightSource[0].diffuse.rgb;

  vec3 factor = vec3(2.0, 2.0, 2.0);

  // IF [ EQ owe.shadows.sun 1 ]
  vec2 ShadowCoord = 0.5 + 0.5 * ProjectShadowVertex(Vertex);
  vec4 ShadowColor = texture2D(ShadowTexture, ShadowCoord);
  if (dotprod > 0.0 && ShadowColor.a > Vertex.y + 0.02 && clamp(ShadowCoord.x, 0.0, 1.0) == ShadowCoord.x && clamp(ShadowCoord.y, 0.0, 1.0) == ShadowCoord.y) {

    // IF [ NEQ owe.shadows.blur 0 ]
    float CoordFactor = (ShadowColor.a - Vertex.y) * 100.0 / ShadowSize * 2 / max(1.0, 1.0 * BlurSamples);
    int Samples = (2 * BlurSamples + 1) * (2 * BlurSamples + 1);
    for (int i = -BlurSamples; i <= BlurSamples; i++)
      for (int j = -BlurSamples; j <= BlurSamples; j++) {
        ShadowColor = texture2D(ShadowTexture, ShadowCoord + 0.0004 * CoordFactor * vec2(i, j));
        if (ShadowColor.a > Vertex.y + 0.02)
          factor -= 2.0 * ShadowColor.rgb / Samples * min(1.0, 15.0 * abs(ShadowColor.a - Vertex.y - 0.02));
      }
    // END

    // IF [ EQ owe.shadows.blur 0 ]
    if (ShadowColor.a > Vertex.y + 0.02)
      factor -= 2.0 * ShadowColor.rgb * min(1.0, 15.0 * abs(ShadowColor.a - Vertex.y - 0.02));
    // END
  }
  // END
  factor = min(factor, vec3(1.0, 1.0, 1.0));
  gl_FragData[0].rgb *= factor;

  // IF [ EQ owe.ssao 1 ]
  if (UseSSAO == 1)
    gl_FragData[0].rgb += ssaoColor.a * gl_LightSource[0].ambient.rgb * (0.8 + 0.2 * dot(normalize(Normal.xyz), vec3(0.0, 1.0, 0.0)));
  else
    gl_FragData[0].rgb += (0.3 + 0.7 * (0.5 + 0.5 * dot(normalize(Normal.xyz), vec3(0.0, 1.0, 0.0)))) * gl_LightSource[0].ambient.rgb;
  // END
  // IF [ NEQ owe.ssao 1 ]
    gl_FragData[0].rgb += (0.3 + 0.7 * (0.5 + 0.5 * dot(normalize(Normal.xyz), vec3(0.0, 1.0, 0.0)))) * gl_LightSource[0].ambient.rgb;
  // END
  vec4 v = (gl_ModelViewMatrix * vec4(Vertex, 1.0));
  vec3 Eye = normalize(-v.xyz);
  vec3 Reflected = normalize(reflect(-normalize((gl_ModelViewMatrix * vec4(gl_LightSource[0].position.xyz, 1.0) - v).xyz), normalize(gl_NormalMatrix * Normal.xyz)));
  gl_FragData[0].a = pow(max(dot(Reflected, Eye), 0.0), Normal.a) * length(factor) / sqrt(3.0);

  // Caustic

  if (dotprod != 0.0) {
    vec2 FakeVertex = Vertex.xz;
    if (Vertex.x < 0.0) FakeVertex.x = Vertex.x * Vertex.x / 1638.4;
    if (Vertex.z < 0.0) FakeVertex.y = Vertex.z * Vertex.z / 1638.4;
    if (Vertex.x > TerrainSize.x) FakeVertex.x = TerrainSize.x - (Vertex.x - TerrainSize.x) * (Vertex.x - TerrainSize.x) / 1638.4;
    if (Vertex.z > TerrainSize.y) FakeVertex.y = TerrainSize.y - (Vertex.z - TerrainSize.y) * (Vertex.z - TerrainSize.y) / 1638.4;

    vec2 Height = 256.0 * texture2D(HeightMap, FakeVertex / TerrainSize).gb;

    if (Height.r > Vertex.y) {
      gl_FragData[0].rgb *= pow(0.9, (Height.r - Vertex.y));
      vec3 ol = gl_FragData[0].rgb;
      float lf = pow(0.95,  AllCoord.w);
      vec2 XZPos = Vertex.xz + (Height.r - Vertex.y) * Sun.xz / -Sun.y;
      XZPos += 0.2 * vec2(sin(XZPos.y + 4.0 * BumpOffset.x + 0.32 * XZPos.x), cos(3.1416 * XZPos.x + 3.67 * BumpOffset.y + 0.68 * XZPos.y));
      XZPos = vec2(sin(3.0 * XZPos.x), sin(3.0 * XZPos.y));
      XZPos *= XZPos;
      XZPos *= XZPos;
      XZPos *= XZPos;
      XZPos *= pow(0.6, (Height.r - Vertex.y)) * lf;
      gl_FragData[0].rgb *= (1.0 - 0.2 * lf + XZPos.x);
      gl_FragData[0].rgb *= (1.0 - 0.2 * lf + XZPos.y);
      gl_FragData[0].rgb = mix(ol, gl_FragData[0].rgb, min(3.0 * abs(Height.r - Vertex.y) * length(factor) / sqrt(3.0) * dotprod, 1.0));
    }

    gl_FragData[1] = vec4(gl_FragData[0].a * gl_FragData[0].rgb, 1.0);

  }
  gl_FragData[0].rgb += Emission.rgb;

  // No lighting

  if (abs(Normal.x) + abs(Normal.y) + abs(Normal.z) == 0.0)
    gl_FragData[0].a = -1.0;

  
}