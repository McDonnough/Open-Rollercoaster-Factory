#version 120

uniform sampler2D Tex;
uniform vec2 Screen;

vec2 fitCoords(vec2 Coord) {
  return Coord / Screen;
}

void main(void) {
  gl_FragColor = texture2D(Tex, fitCoords(gl_FragCoord.xy));
  gl_FragColor *= gl_FragColor;
  gl_FragColor *= gl_FragColor;
}