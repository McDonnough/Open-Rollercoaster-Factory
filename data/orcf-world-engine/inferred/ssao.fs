#version 120

uniform sampler2D GeometryTexture;
uniform sampler2D NormalTexture;
uniform sampler2D EmissionTexture;

uniform float RandomOffset;
uniform ivec2 ScreenSize;
uniform float FSAASamples;

const int SamplesFirstRing = {{{owe.ssao.ringsamples}}};
const int Rings = {{{owe.ssao.rings}}};

void main(void) {
  float value = 0.0;

  // IF [ EQ owe.ssao.indirectlighting 1 ]
  vec3 finalEmission = vec3(0.0, 0.0, 0.0);
  // END

  vec4 Vertex = texture2D(GeometryTexture, gl_TexCoord[0].xy);
  vec3 Normal = texture2D(NormalTexture, gl_TexCoord[0].xy).xyz;

  int Samples = 0;

  for (int i = 1; i <= Rings; i++) {
    float Radius = 200.0 * i / Vertex.a / Rings;
    float Coeff = 6.28319 / (SamplesFirstRing * i);
    for (int j = 0; j < SamplesFirstRing * i; j++) {
      Samples++;
      vec2 coord = gl_TexCoord[0].xy + (Radius * vec2(sin(Coeff * j + RandomOffset), cos(Coeff * j + RandomOffset))) / ScreenSize;
      vec3 Dest = texture2D(GeometryTexture, coord).xyz;
      vec3 dir = Dest - Vertex.xyz;
      float distfactor = 1.5 * pow(2.7183, -0.4 * length(dir));
      value += 1.0 - max(0.0, dot(normalize(dir), Normal)) * distfactor;
      // IF [ EQ owe.ssao.indirectlighting 1 ]
      coord = gl_TexCoord[0].xy + (6.0 * Radius * vec2(sin(Coeff * j + RandomOffset), cos(Coeff * j + RandomOffset))) / ScreenSize;
      Dest = texture2D(GeometryTexture, coord).xyz;
      dir = Dest - Vertex.xyz;
      vec4 Emission = texture2D(EmissionTexture, coord);
      finalEmission += 2.0 * Emission.rgb * Emission.a * Emission.a / (Emission.a * Emission.a + dot(dir, dir)) * max(0.0, dot(normalize(dir), Normal));
      // END
    }
  }

  value = max(value, 0.0);
  value /= Samples;
  // IF [ EQ owe.ssao.indirectlighting 1 ]
  finalEmission /= Samples;
  gl_FragColor = vec4(finalEmission, value);
  // END
  // IF [ NEQ owe.ssao.indirectlighting 1 ]
  gl_FragColor = vec4(value, value, value, value);
  // END
}