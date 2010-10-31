#version 120

uniform sampler2D MaterialTexture;
uniform sampler2D LightTexture;

void main(void) {
  vec4 Material = texture2D(MaterialTexture, gl_TexCoord[0].xy);
  vec4 Light = texture2D(LightTexture, gl_TexCoord[0].xy);
  gl_FragColor = vec4(Material.rgb, 1.0);
  if (Light.a >= 0.0)
    gl_FragColor.rgb = Material.rgb * Light.rgb + Light.rgb * Light.a * Material.a;
}