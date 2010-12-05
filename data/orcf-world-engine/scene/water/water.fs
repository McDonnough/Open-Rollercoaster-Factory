#version 120

uniform sampler2D HeightMap;
uniform sampler2D ReflectTex;
uniform sampler2D RefractTex;
uniform sampler2D BumpMap;
uniform sampler2D GeometryMap;
uniform float Height;
uniform vec2 TerrainSize;
uniform vec2 ScreenSize;
uniform vec2 BumpOffset;

varying vec2 Vertex;

float Fresnel(float x) {
  float Rs = pow((cos(x) - 1.33 * sqrt(1.0 - pow(1.0 / 1.33 * sin(x), 2.0))) / (cos(x) + 1.33 * sqrt(1.0 - pow(1.0 / 1.33 * sin(x), 2.0))), 2.0);
  float Rp = pow((sqrt(1.0 - pow(1.0 / 1.33 * sin(x), 2.0)) - 1.33 * cos(x)) / (sqrt(1.0 - pow(1.0 / 1.33 * sin(x), 2.0)) + 1.33 * cos(x)), 2.0);
  return 0.5 * (Rs + Rp);
}

void main(void) {
  vec2 hm = texture2D(HeightMap, Vertex / TerrainSize).gb;
  if (abs(256.0 * hm.r - Height) > 0.1)
    discard;

  vec3 Position = vec3(Vertex.x, Height, Vertex.y);

  vec4 bumpColor = (-1.0 + 2.0 * texture2D(BumpMap, (Vertex + BumpOffset) / 15.0)) - (-1.0 + 2.0 * texture2D(BumpMap, (Vertex + BumpOffset.yx) / 7.5 + 0.5));
  vec3 normal = normalize((bumpColor.rbg) + vec3(0.0, 1.0, 0.0));
  vec3 Eye = normalize((gl_ModelViewMatrix * vec4(Position, 1.0)).xyz);

  vec4 RealPosition = gl_ModelViewProjectionMatrix * vec4(Position, 1.0);
  float PixelSceneHeight = texture2D(GeometryMap, 0.5 + 0.5 * RealPosition.xy / RealPosition.w).y;
  float OffsetFactor = 1.0 - clamp(pow(0.5, Height - PixelSceneHeight), 0.0, 1.0);

  normal = mix(vec3(0.0, 1.0, 0.0), normal, OffsetFactor);

  vec3 RefractedOffset = normal * vec3(1.0, 0.0, 1.0);
  vec4 RefractedPosition = gl_ModelViewProjectionMatrix * vec4(Position + RefractedOffset, 1.0);

  vec3 ReflectedOffset = normal * vec3(1.0, 0.0, 1.0);
  vec4 ReflectedPosition = gl_ModelViewProjectionMatrix * vec4(Position + ReflectedOffset, 1.0);

  vec3 SceneVertex = texture2D(GeometryMap, 0.5 + 0.5 * RefractedPosition.xy / RefractedPosition.w).xyz;
  float HeightFactor = clamp(pow(0.82, distance(SceneVertex, vec3(Vertex.x, Height, Vertex.y))), 0.0, 1.0);

  gl_FragData[2] = vec4(Vertex.x, Height, Vertex.y, length(vec3(gl_ModelViewMatrix * vec4(Vertex.x, Height, Vertex.y, 1.0))));
  gl_FragData[1] = vec4(normal, 150.0);
  gl_FragData[0] = vec4(1.0, 1.0, 1.0, -0.90);
  float ReflectionCoefficient = Fresnel(acos(dot(-Eye, normalize(gl_NormalMatrix * normal))));
  gl_FragData[0].rgb = ReflectionCoefficient * texture2D(ReflectTex, 0.5 + 0.5 * ReflectedPosition.xy / ReflectedPosition.w).rgb;
  gl_FragData[0].rgb += mix(vec3(0.03, 0.24, 0.29) * 4.0 * gl_LightSource[0].ambient.rgb, (1.0 - ReflectionCoefficient) * texture2D(RefractTex, 0.5 + 0.5 * RefractedPosition.xy / RefractedPosition.w).rgb, HeightFactor);
}
