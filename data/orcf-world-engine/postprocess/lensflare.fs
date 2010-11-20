#version 120

uniform sampler2D Texture;

varying float alpha;
varying vec2 LightOnScreen;

void main(void) {
  if (LightOnScreen.x - clamp(LightOnScreen.x, -1.02, 1.02) != 0.0 || LightOnScreen.y - clamp(LightOnScreen.y, -1.02, 1.02) != 0.0)
    discard;
  gl_FragColor = gl_Color * texture2D(Texture, gl_TexCoord[0].xy);
  gl_FragColor.a *= alpha;
}