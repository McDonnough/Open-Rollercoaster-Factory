#version 120

uniform sampler2D TransparencyMask;
uniform sampler2D Texture;
uniform sampler2D LightFactorMap;
uniform sampler2D NormalMap;
uniform sampler2D ReflectionMap;

uniform vec3 ViewPoint;

uniform vec2 MaskOffset;
uniform vec2 MaskSize;

uniform int HasTexture;
uniform int HasNormalMap;
uniform int HasLightFactorMap;

uniform ivec3 MaterialID;

varying vec3 Vertex;
varying vec3 Normal;

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
  gl_FragData[3].a = 1.0;
  gl_FragData[3].rgb = MaterialID;
  gl_FragData[3].rgb /= 255.0;
  gl_FragData[0] = gl_FrontMaterial.diffuse;
  if (HasTexture == 1)
    gl_FragData[0] *= texture2D(Texture, gl_TexCoord[0].xy);
  if (gl_FragData[0].a < texture2D(TransparencyMask, (gl_FragCoord.xy) / MaskSize + MaskOffset).a)
    discard;
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
  gl_FragData[0].a = gl_FrontMaterial.specular.r;
  gl_FragData[1] = vec4(normal, gl_FrontMaterial.shininess);
  gl_FragData[4] = vec4(GetReflectionColor(normal), gl_FrontMaterial.specular.g);
  gl_FragData[2].rgb = Vertex;
  gl_FragData[2].a = length(gl_ModelViewMatrix * vec4(Vertex, 1.0));
}