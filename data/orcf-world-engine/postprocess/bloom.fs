#version 120

#extension GL_EXT_gpu_shader4 : require

uniform sampler2D Tex;
uniform sampler2D HDRColor;

void main(void) {
  vec3 HDRAverage = texelFetch2D(HDRColor, ivec2(0, 0), 0).rgb;
  float HDRLighting = length(HDRAverage) / 1.73;
  float HDRLightingFactor = 1.0 / (HDRLighting * HDRLighting + 0.5) / 1.5;
  gl_FragColor = texture2D(Tex, gl_TexCoord[0].xy) * HDRLightingFactor;
  gl_FragColor.rgb = vec3(pow(15.0, gl_FragColor.r - 2.0), pow(15.0, gl_FragColor.g - 2.0), pow(15.0, gl_FragColor.b - 2.0));
}