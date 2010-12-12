#version 120

uniform sampler2D Tex;
uniform vec2 BlurDirection;

void main(void) {
  gl_FragColor =
         0.1793 * texture2D(Tex, gl_TexCoord[0].xy)
       + 0.0893 * texture2D(Tex, gl_TexCoord[0].xy + BlurDirection * 1.5)
       + 0.0893 * texture2D(Tex, gl_TexCoord[0].xy - BlurDirection * 1.5)
       + 0.0882 * texture2D(Tex, gl_TexCoord[0].xy + BlurDirection * 3.5)
       + 0.0882 * texture2D(Tex, gl_TexCoord[0].xy - BlurDirection * 3.5)
       + 0.0865 * texture2D(Tex, gl_TexCoord[0].xy + BlurDirection * 5.5)
       + 0.0865 * texture2D(Tex, gl_TexCoord[0].xy - BlurDirection * 5.5)
       + 0.0840 * texture2D(Tex, gl_TexCoord[0].xy + BlurDirection * 7.5)
       + 0.0840 * texture2D(Tex, gl_TexCoord[0].xy - BlurDirection * 7.5)
       + 0.0801 * texture2D(Tex, gl_TexCoord[0].xy + BlurDirection * 9.5)
       + 0.0801 * texture2D(Tex, gl_TexCoord[0].xy - BlurDirection * 9.5)
       + 0.0770 * texture2D(Tex, gl_TexCoord[0].xy + BlurDirection * 11.5)
       + 0.0770 * texture2D(Tex, gl_TexCoord[0].xy - BlurDirection * 11.5)
       + 0.0725 * texture2D(Tex, gl_TexCoord[0].xy + BlurDirection * 13.5)
       + 0.0725 * texture2D(Tex, gl_TexCoord[0].xy - BlurDirection * 13.5)
       + 0.0672 * texture2D(Tex, gl_TexCoord[0].xy + BlurDirection * 15.5)
       + 0.0672 * texture2D(Tex, gl_TexCoord[0].xy - BlurDirection * 15.5)
       + 0.0613 * texture2D(Tex, gl_TexCoord[0].xy + BlurDirection * 17.5)
       + 0.0613 * texture2D(Tex, gl_TexCoord[0].xy - BlurDirection * 17.5)
       + 0.0546 * texture2D(Tex, gl_TexCoord[0].xy + BlurDirection * 19.5)
       + 0.0546 * texture2D(Tex, gl_TexCoord[0].xy - BlurDirection * 19.5)
       + 0.0473 * texture2D(Tex, gl_TexCoord[0].xy + BlurDirection * 21.5)
       + 0.0473 * texture2D(Tex, gl_TexCoord[0].xy - BlurDirection * 21.5)
       + 0.0392 * texture2D(Tex, gl_TexCoord[0].xy + BlurDirection * 23.5)
       + 0.0392 * texture2D(Tex, gl_TexCoord[0].xy - BlurDirection * 23.5)
       + 0.0305 * texture2D(Tex, gl_TexCoord[0].xy + BlurDirection * 25.5)
       + 0.0305 * texture2D(Tex, gl_TexCoord[0].xy - BlurDirection * 25.5)
       + 0.0210 * texture2D(Tex, gl_TexCoord[0].xy + BlurDirection * 27.5)
       + 0.0210 * texture2D(Tex, gl_TexCoord[0].xy - BlurDirection * 27.5)
       + 0.0109 * texture2D(Tex, gl_TexCoord[0].xy + BlurDirection * 29.5)
       + 0.0109 * texture2D(Tex, gl_TexCoord[0].xy - BlurDirection * 29.5);
  gl_FragColor.a = 1.0;
}