uniform sampler2D tex;
uniform sampler2D dist;
uniform vec2 blurDirection;
uniform float focusDist;

float lastDist = 0.0;

float calcBlurFactor(float a) {
  lastDist = clamp(pow(abs((a / focusDist) - 1.0), 2.0), 0.0, 1.0);
  return lastDist;
}

void main(void) {
  float cdist = 10000.0 * pow(texture2D(dist, gl_TexCoord[0].xy).r, 2.0);
  vec2 blurFactor = blurDirection * calcBlurFactor(cdist);
  float AblurFactor = length(blurFactor);
  gl_FragColor = 0.16 * texture2D(tex, gl_TexCoord[0].xy)
               + 0.13 * texture2D(tex, gl_TexCoord[0].xy + 0.002 * blurFactor * (((calcBlurFactor(0.8 * abs(10000.0 * pow(texture2D(dist, gl_TexCoord[0].xy + 0.002 * blurFactor).r, 2.0))) > AblurFactor) && (lastDist > focusDist)) ? 0.0 : 1.0))
               + 0.13 * texture2D(tex, gl_TexCoord[0].xy - 0.002 * blurFactor * (((calcBlurFactor(0.8 * abs(10000.0 * pow(texture2D(dist, gl_TexCoord[0].xy - 0.002 * blurFactor).r, 2.0))) > AblurFactor) && (lastDist > focusDist)) ? 0.0 : 1.0))
               + 0.11 * texture2D(tex, gl_TexCoord[0].xy + 0.004 * blurFactor * (((calcBlurFactor(0.8 * abs(10000.0 * pow(texture2D(dist, gl_TexCoord[0].xy + 0.004 * blurFactor).r, 2.0))) > AblurFactor) && (lastDist > focusDist)) ? 0.0 : 1.0))
               + 0.11 * texture2D(tex, gl_TexCoord[0].xy - 0.004 * blurFactor * (((calcBlurFactor(0.8 * abs(10000.0 * pow(texture2D(dist, gl_TexCoord[0].xy - 0.004 * blurFactor).r, 2.0))) > AblurFactor) && (lastDist > focusDist)) ? 0.0 : 1.0))
               + 0.08 * texture2D(tex, gl_TexCoord[0].xy + 0.006 * blurFactor * (((calcBlurFactor(0.8 * abs(10000.0 * pow(texture2D(dist, gl_TexCoord[0].xy + 0.006 * blurFactor).r, 2.0))) > AblurFactor) && (lastDist > focusDist)) ? 0.0 : 1.0))
               + 0.08 * texture2D(tex, gl_TexCoord[0].xy - 0.006 * blurFactor * (((calcBlurFactor(0.8 * abs(10000.0 * pow(texture2D(dist, gl_TexCoord[0].xy - 0.006 * blurFactor).r, 2.0))) > AblurFactor) && (lastDist > focusDist)) ? 0.0 : 1.0))
               + 0.06 * texture2D(tex, gl_TexCoord[0].xy + 0.008 * blurFactor * (((calcBlurFactor(0.8 * abs(10000.0 * pow(texture2D(dist, gl_TexCoord[0].xy + 0.008 * blurFactor).r, 2.0))) > AblurFactor) && (lastDist > focusDist)) ? 0.0 : 1.0))
               + 0.06 * texture2D(tex, gl_TexCoord[0].xy - 0.008 * blurFactor * (((calcBlurFactor(0.8 * abs(10000.0 * pow(texture2D(dist, gl_TexCoord[0].xy - 0.008 * blurFactor).r, 2.0))) > AblurFactor) && (lastDist > focusDist)) ? 0.0 : 1.0))
               + 0.04 * texture2D(tex, gl_TexCoord[0].xy + 0.010 * blurFactor * (((calcBlurFactor(0.8 * abs(10000.0 * pow(texture2D(dist, gl_TexCoord[0].xy + 0.010 * blurFactor).r, 2.0))) > AblurFactor) && (lastDist > focusDist)) ? 0.0 : 1.0))
               + 0.04 * texture2D(tex, gl_TexCoord[0].xy - 0.010 * blurFactor * (((calcBlurFactor(0.8 * abs(10000.0 * pow(texture2D(dist, gl_TexCoord[0].xy - 0.010 * blurFactor).r, 2.0))) > AblurFactor) && (lastDist > focusDist)) ? 0.0 : 1.0));
}