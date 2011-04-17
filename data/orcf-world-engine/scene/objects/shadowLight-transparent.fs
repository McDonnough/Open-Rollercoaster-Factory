#version 120

uniform sampler2D Texture;
uniform int HasTexture;

varying vec3 dir;

void main(void) {
  vec4 color = gl_FrontMaterial.diffuse;
  if (HasTexture == 1)
    color *= texture2D(Texture, gl_TexCoord[0].xy);
  gl_FragColor.rgb = mix(vec3(0.0, 0.0, 0.0), vec3(1.0 - color.rgb * (1.0 - color.a)), sqrt(color.a));
  gl_FragColor.a = length(dir);
}