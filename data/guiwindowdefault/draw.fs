#version 120

uniform sampler2D Mask;

varying vec3 Vertex;

float fpart(float a) {
  return a - floor(a);
}

void main(void) {
  vec4 MaskColor = texture2D(Mask, gl_TexCoord[0].xy);
  float Factor = 1.0 + 0.1 * abs(fpart(Vertex.x / 150.0 - Vertex.y / 600.0) * (0.5 + 0.5 * sin(Vertex.x * 3.1416 / 200.0)));
  gl_FragColor = gl_Color * MaskColor.r;
  gl_FragColor.a *= (1.0 + 4.0 * MaskColor.g);
  gl_FragColor *= Factor;
}