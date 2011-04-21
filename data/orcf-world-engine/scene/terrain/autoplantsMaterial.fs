#version 120

#extension GL_EXT_gpu_shader4 : enable

uniform sampler2D Texture;
uniform sampler2D LightTexture;
uniform sampler2D MaterialMap;
uniform float MaxDist;

uniform vec3 FogColor;
uniform float FogStrength;

uniform float WaterHeight;
uniform float WaterRefractionMode;

varying vec3 Vertex;
varying vec2 texCoord;

void main(void) {
  ivec2 Offset = ivec2(0, 0);
  ivec2 Coords = ivec2(floor(gl_FragCoord.xy));
  for (int i = 3; i >= 0; i--)
    for (int j = 3; j >= 0; j--) {
      vec3 diff = 255.0 * texelFetch2D(MaterialMap, Coords + ivec2(i, j), 0).rgb - vec3(255.0, 255.0, 255.0);
      if (max(max(abs(diff.x), abs(diff.y)), abs(diff.z)) < 0.5)
        Offset = ivec2(i, j);
      }
  Coords += Offset;

  float dist = length(gl_ModelViewMatrix * vec4(Vertex, 1.0));
  gl_FragDepth = dist / 10000.0;
  float alpha = clamp(MaxDist - dist, 0.0, 5.0) * 0.2;
  gl_FragColor = texture2D(Texture, texCoord);
  gl_FragColor.a *= alpha;
  vec4 Light = texelFetch2D(LightTexture, Coords, 0);
  if (Light.a >= 0.0)
    gl_FragColor.rgb = gl_FragColor.rgb * Light.rgb;
  gl_FragColor.rgb = mix(gl_FragColor.rgb, FogColor, 1.0 - pow(0.5, mix(dist * FogStrength, max(0.0, WaterHeight - Vertex.y), WaterRefractionMode)));
}