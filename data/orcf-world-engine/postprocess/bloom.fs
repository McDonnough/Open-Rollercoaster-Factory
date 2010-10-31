#version 120

uniform sampler2D Tex;

void main(void) {
  gl_FragColor = texture2D(Tex, gl_TexCoord[0].xy);
  gl_FragColor *= gl_FragColor;
}