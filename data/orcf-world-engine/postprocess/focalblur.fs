#version 120

#extension GL_EXT_gpu_shader4 : require

uniform sampler2D SceneTexture;
uniform sampler2D GeometryTexture;

uniform vec2 Screen;
uniform float FocusDistance;
uniform float Strength;

const int SAMPLES = 6;
const int RINGS = 3;

void main(void) {
  float Distance = texture2D(GeometryTexture, gl_TexCoord[0].xy).a;
  float fDiff = abs(FocusDistance - Distance) / FocusDistance;
  gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
  float Factor = 1.0;
  float SampleCount = 1.0;
  float PixelsPerRing = min(2.3, mix(4.6 / FocusDistance, 2.3, 0.5));
  for (int i = 1; i <= RINGS; i++) {
    float Radius = PixelsPerRing * i;
    float Coeff = 6.28319 / (SAMPLES * (0.5 * i + 0.5));
    for (int j = 0; j < int(SAMPLES * (0.5 * i + 0.5)); j++) {
      vec2 tc = gl_TexCoord[0].xy + Radius * vec2(sin(Coeff * j), cos(Coeff * j)) / Screen;
      float d = texture2D(GeometryTexture, tc).a;
      vec3 c = texture2D(SceneTexture, tc).rgb;
      float diff = max(abs(FocusDistance - d) / FocusDistance, fDiff) * mix(FocusDistance / d, 1.0, 0.25);
      float RightBorder = float(RINGS + 1) * diff;
      float AddFac = clamp((RightBorder - float(i)), 0.0, 1.0);
      SampleCount += 1.0;
      Factor += AddFac;
      gl_FragColor.rgb += AddFac * c;
    }
  }
  gl_FragColor.rgb += (SampleCount - Factor + 1.0) * texture2D(SceneTexture, gl_TexCoord[0].xy).rgb;
  gl_FragColor.rgb /= (SampleCount + 1.0);
}