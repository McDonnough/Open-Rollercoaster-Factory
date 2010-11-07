#version 120

#extension GL_EXT_gpu_shader4 : enable

uniform sampler2D MaterialTexture;
uniform sampler2D LightTexture;
uniform sampler2D GTexture;

void main(void) {
  gl_FragDepth = texelFetch2D(GTexture, ivec2(floor(gl_FragCoord.xy)), 0).a / 10000.0;
  vec4 Material = texelFetch2D(MaterialTexture, ivec2(floor(gl_FragCoord.xy)), 0);
  vec4 Light = texelFetch2D(LightTexture, ivec2(floor(gl_FragCoord.xy)), 0);
  gl_FragColor = vec4(Material.rgb, 1.0);
  if (Light.a >= 0.0)
    gl_FragColor.rgb = Material.rgb * Light.rgb + Light.rgb * Light.a * Material.a;
}