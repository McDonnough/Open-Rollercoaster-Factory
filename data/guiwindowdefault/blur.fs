#version 120

uniform sampler2D BackTex;
uniform sampler2D WinTex;
uniform vec2 Screen;
uniform vec2 BlurAmount;
uniform int UseWinTex;

vec4 BackTexel;

vec2 fitCoords(vec2 Coord) {
  return Coord / Screen;
}

vec4 do_blur(void) {
  return 0.22  * BackTexel
       + 0.20  * texture2D(BackTex, fitCoords(gl_FragCoord.xy + BlurAmount * 1.5))
       + 0.20  * texture2D(BackTex, fitCoords(gl_FragCoord.xy - BlurAmount * 1.5))
       + 0.13  * texture2D(BackTex, fitCoords(gl_FragCoord.xy + BlurAmount * 3.5))
       + 0.13  * texture2D(BackTex, fitCoords(gl_FragCoord.xy - BlurAmount * 3.5))
       + 0.05  * texture2D(BackTex, fitCoords(gl_FragCoord.xy + BlurAmount * 5.5))
       + 0.05  * texture2D(BackTex, fitCoords(gl_FragCoord.xy - BlurAmount * 5.5))
       + 0.01  * texture2D(BackTex, fitCoords(gl_FragCoord.xy + BlurAmount * 7.5))
       + 0.01  * texture2D(BackTex, fitCoords(gl_FragCoord.xy - BlurAmount * 7.5));
}

void main(void) {
  BackTexel = texture2D(BackTex, fitCoords(gl_FragCoord.xy));
  vec4 WinTexel = vec4(1.0, 1.0, 1.0, 1.0);
  if (UseWinTex == 1) {
    WinTexel = texture2D(WinTex, gl_TexCoord[0].xy);
    if (WinTexel.r == 0.0)
      discard;
  }
  gl_FragColor = mix(BackTexel, do_blur(), WinTexel.r);
  if (UseWinTex == 1)
    gl_FragColor.a = 1.0;
}