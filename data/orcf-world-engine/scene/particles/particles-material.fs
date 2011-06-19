#version 120

#extension GL_EXT_gpu_shader4 : require

uniform sampler2D Texture;
uniform sampler2D LightTexture;
uniform sampler2D SpecularTexture;
uniform sampler2D MaterialMap;

uniform vec3 FogColor;
uniform float FogStrength;

uniform float WaterHeight;
uniform float WaterRefractionMode;

uniform ivec3 MaterialID;

uniform int Illumination;

varying vec3 Vertex;

void main(void) {
  float dist = length(vec3(gl_ModelViewMatrix * vec4(Vertex, 1.0)));
  gl_FragDepth = dist / 10000.0;

  gl_FragColor = gl_FrontMaterial.diffuse * gl_Color;
  gl_FragColor *= texture2D(Texture, gl_TexCoord[0].xy);

  if (Illumination == 1) {
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
      gl_FragColor.rgb += texelFetch2D(SpecularTexture, Coords, 0).rgb * gl_FrontMaterial.specular.r;
      gl_FragColor.rgb = mix(gl_FragColor.rgb, 0.5 * gl_LightSource[0].diffuse.rgb, clamp(2.0 * gl_FragDepth, 0.0, 1.0));
    }
  }
  else {
    gl_FragColor.rgb *= (gl_LightSource[0].diffuse.rgb + gl_LightSource[0].ambient.rgb);
    gl_FragColor.rgb += gl_FrontMaterial.diffuse.rgb * gl_Color.rgb * gl_FrontMaterial.emission.rgb;
  }
  gl_FragColor.rgb = mix(gl_FragColor.rgb, FogColor, 1.0 - pow(0.5, mix(dist * FogStrength, max(0.0, WaterHeight - Vertex.y), WaterRefractionMode)));
}