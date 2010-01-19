uniform sampler2D BackTex;
uniform sampler2D WinTex;
uniform vec2 Screen;
uniform vec2 BlurAmount;

vec4 BackTexel;

vec2 fitCoords(vec2 Coord) {
  return Coord / Screen;
}

vec4 do_blur(void) {
  return 0.25  * BackTexel
       + 0.2   * texture2D(BackTex, fitCoords(gl_FragCoord.xy + BlurAmount * 1.5))
       + 0.2   * texture2D(BackTex, fitCoords(gl_FragCoord.xy - BlurAmount * 1.5))
       + 0.1   * texture2D(BackTex, fitCoords(gl_FragCoord.xy + BlurAmount * 3.5))
       + 0.1   * texture2D(BackTex, fitCoords(gl_FragCoord.xy - BlurAmount * 3.5))
       + 0.075 * texture2D(BackTex, fitCoords(gl_FragCoord.xy + BlurAmount * 5.5))
       + 0.075 * texture2D(BackTex, fitCoords(gl_FragCoord.xy - BlurAmount * 5.5));
}

void main(void) {
  BackTexel = texture2D(BackTex, fitCoords(gl_FragCoord.xy));
  vec4 WinTexel = texture2D(WinTex, gl_TexCoord[0].xy);
  if (WinTexel.a == 0.0)
    discard;
  gl_FragColor = mix(BackTexel, do_blur(), WinTexel.r);
  gl_FragColor.a = 1.0;
}