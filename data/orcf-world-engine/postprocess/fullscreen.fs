#version 120

uniform sampler2D Texture;

void main(void) {
  gl_FragColor = texture2D(Texture, gl_TexCoord[0].xy);
}