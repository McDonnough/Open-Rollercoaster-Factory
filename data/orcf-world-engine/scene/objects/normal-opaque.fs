#version 120

uniform sampler2D Texture;
uniform sampler2D NormalMap;
uniform sampler2D ReflectionMap;

uniform vec3 ViewPoint;
uniform vec3 Mirror;

uniform int HasTexture;
uniform int HasNormalMap;

uniform vec2 Mediums;

varying vec3 Vertex;
varying vec3 OrigVertex;
varying vec3 Normal;
varying vec3 Tangent;
varying vec3 Bitangent;
varying vec3 MirrorVec;

float Fresnel(float x) {
  float theSQRT = sqrt(max(0.0, 1.0 - pow(Mediums.x / Mediums.y * sin(x), 2.0)));
  float Rs = pow((Mediums.x * cos(x) - Mediums.y * theSQRT) / (Mediums.x * cos(x) + Mediums.y * theSQRT), 2.0);
  float Rp = pow((Mediums.x * theSQRT - Mediums.y * cos(x)) / (Mediums.x * theSQRT + Mediums.y * cos(x)), 2.0);
  return min(1.0, 0.5 * (Rs + Rp));
}

vec3 GetReflectionColor(vec3 vector) {
  vector = normalize(OrigVertex + reflect(normalize(Vertex - ViewPoint), -vector));
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
  gl_FragData[0] = vec4(gl_FrontMaterial.diffuse.rgb, gl_FrontMaterial.specular.r);
  vec3 normal = Normal;
  float displacement = 0.0;
  float displacementHeight = gl_FrontMaterial.specular.b;
  vec3 Eye = normalize((gl_ModelViewMatrix * vec4(Vertex, 1.0)).xyz);
  vec2 coords = gl_TexCoord[0].xy;
  if (HasNormalMap == 1) {
    mat3 M = mat3(Tangent, Bitangent, Normal);

    // IF [ NEQ owe.pom 1 ]
    vec4 BumpColor = texture2D(NormalMap, coords);
    normal = normalize(M * (BumpColor.rgb - vec3(0.5, 0.5, 0.5)));
    displacement = (BumpColor.a - 1.0) * displacementHeight;
    // END
    // IF [ EQ owe.pom 1 ]
    vec4 BumpColor = vec4(0.5, 0.5, 1.0, 1.0);

    mat3 _M = transpose(M);

    int SampleCount = int(ceil(mix(45.0, 5.0, pow(abs(dot(normalize(Vertex - ViewPoint), Normal)), 2.0))));

    vec3 tsEye = _M * (Vertex - ViewPoint);
    tsEye /= abs(tsEye.z);
    tsEye *= displacementHeight;
    tsEye /= SampleCount;

    for (int i = 0; i < SampleCount; i++) {
      BumpColor = texture2D(NormalMap, coords);
      if ((BumpColor.a - 1.0) * displacementHeight >= displacement)
        break;
      coords += tsEye.xy;
      displacement += tsEye.z;
    }
    float factor = -0.5;
    for (int i = 0; i < 5; i++) {
      coords += factor * tsEye.xy;
      displacement += factor * tsEye.z;
      BumpColor = texture2D(NormalMap, coords);
      factor = 0.5 * abs(factor) * sign(displacement - (BumpColor.a - 1.0) * displacementHeight);
    }
    normal = normalize(M * (BumpColor.rgb - vec3(0.5, 0.5, 0.5)));

      // IF [ EQ owe.pom.shadows 1 ]
      if (dot(gl_LightSource[0].position.xyz - Vertex, normal) > 0.0) {
        SampleCount = int(ceil(mix(90.0, 32.0, pow(abs(dot(normalize(gl_LightSource[0].position.xyz - Vertex), Normal)), 2.0))));

        vec3 tsSun = _M * (gl_LightSource[0].position.xyz - Vertex);
        tsSun /= abs(tsSun.z);
        tsSun *= max(-displacement, 0.1);
        tsSun /= SampleCount;

        float h = displacement;
        vec2 shadowCoords = coords;

        float diff = 0.0;
        for (int i = 0; i < SampleCount; i++) {
          shadowCoords += tsSun.xy;
          h += tsSun.z;
          vec4 tmpBumpColor = texture2D(NormalMap, shadowCoords);
          diff = max(diff, ((tmpBumpColor.a - 1.0) * displacementHeight) - (h + 0.1 * displacementHeight));
        }
        gl_FragData[3].a = 1.0 - 100.0 * diff;
      }
      // END
    // END
  }
  if (gl_FrontMaterial.specular.g > 0.0)
    gl_FragData[4] = vec4(GetReflectionColor(normal), gl_FrontMaterial.specular.g * Fresnel(acos(abs(dot(-Eye, normalize(gl_NormalMatrix * normal))))));
  else
    gl_FragData[4] = vec4(0.0, 0.0, 0.0, 0.0);
  if (HasTexture == 1)
    gl_FragData[0].rgb *= texture2D(Texture, coords).rgb;
  gl_FragData[5] = gl_FrontMaterial.emission * vec4(gl_FragData[0].rgb, 1.0);
  gl_FragData[1] = vec4(normal, gl_FrontMaterial.shininess);
  gl_FragData[2].rgb = Vertex + (displacementHeight + displacement) * Normal;
  gl_FragData[2].a = length(vec3(gl_ModelViewMatrix * vec4(gl_FragData[2].rgb, 1.0)));
  vec2 projected = (gl_ModelViewProjectionMatrix * vec4(Vertex + displacement * Normal, 1.0)).zw;
  gl_FragDepth = sqrt(projected.x / projected.y);
}