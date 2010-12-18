#version 120

#extension GL_EXT_gpu_shader4 : enable

uniform sampler2D Texture;
uniform sampler2D HDRColor;
uniform ivec2 ScreenSize;
uniform int Samples;
uniform float Gamma;

void main(void) {
  vec3 HDRAverage = texelFetch2D(HDRColor, ivec2(0, 0), 0).rgb;
  float HDRLighting = length(HDRAverage) / 1.73;
  float HDRLightingFactor = 1.0 / (HDRLighting * HDRLighting + 0.5) / 1.5;
  gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
  for (int i = 0; i < Samples; i++) {
    for (int j = 0; j < Samples; j++)
      gl_FragColor.rgb += texelFetch2D(Texture, Samples * ivec2(floor(gl_FragCoord.xy)) + ivec2(i, j), 0).rgb;
  }
  gl_FragColor.rgb /= (Samples * Samples);
  gl_FragColor *= gl_Color * HDRLightingFactor;
  gl_FragColor.rgb = vec3(pow(gl_FragColor.r, Gamma), pow(gl_FragColor.g, Gamma), pow(gl_FragColor.b, Gamma));
}