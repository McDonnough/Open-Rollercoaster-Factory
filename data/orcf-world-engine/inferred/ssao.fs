#version 120

uniform sampler2D GeometryTexture;
uniform sampler2D NormalTexture;
uniform sampler2D EmissionTexture;

uniform float RandomOffset;
uniform int SamplesFirstRing;
uniform int Rings;
uniform ivec2 ScreenSize;

void main(void) {
  float value = 0.0;
  vec3 finalEmission = vec3(0.0, 0.0, 0.0);

  vec4 Vertex = texture2D(GeometryTexture, gl_FragCoord.xy / ScreenSize);
  vec3 Normal = texture2D(NormalTexture, gl_FragCoord.xy / ScreenSize).xyz;

  int Samples = 0;

  for (int i = 1; i <= Rings; i++) {
    float Radius = 200.0 * i / Vertex.a / Rings;
    float Coeff = 6.28319 / (SamplesFirstRing * i);
    for (int j = 0; j < SamplesFirstRing * i; j++) {
      Samples++;
      vec2 coord = (gl_FragCoord.xy + Radius * vec2(sin(Coeff * j + RandomOffset), cos(Coeff * j + RandomOffset))) / ScreenSize;
      vec3 Dest = texture2D(GeometryTexture, coord).xyz;
      vec3 dir = Dest - Vertex.xyz;
      float distfactor = pow(2.7183, -0.4 * length(dir));
      value += 1.0 - max(0.0, dot(normalize(dir), Normal)) * distfactor;

      vec4 Emission = texture2D(EmissionTexture, coord);
      finalEmission += 2.0 * Emission.rgb * Emission.a * Emission.a / (Emission.a * Emission.a + dot(dir, dir)) * max(0.0, dot(normalize(dir), Normal));
    }
  }

  value /= Samples;
  finalEmission /= Samples;
  gl_FragColor = vec4(finalEmission, value);
}