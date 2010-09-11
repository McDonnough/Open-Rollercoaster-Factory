#version 120

uniform sampler2D ModelTexture;
uniform int UseTexture;

varying float dist;

void main(void) {
  gl_FragDepth = 1.0 - dist / 256.0;
  gl_FragColor = vec4(1.0, 1.0, 1.0, dist);
  if (UseTexture == 1)
    gl_FragColor.rgb *= texture2D(ModelTexture, gl_TexCoord[0].xy).a;
}
