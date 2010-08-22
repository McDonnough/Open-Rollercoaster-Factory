#version 120

uniform sampler2D Image;
uniform ivec2 Size;
uniform int Samples;

void main(void) {
  gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
  for (int i = 0; i < Samples; i++)
    for (int j = 0; j < Samples; j++)
      gl_FragColor += texture2D(Image, 0.001 * (gl_TexCoord[0].xy + 1000 * vec2(i, j) / Samples / Size));
  gl_FragColor = gl_FragColor / Samples / Samples;
  gl_FragColor.a = 1.0;
}