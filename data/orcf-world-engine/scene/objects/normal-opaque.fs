#version 120

uniform sampler2D Texture;
uniform sampler2D NormalMap;
uniform sampler2D LightFactorMap;

uniform int HasTexture;
uniform int HasNormalMap;
uniform int HasLightFactorMap;

varying vec3 Vertex;
varying vec3 Normal;
varying vec4 Color;

void main(void) {
  gl_FragData[3].rgb = vec3(0.0, 0.0, 0.0);
  gl_FragData[2].rgb = Vertex;
  gl_FragData[2].a = length(gl_ModelViewMatrix * vec4(Vertex, 1.0));
  vec3 normal = Normal;
  if (HasNormalMap == 1) {
    vec3 q0 = dFdx(Vertex.xyz);
    vec3 q1 = dFdy(Vertex.xyz);
    vec2 st0 = dFdx(gl_TexCoord[0].st);
    vec2 st1 = dFdy(gl_TexCoord[0].st);

    vec3 S = normalize( q0 * st1.t - q1 * st0.t);
    vec3 T = normalize(-q0 * st1.s + q1 * st0.s);

    mat3 M = mat3(-T, -S, normal);
    normal = normalize(M * (vec3(texture2D(NormalMap, gl_TexCoord[0].xy)) - vec3(0.5, 0.5, 0.5)));
  }
  gl_FragData[1] = vec4(normal, gl_FrontMaterial.shininess);
  gl_FragData[0].rgb = gl_FrontMaterial.diffuse.rgb;
  if (HasTexture == 1)
    gl_FragData[0].rgb *= texture2D(Texture, gl_TexCoord[0].xy).rgb;
  gl_FragData[0].a = gl_FrontMaterial.specular.r;
}