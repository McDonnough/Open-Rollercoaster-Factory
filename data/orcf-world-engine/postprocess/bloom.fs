#version 120

uniform sampler2D Tex;

void main(void) {
  gl_FragColor = texture2D(Tex, gl_TexCoord[0].xy);
  gl_FragColor.r = (pow(1000.0, gl_FragColor.r) - 1) / 999.0;
  gl_FragColor.g = (pow(1000.0, gl_FragColor.g) - 1) / 999.0;
  gl_FragColor.b = (pow(1000.0, gl_FragColor.b) - 1) / 999.0;
}