#version 120

#extension GL_EXT_gpu_shader4 : enable

uniform sampler2D Texture;
uniform sampler2D LightTexture;
uniform float MaxDist;

uniform vec3 FogColor;
uniform float FogStrength;

varying vec3 normal;
varying vec3 Vertex;
varying vec2 texCoord;

void main(void) {
  float dist = length(gl_ModelViewMatrix * vec4(Vertex, 1.0));
  gl_FragDepth = dist / 10000.0;
  float alpha = clamp(MaxDist - dist, 0.0, 5.0) * 0.2;
  gl_FragColor = texture2D(Texture, texCoord);
  gl_FragColor.a *= alpha;
//   if (gl_FragColor.a < 0.2)
  if (gl_FragColor.a < 0.2)
    discard;
  gl_FragColor.a = 1.0;
  vec4 Light = texelFetch2D(LightTexture, ivec2(floor(gl_FragCoord.xy)), 0);
  if (Light.a >= 0.0)
    gl_FragColor.rgb = gl_FragColor.rgb * Light.rgb;
  gl_FragColor.rgb = mix(gl_FragColor.rgb, FogColor, 1.0 - pow(0.5, dist * FogStrength));
}