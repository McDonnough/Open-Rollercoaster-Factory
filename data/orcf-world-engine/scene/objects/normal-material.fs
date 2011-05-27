#version 120

#extension GL_EXT_gpu_shader4 : enable

uniform sampler2D Texture;
uniform sampler2D LightTexture;
uniform sampler2D NormalMap;
uniform sampler2D SpecularTexture;
uniform sampler2D MaterialMap;
uniform sampler2D ReflectionMap;

uniform vec3 FogColor;
uniform float FogStrength;

uniform float WaterHeight;
uniform float WaterRefractionMode;

uniform int HasTexture;

uniform ivec3 MaterialID;
uniform vec2 Mediums;

varying vec3 Vertex;

float Fresnel(float x) {
  float theSQRT = sqrt(max(0.0, 1.0 - pow(Mediums.x / Mediums.y * sin(x), 2.0)));
  float Rs = pow((Mediums.x * cos(x) - Mediums.y * theSQRT) / (Mediums.x * cos(x) + Mediums.y * theSQRT), 2.0);
  float Rp = pow((Mediums.x * theSQRT - Mediums.y * cos(x)) / (Mediums.x * theSQRT + Mediums.y * cos(x)), 2.0);
  return min(1.0, 0.5 * (Rs + Rp));
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
  vec4 Light = texelFetch2D(LightTexture, Coords, 0);
  vec3 normal = texelFetch2D(NormalMap, Coords, 0).rgb;
  vec3 Eye = normalize((gl_ModelViewMatrix * vec4(Vertex, 1.0)).xyz);
  float FVal = Fresnel(acos(abs(dot(-Eye, normalize(gl_NormalMatrix * normal)))));
  gl_FragColor.a = mix(gl_FragColor.a, 1.0, FVal);
  if (Light.a >= 0.0) {
    gl_FragColor.rgb = gl_FragColor.rgb * Light.rgb;
    gl_FragColor.rgb = mix(gl_FragColor.rgb, texelFetch2D(ReflectionMap, Coords, 0).rgb, gl_FrontMaterial.specular.g);
    gl_FragColor.rgb += texelFetch2D(SpecularTexture, Coords, 0).rgb * gl_FrontMaterial.specular.r;
    gl_FragColor.rgb = mix(gl_FragColor.rgb, 0.5 * gl_LightSource[0].diffuse.rgb, clamp(2.0 * gl_FragDepth, 0.0, 1.0));
  }
  gl_FragColor.rgb = mix(gl_FragColor.rgb, FogColor, 1.0 - pow(0.5, mix(dist * FogStrength, max(0.0, WaterHeight - Vertex.y), WaterRefractionMode)));
}