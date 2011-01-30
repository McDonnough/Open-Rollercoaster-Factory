#version 120

#extension GL_EXT_gpu_shader4 : enable

uniform sampler2D Texture;
uniform sampler2D LightTexture;

uniform int HasTexture;

varying vec3 normal;
varying vec3 Vertex;

void main(void) {
  float dist = length(gl_ModelViewMatrix * vec4(Vertex, 1.0));
  gl_FragDepth = dist / 10000.0;
  
  gl_FragColor = gl_FrontMaterial.diffuse;
  if (HasTexture == 1)
    gl_FragColor *= texture2D(Texture, gl_TexCoord[0].xy);

  vec4 Light = texelFetch2D(LightTexture, ivec2(floor(gl_FragCoord.xy)), 0);
  if (Light.a >= 0.0) {
    gl_FragColor.rgb = gl_FragColor.rgb * Light.rgb;
    gl_FragColor.rgb += Light.rgb * Light.a * gl_FrontMaterial.specular.r;
  }
}