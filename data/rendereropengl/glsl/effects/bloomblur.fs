uniform sampler2D Tex;
uniform vec2 Screen;
uniform vec2 BlurDirection;

vec2 fitCoords(vec2 Coord) {
  return Coord / Screen;
}

void main(void) {
  gl_FragColor =
         0.2   * texture2D(Tex, fitCoords(gl_FragCoord.xy))
       + 0.15  * texture2D(Tex, fitCoords(gl_FragCoord.xy + BlurDirection * 1.5))
       + 0.15  * texture2D(Tex, fitCoords(gl_FragCoord.xy - BlurDirection * 1.5))
       + 0.09  * texture2D(Tex, fitCoords(gl_FragCoord.xy + BlurDirection * 3.5))
       + 0.09  * texture2D(Tex, fitCoords(gl_FragCoord.xy - BlurDirection * 3.5))
       + 0.07  * texture2D(Tex, fitCoords(gl_FragCoord.xy + BlurDirection * 5.5))
       + 0.07  * texture2D(Tex, fitCoords(gl_FragCoord.xy - BlurDirection * 5.5))
       + 0.05  * texture2D(Tex, fitCoords(gl_FragCoord.xy + BlurDirection * 7.5))
       + 0.05  * texture2D(Tex, fitCoords(gl_FragCoord.xy - BlurDirection * 7.5))
       + 0.04  * texture2D(Tex, fitCoords(gl_FragCoord.xy + BlurDirection * 9.5))
       + 0.04  * texture2D(Tex, fitCoords(gl_FragCoord.xy - BlurDirection * 9.5));
  gl_FragColor.a = 1.0;
}