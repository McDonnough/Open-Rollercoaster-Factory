#version 120

uniform sampler2D Texture;
uniform ivec2 ScreenSize;
uniform int Samples;

void main(void) {
  gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
  for (int i = 0; i < Samples; i++) {
    for (int j = 0; j < Samples; j++)
      gl_FragColor.rgb += texture2D(Texture, gl_TexCoord[0].xy + vec2(i, j) * 1.0 / (ScreenSize * Samples)).rgb;
  }
  gl_FragColor.rgb /= (Samples * Samples);
  gl_FragColor *= gl_Color;
}