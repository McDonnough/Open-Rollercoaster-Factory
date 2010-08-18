uniform sampler2D tex;
uniform sampler2D dist;
uniform vec2 blurDirection;
uniform float focusDist;

float lastDist = 0.0;

float calcBlurFactor(float a) {
  lastDist = clamp((pow(0.1, a * 0.428 / focusDist) + pow(a * 0.428 / focusDist, 2.0) - 0.5564) / 0.4436 / 2.0, 0.0, 2.0);
  return lastDist;
}

void main(void) {
  vec2 a = texture2D(dist, gl_TexCoord[0].xy).rg * vec2(256.0, 1.0);
  float cdist = a.x + a.y;
  vec2 blurFactor = blurDirection * calcBlurFactor(cdist);
  float AblurFactor = length(blurFactor);
  gl_FragColor = 0.25 * texture2D(tex, gl_TexCoord[0].xy)
               + 0.20 * texture2D(tex, gl_TexCoord[0].xy + 0.002 * blurFactor * (((calcBlurFactor(0.8 * abs(10000.0 * pow(texture2D(dist, gl_TexCoord[0].xy + 0.002 * blurFactor).r, 2.0))) > AblurFactor) && (lastDist > focusDist)) ? 0.0 : 1.0))
               + 0.20 * texture2D(tex, gl_TexCoord[0].xy - 0.002 * blurFactor * (((calcBlurFactor(0.8 * abs(10000.0 * pow(texture2D(dist, gl_TexCoord[0].xy - 0.002 * blurFactor).r, 2.0))) > AblurFactor) && (lastDist > focusDist)) ? 0.0 : 1.0))
               + 0.10 * texture2D(tex, gl_TexCoord[0].xy + 0.004 * blurFactor * (((calcBlurFactor(0.8 * abs(10000.0 * pow(texture2D(dist, gl_TexCoord[0].xy + 0.004 * blurFactor).r, 2.0))) > AblurFactor) && (lastDist > focusDist)) ? 0.0 : 1.0))
               + 0.10 * texture2D(tex, gl_TexCoord[0].xy - 0.004 * blurFactor * (((calcBlurFactor(0.8 * abs(10000.0 * pow(texture2D(dist, gl_TexCoord[0].xy - 0.004 * blurFactor).r, 2.0))) > AblurFactor) && (lastDist > focusDist)) ? 0.0 : 1.0))
               + 0.075 * texture2D(tex, gl_TexCoord[0].xy + 0.006 * blurFactor * (((calcBlurFactor(0.8 * abs(10000.0 * pow(texture2D(dist, gl_TexCoord[0].xy + 0.006 * blurFactor).r, 2.0))) > AblurFactor) && (lastDist > focusDist)) ? 0.0 : 1.0))
               + 0.075 * texture2D(tex, gl_TexCoord[0].xy - 0.006 * blurFactor * (((calcBlurFactor(0.8 * abs(10000.0 * pow(texture2D(dist, gl_TexCoord[0].xy - 0.006 * blurFactor).r, 2.0))) > AblurFactor) && (lastDist > focusDist)) ? 0.0 : 1.0));
  gl_FragColor.a = 1.0;
}