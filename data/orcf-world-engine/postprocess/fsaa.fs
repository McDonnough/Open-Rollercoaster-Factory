#version 120

#extension GL_EXT_gpu_shader4 : enable

uniform sampler2D Texture;
uniform ivec2 ScreenSize;
uniform int Samples;

void main(void) {
  gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
  for (int i = 0; i < Samples; i++) {
    for (int j = 0; j < Samples; j++)
      gl_FragColor.rgb += texelFetch2D(Texture, Samples * ivec2(floor(gl_FragCoord.xy)) + ivec2(i, j), 0).rgb;
  }
  gl_FragColor.rgb /= (Samples * Samples);
  gl_FragColor *= gl_Color;
}