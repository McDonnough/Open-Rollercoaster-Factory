#version 120

uniform sampler2D Texture;
uniform sampler2D NormalMap;
uniform sampler2D ReflectionMap;

uniform vec3 ViewPoint;

uniform int HasTexture;
uniform int HasNormalMap;

uniform vec2 Mediums;

varying vec3 Vertex;
varying vec3 Normal;

float Fresnel(float x) {
  float theSQRT = sqrt(max(0.0, 1.0 - pow(Mediums.x / Mediums.y * sin(x), 2.0)));
  float Rs = pow((Mediums.x * cos(x) - Mediums.y * theSQRT) / (Mediums.x * cos(x) + Mediums.y * theSQRT), 2.0);
  float Rp = pow((Mediums.x * theSQRT - Mediums.y * cos(x)) / (Mediums.x * theSQRT + Mediums.y * cos(x)), 2.0);
  return min(1.0, 0.5 * (Rs + Rp));
}

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
  gl_FragData[3] = vec4(0.0, 0.0, 0.0, 1.0);
  gl_FragData[2].rgb = Vertex;
  gl_FragData[2].a = length(vec3(gl_ModelViewMatrix * vec4(Vertex, 1.0)));
  gl_FragData[0] = vec4(gl_FrontMaterial.diffuse.rgb, gl_FrontMaterial.specular.r);
  if (HasTexture == 1)
    gl_FragData[0].rgb *= texture2D(Texture, gl_TexCoord[0].xy).rgb;
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
  vec3 Eye = normalize((gl_ModelViewMatrix * vec4(Vertex, 1.0)).xyz);
  gl_FragData[4] = vec4(GetReflectionColor(normal), gl_FrontMaterial.specular.g * Fresnel(acos(abs(dot(-Eye, normalize(gl_NormalMatrix * normal))))));
  gl_FragData[5] = gl_FrontMaterial.emission * vec4(gl_FragData[0].rgb, 1.0);
  gl_FragData[1] = vec4(normal, gl_FrontMaterial.shininess);
}