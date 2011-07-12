#version 120

#extension GL_EXT_gpu_shader4 : require

uniform sampler2D MaterialTexture;
uniform sampler2D LightTexture;
uniform sampler2D SpecularTexture;
uniform sampler2D GTexture;
uniform sampler2D MaterialMap;
uniform sampler2D ReflectionTexture;

uniform float WaterHeight;
uniform float WaterRefractionMode;

uniform float FogStrength;
uniform vec3 FogColor;

void main(void) {
  ivec2 Offset = ivec2(0, 0);
  ivec2 Coords = ivec2(floor(gl_FragCoord.xy));
  for (int i = 3; i >= 0; i--)
    for (int j = 3; j >= 0; j--) {
      vec3 diff = 255.0 * texelFetch2D(MaterialMap, Coords + ivec2(i, j), 0).rgb;
      if (max(max(diff.x, diff.y), diff.z) < 0.5)
        Offset = ivec2(i, j);
    }
  Coords += Offset;

  vec4 Vertex = texelFetch2D(GTexture, Coords, 0);
  gl_FragDepth = Vertex.a / 10000.0;
  vec4 Material = texelFetch2D(MaterialTexture, Coords, 0);
  vec4 Light = texelFetch2D(LightTexture, Coords, 0);
  vec4 Reflection = texelFetch2D(ReflectionTexture, Coords, 0);
  gl_FragColor = vec4(Material.rgb, 1.0);
  if (Light.a >= 0.0) {
    gl_FragColor.rgb *= Light.rgb;
    gl_FragColor.rgb = mix(gl_FragColor.rgb, Reflection.rgb, Reflection.a);
    gl_FragColor.rgb += texelFetch2D(SpecularTexture, Coords, 0).rgb * abs(Material.a);
    gl_FragColor.rgb = mix(gl_FragColor.rgb, 0.5 * gl_LightSource[0].diffuse.rgb, clamp(2.0 * gl_FragDepth, 0.0, 1.0));
  }
  gl_FragColor.rgb = mix(gl_FragColor.rgb, FogColor, 1.0 - pow(0.5, mix(Vertex.a * FogStrength, max(0.0, WaterHeight - Vertex.y), WaterRefractionMode)));
}