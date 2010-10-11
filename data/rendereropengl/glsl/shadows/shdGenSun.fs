#version 120

uniform sampler2D ModelTexture;
uniform int UseTexture;
uniform vec4 MeshColor;

varying float dist;

void main(void) {
  gl_FragDepth = 1.0 - dist / 256.0;
  gl_FragColor = vec4(1.0, 1.0, 1.0, dist);
  vec4 tex = MeshColor;
  if (UseTexture == 1)
    tex *= texture2D(ModelTexture, gl_TexCoord[0].xy);
  gl_FragColor.rgb *= (1.0 - tex.rgb * (1.0 - tex.a));
  gl_FragColor.rgb *= tex.a;
}
