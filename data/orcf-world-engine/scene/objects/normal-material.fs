#version 120

#extension GL_EXT_gpu_shader4 : enable

uniform sampler2D Texture;
uniform sampler2D LightTexture;
uniform sampler2D MaterialMap;

uniform int HasTexture;

uniform ivec3 MaterialID;

varying vec3 normal;
varying vec3 Vertex;

void main(void) {
  float dist = length(gl_ModelViewMatrix * vec4(Vertex, 1.0));
  gl_FragDepth = dist / 10000.0;
  
  gl_FragColor = gl_FrontMaterial.diffuse;
  if (HasTexture == 1)
    gl_FragColor *= texture2D(Texture, gl_TexCoord[0].xy);

  ivec2 Offset = ivec2(0, 0);
  ivec2 Coords = ivec2(floor(gl_FragCoord.xy));
  for (int i = 3; i >= 0; i--)
    for (int j = 3; j >= 0; j--) {
      vec3 diff = 255.0 * texelFetch2D(MaterialMap, Coords + ivec2(i, j), 0).rgb - MaterialID;
      if (max(max(abs(diff.x), abs(diff.y)), abs(diff.z)) < 0.5)
        Offset = ivec2(i, j);
      }
  Coords += Offset;
  vec4 Light = texelFetch2D(LightTexture, Coords, 0);
  if (Light.a >= 0.0) {
    gl_FragColor.rgb = gl_FragColor.rgb * Light.rgb;
    gl_FragColor.rgb += Light.rgb * Light.a * gl_FrontMaterial.specular.r;
  }
}