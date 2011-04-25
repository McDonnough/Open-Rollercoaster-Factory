#version 120

#extension GL_EXT_gpu_shader4 : enable

uniform sampler2D GeometryTexture;
uniform sampler2D NormalTexture;
uniform sampler2D ShadowTexture;
uniform sampler2D MaterialTexture;
uniform int UseShadow;
uniform int Samples;

// IF [ EQ owe.shadows.light 1 ]
vec2 ProjectShadowVertex(vec3 vector) {
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
  return texCoord / vec2(3.0, 2.0);
}
// END

void main(void) {
  ivec2 Coords = ivec2(floor(gl_FragCoord.xy));

  vec4 AllCoord = texelFetch2D(GeometryTexture, Coords, 0);

  vec3 Vertex = AllCoord.rgb;
  vec4 Normal = texelFetch2D(NormalTexture, Coords, 0);
  vec4 Material = texelFetch2D(MaterialTexture, Coords, 0);

  vec3 Light = gl_LightSource[1].position.xyz - Vertex;

  float dotprod = max(0.0, dot(normalize(Normal.xyz), normalize(Light)));
  gl_FragColor.rgb = dotprod * gl_LightSource[1].diffuse.rgb;

  vec3 factor = vec3(2.0, 2.0, 2.0);

  float attenuation = gl_LightSource[1].diffuse.a * (gl_LightSource[1].ambient.a * gl_LightSource[1].ambient.a / (gl_LightSource[1].ambient.a * gl_LightSource[1].ambient.a + dot(Light, Light)));

// IF [ EQ owe.shadows.light 1 ]
  if (UseShadow == 1 && dotprod > 0.0) {
  // IF [ NEQ owe.shadows.light.blur 1 ]
    vec4 ShadowColor = texture2D(ShadowTexture, ProjectShadowVertex(-Light));
    if (dot(Light, Light) > ShadowColor.a * ShadowColor.a * 1.05 * 1.05)
      factor -= 2.0 * ShadowColor.rgb;
  // END
  // IF [ EQ owe.shadows.light.blur 1 ]
    int SampleCount = (Samples * 2 + 1) * (Samples * 2 + 1);
    vec3 bvrl = 0.025 * normalize(cross(-Light, vec3(0.0, 1.0, 0.0)));
    vec3 bvud = 0.025 * normalize(cross(-Light, bvrl));
    for (int i = -Samples; i <= Samples; i++)
      for (int j = -Samples; j <= Samples; j++) {
        vec4 ShadowColor = texture2D(ShadowTexture, ProjectShadowVertex(normalize(-Light) + i * bvrl + j * bvud));
        if (dot(Light, Light) > ShadowColor.a * ShadowColor.a * 1.05 * 1.05)
          factor -= 2.0 * ShadowColor.rgb / SampleCount;
      }

  // END
  }
// END


  factor = min(factor, vec3(1.0, 1.0, 1.0));
  gl_FragColor.rgb *= factor * attenuation;

  vec4 v = (gl_ModelViewMatrix * vec4(Vertex, 1.0));
  vec3 Eye = normalize(-v.xyz);
  vec3 Reflected = normalize(reflect(-normalize((gl_ModelViewMatrix * vec4(gl_LightSource[1].position.xyz, 1.0) - v).xyz), normalize(gl_NormalMatrix * Normal.xyz)));
  gl_FragColor.a = pow(max(dot(Reflected, Eye), 0.0), Normal.a) * length(factor) / sqrt(3.0) * attenuation;

  if (abs(Normal.x) + abs(Normal.y) + abs(Normal.z) == 0.0)
    gl_FragColor.a = -1.0;
}