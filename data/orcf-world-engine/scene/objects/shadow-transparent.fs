#version 120

uniform sampler2D Texture;
uniform int HasTexture;

varying vec3 VData;

void main(void) {
  vec4 color = gl_FrontMaterial.diffuse;
  if (HasTexture == 1)
    color *= texture2D(Texture, gl_TexCoord[0].xy);
  gl_FragColor = mix(vec4(0.0, 0.0, 0.0, 0.0), vec4(1.0 - color.rgb * (1.0 - color.a), VData.y), color.a);
  gl_FragDepth = 1.0 - VData.y / 1000.0;
}