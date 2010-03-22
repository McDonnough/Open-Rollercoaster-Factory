uniform sampler2D tex;
uniform sampler2D dist;
uniform vec2 blurDirection;
uniform float focusDist;


void main(void) {
  float cdist = 10000.0 * pow(texture2D(dist, gl_TexCoord[0].xy).r, 2.0);
  vec2 blurFactor = blurDirection * clamp(pow(abs((cdist / focusDist) - 1.0), 2.0), 0.0, 1.0);
  gl_FragColor = 0.16 * texture2D(tex, gl_TexCoord[0].xy)
               + 0.13 * texture2D(tex, gl_TexCoord[0].xy + 0.002 * blurFactor * ((0.8 * abs(10000.0 * pow(texture2D(dist, gl_TexCoord[0].xy + 0.002 * blurFactor).r, 2.0))) <= cdist ? 1.0 : 0.0))
               + 0.13 * texture2D(tex, gl_TexCoord[0].xy - 0.002 * blurFactor * ((0.8 * abs(10000.0 * pow(texture2D(dist, gl_TexCoord[0].xy - 0.002 * blurFactor).r, 2.0))) <= cdist ? 1.0 : 0.0))
               + 0.11 * texture2D(tex, gl_TexCoord[0].xy + 0.004 * blurFactor * ((0.8 * abs(10000.0 * pow(texture2D(dist, gl_TexCoord[0].xy + 0.004 * blurFactor).r, 2.0))) <= cdist ? 1.0 : 0.0))
               + 0.11 * texture2D(tex, gl_TexCoord[0].xy - 0.004 * blurFactor * ((0.8 * abs(10000.0 * pow(texture2D(dist, gl_TexCoord[0].xy - 0.004 * blurFactor).r, 2.0))) <= cdist ? 1.0 : 0.0))
               + 0.08 * texture2D(tex, gl_TexCoord[0].xy + 0.006 * blurFactor * ((0.8 * abs(10000.0 * pow(texture2D(dist, gl_TexCoord[0].xy + 0.006 * blurFactor).r, 2.0))) <= cdist ? 1.0 : 0.0))
               + 0.08 * texture2D(tex, gl_TexCoord[0].xy - 0.006 * blurFactor * ((0.8 * abs(10000.0 * pow(texture2D(dist, gl_TexCoord[0].xy - 0.006 * blurFactor).r, 2.0))) <= cdist ? 1.0 : 0.0))
               + 0.06 * texture2D(tex, gl_TexCoord[0].xy + 0.008 * blurFactor * ((0.8 * abs(10000.0 * pow(texture2D(dist, gl_TexCoord[0].xy + 0.008 * blurFactor).r, 2.0))) <= cdist ? 1.0 : 0.0))
               + 0.06 * texture2D(tex, gl_TexCoord[0].xy - 0.008 * blurFactor * ((0.8 * abs(10000.0 * pow(texture2D(dist, gl_TexCoord[0].xy - 0.008 * blurFactor).r, 2.0))) <= cdist ? 1.0 : 0.0))
               + 0.04 * texture2D(tex, gl_TexCoord[0].xy + 0.010 * blurFactor * ((0.8 * abs(10000.0 * pow(texture2D(dist, gl_TexCoord[0].xy + 0.010 * blurFactor).r, 2.0))) <= cdist ? 1.0 : 0.0))
               + 0.04 * texture2D(tex, gl_TexCoord[0].xy - 0.010 * blurFactor * ((0.8 * abs(10000.0 * pow(texture2D(dist, gl_TexCoord[0].xy - 0.010 * blurFactor).r, 2.0))) <= cdist ? 1.0 : 0.0));
}