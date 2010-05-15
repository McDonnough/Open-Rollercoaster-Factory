#version 120

uniform sampler2D Tex;
uniform vec2 Screen;
uniform vec2 BlurDirection;

vec2 fitCoords(vec2 Coord) {
  return Coord / Screen;
}

void main(void) {
  gl_FragColor =
         0.080   * texture2D(Tex, fitCoords(gl_FragCoord.xy))
       + 0.065  * texture2D(Tex, fitCoords(gl_FragCoord.xy + BlurDirection * 1.5))
       + 0.065  * texture2D(Tex, fitCoords(gl_FragCoord.xy - BlurDirection * 1.5))
       + 0.056  * texture2D(Tex, fitCoords(gl_FragCoord.xy + BlurDirection * 3.5))
       + 0.056  * texture2D(Tex, fitCoords(gl_FragCoord.xy - BlurDirection * 3.5))
       + 0.052  * texture2D(Tex, fitCoords(gl_FragCoord.xy + BlurDirection * 5.5))
       + 0.052  * texture2D(Tex, fitCoords(gl_FragCoord.xy - BlurDirection * 5.5))
       + 0.047  * texture2D(Tex, fitCoords(gl_FragCoord.xy + BlurDirection * 7.5))
       + 0.047  * texture2D(Tex, fitCoords(gl_FragCoord.xy - BlurDirection * 7.5))
       + 0.044  * texture2D(Tex, fitCoords(gl_FragCoord.xy + BlurDirection * 9.5))
       + 0.044  * texture2D(Tex, fitCoords(gl_FragCoord.xy - BlurDirection * 9.5));
       + 0.041  * texture2D(Tex, fitCoords(gl_FragCoord.xy + BlurDirection * 11.5))
       + 0.041  * texture2D(Tex, fitCoords(gl_FragCoord.xy - BlurDirection * 11.5));
       + 0.040  * texture2D(Tex, fitCoords(gl_FragCoord.xy + BlurDirection * 13.5))
       + 0.040  * texture2D(Tex, fitCoords(gl_FragCoord.xy - BlurDirection * 13.5));
       + 0.039  * texture2D(Tex, fitCoords(gl_FragCoord.xy + BlurDirection * 15.5))
       + 0.039  * texture2D(Tex, fitCoords(gl_FragCoord.xy - BlurDirection * 15.5));
       + 0.038  * texture2D(Tex, fitCoords(gl_FragCoord.xy + BlurDirection * 17.5))
       + 0.038  * texture2D(Tex, fitCoords(gl_FragCoord.xy - BlurDirection * 17.5));
       + 0.037  * texture2D(Tex, fitCoords(gl_FragCoord.xy + BlurDirection * 19.5))
       + 0.037  * texture2D(Tex, fitCoords(gl_FragCoord.xy - BlurDirection * 19.5));
  gl_FragColor.a = 1.0;
}