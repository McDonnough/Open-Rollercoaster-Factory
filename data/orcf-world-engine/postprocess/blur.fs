#version 120

uniform sampler2D Tex;
uniform vec2 BlurDirection;

void main(void) {
  gl_FragColor =
         0.080  * texture2D(Tex, gl_TexCoord[0].xy)
       + 0.065  * texture2D(Tex, gl_TexCoord[0].xy + BlurDirection * 1.0)
       + 0.065  * texture2D(Tex, gl_TexCoord[0].xy - BlurDirection * 1.0)
       + 0.056  * texture2D(Tex, gl_TexCoord[0].xy + BlurDirection * 2.0)
       + 0.056  * texture2D(Tex, gl_TexCoord[0].xy - BlurDirection * 2.0)
       + 0.052  * texture2D(Tex, gl_TexCoord[0].xy + BlurDirection * 3.0)
       + 0.052  * texture2D(Tex, gl_TexCoord[0].xy - BlurDirection * 3.0)
       + 0.047  * texture2D(Tex, gl_TexCoord[0].xy + BlurDirection * 4.0)
       + 0.047  * texture2D(Tex, gl_TexCoord[0].xy - BlurDirection * 4.0)
       + 0.044  * texture2D(Tex, gl_TexCoord[0].xy + BlurDirection * 5.0)
       + 0.044  * texture2D(Tex, gl_TexCoord[0].xy - BlurDirection * 5.0)
       + 0.041  * texture2D(Tex, gl_TexCoord[0].xy + BlurDirection * 6.0)
       + 0.041  * texture2D(Tex, gl_TexCoord[0].xy - BlurDirection * 6.0)
       + 0.040  * texture2D(Tex, gl_TexCoord[0].xy + BlurDirection * 7.0)
       + 0.040  * texture2D(Tex, gl_TexCoord[0].xy - BlurDirection * 7.0)
       + 0.039  * texture2D(Tex, gl_TexCoord[0].xy + BlurDirection * 8.0)
       + 0.039  * texture2D(Tex, gl_TexCoord[0].xy - BlurDirection * 8.0)
       + 0.038  * texture2D(Tex, gl_TexCoord[0].xy + BlurDirection * 9.0)
       + 0.038  * texture2D(Tex, gl_TexCoord[0].xy - BlurDirection * 9.0)
       + 0.037  * texture2D(Tex, gl_TexCoord[0].xy + BlurDirection * 10.0)
       + 0.037  * texture2D(Tex, gl_TexCoord[0].xy - BlurDirection * 10.0);
  gl_FragColor.a = 1.0;
}