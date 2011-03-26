#version 120

#extension GL_EXT_gpu_shader4 : enable

uniform sampler2D Texture;
uniform sampler2D LightTexture;
uniform sampler2D MaterialMap;
uniform sampler2D NormalMap;
uniform sampler2D ReflectionMap;

uniform vec3 FogColor;
uniform float FogStrength;

uniform int HasTexture;
uniform vec3 ViewPoint;

uniform ivec3 MaterialID;

varying vec3 normal;
varying vec3 Vertex;

vec3 GetReflectionColor(vec3 vector) {
  vector = reflect(normalize(Vertex - ViewPoint), -vector);
  float mx = max(abs(vector.x), max(abs(vector.y), abs(vector.z)));
  vector = vector / mx;
  vec2 texCoord = vec2(0, 0);
  if (vector.z <= -0.99)
    texCoord = 0.5 + 0.5 * vector.xy * vec2(0.99, 0.99);
  if (vector.z >= 0.99)
    texCoord = 0.5 + 0.5 * vector.xy * vec2(-0.99, 0.99) + vec2(2.0, 0.0);
  if (vector.x <= -0.99)
    texCoord = 0.5 + 0.5 * vector.zy * vec2(-0.99, 0.99) + vec2(0.0, 1.0);
  if (vector.x >= 0.99)
    texCoord = 0.5 + 0.5 * vector.zy * vec2(0.99, 0.99) + vec2(1.0, 0.0);
  if (vector.y <= -0.99)
    texCoord = 0.5 + 0.5 * vector.xz * vec2(0.99, -0.99) + vec2(1.0, 1.0);
  if (vector.y >= 0.99)
    texCoord = 0.5 + 0.5 * vector.xz * vec2(0.99, 0.99) + vec2(2.0, 1.0);
  texCoord /= vec2(3.0, 2.0);
  return texture2D(ReflectionMap, texCoord).rgb;
}

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
  vec3 Normal = texelFetch2D(NormalMap, Coords, 0).rgb;
  gl_FragColor.rgb = mix(gl_FragColor.rgb, GetReflectionColor(Normal), gl_FrontMaterial.specular.g);
  vec4 Light = texelFetch2D(LightTexture, Coords, 0);
  if (Light.a >= 0.0) {
    gl_FragColor.rgb = gl_FragColor.rgb * Light.rgb;
    gl_FragColor.rgb += Light.rgb * Light.a * (gl_FrontMaterial.specular.r + gl_FrontMaterial.specular.g);
  }
  gl_FragColor.rgb = mix(gl_FragColor.rgb, FogColor, 1.0 - pow(0.5, dist * FogStrength));
}