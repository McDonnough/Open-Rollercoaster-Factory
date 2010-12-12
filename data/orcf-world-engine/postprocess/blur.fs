#version 120

uniform sampler2D Tex;
uniform vec2 BlurDirection;

void main(void) {
  gl_FragColor =
         0.1176 * texture2D(Tex, gl_TexCoord[0].xy)
       + 0.0583 * texture2D(Tex, gl_TexCoord[0].xy + BlurDirection * 1.0)
       + 0.0583 * texture2D(Tex, gl_TexCoord[0].xy - BlurDirection * 1.0)
       + 0.0566 * texture2D(Tex, gl_TexCoord[0].xy + BlurDirection * 2.0)
       + 0.0566 * texture2D(Tex, gl_TexCoord[0].xy - BlurDirection * 2.0)
       + 0.0534 * texture2D(Tex, gl_TexCoord[0].xy + BlurDirection * 3.0)
       + 0.0534 * texture2D(Tex, gl_TexCoord[0].xy - BlurDirection * 3.0)
       + 0.0502 * texture2D(Tex, gl_TexCoord[0].xy + BlurDirection * 4.0)
       + 0.0502 * texture2D(Tex, gl_TexCoord[0].xy - BlurDirection * 4.0)
       + 0.0457 * texture2D(Tex, gl_TexCoord[0].xy + BlurDirection * 5.0)
       + 0.0457 * texture2D(Tex, gl_TexCoord[0].xy - BlurDirection * 5.0)
       + 0.0407 * texture2D(Tex, gl_TexCoord[0].xy + BlurDirection * 6.0)
       + 0.0407 * texture2D(Tex, gl_TexCoord[0].xy - BlurDirection * 6.0)
       + 0.0352 * texture2D(Tex, gl_TexCoord[0].xy + BlurDirection * 7.0)
       + 0.0352 * texture2D(Tex, gl_TexCoord[0].xy - BlurDirection * 7.0)
       + 0.0294 * texture2D(Tex, gl_TexCoord[0].xy + BlurDirection * 8.0)
       + 0.0294 * texture2D(Tex, gl_TexCoord[0].xy - BlurDirection * 8.0)
       + 0.0237 * texture2D(Tex, gl_TexCoord[0].xy + BlurDirection * 9.0)
       + 0.0237 * texture2D(Tex, gl_TexCoord[0].xy - BlurDirection * 9.0)
       + 0.0182 * texture2D(Tex, gl_TexCoord[0].xy + BlurDirection * 10.0)
       + 0.0182 * texture2D(Tex, gl_TexCoord[0].xy - BlurDirection * 10.0)
       + 0.0131 * texture2D(Tex, gl_TexCoord[0].xy + BlurDirection * 11.0)
       + 0.0131 * texture2D(Tex, gl_TexCoord[0].xy - BlurDirection * 11.0)
       + 0.0086 * texture2D(Tex, gl_TexCoord[0].xy + BlurDirection * 12.0)
       + 0.0086 * texture2D(Tex, gl_TexCoord[0].xy - BlurDirection * 12.0)
       + 0.0049 * texture2D(Tex, gl_TexCoord[0].xy + BlurDirection * 13.0)
       + 0.0049 * texture2D(Tex, gl_TexCoord[0].xy - BlurDirection * 13.0)
       + 0.0022 * texture2D(Tex, gl_TexCoord[0].xy + BlurDirection * 14.0)
       + 0.0022 * texture2D(Tex, gl_TexCoord[0].xy - BlurDirection * 14.0)
       + 0.0006 * texture2D(Tex, gl_TexCoord[0].xy + BlurDirection * 15.0)
       + 0.0006 * texture2D(Tex, gl_TexCoord[0].xy - BlurDirection * 15.0);
  gl_FragColor.a = 1.0;
}