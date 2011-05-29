#version 120

#extension GL_EXT_gpu_shader4 : enable

uniform sampler2D GeometryTexture;
uniform sampler2D NormalTexture;
uniform sampler2D ShadowTexture;
uniform sampler2D MaterialTexture;

void main(void) {
  ivec2 Coords = ivec2(floor(gl_FragCoord.xy));

  vec4 AllCoord = texelFetch2D(GeometryTexture, Coords, 0);

  vec3 Vertex = AllCoord.rgb;
  vec3 Light = gl_LightSource[1].position.xyz - Vertex;
  float attenuation = gl_LightSource[1].diffuse.a * (gl_LightSource[1].ambient.a * gl_LightSource[1].ambient.a / (gl_LightSource[1].ambient.a * gl_LightSource[1].ambient.a + dot(Light, Light)));

  if (attenuation <= 0.01)
    discard;

  vec4 Normal = texelFetch2D(NormalTexture, Coords, 0);
  vec4 Material = texelFetch2D(MaterialTexture, Coords, 0);


  float dotprod = max(0.0, dot(normalize(Normal.xyz), normalize(Light)));
  gl_FragData[0].rgb = dotprod * gl_LightSource[1].diffuse.rgb;

  gl_FragData[0].rgb *= attenuation;

  vec4 v = (gl_ModelViewMatrix * vec4(Vertex, 1.0));
  vec3 Eye = normalize(-v.xyz);
  vec3 Reflected = normalize(reflect(-normalize((gl_ModelViewMatrix * vec4(gl_LightSource[1].position.xyz, 1.0) - v).xyz), normalize(gl_NormalMatrix * Normal.xyz)));
  gl_FragData[0].a = pow(max(dot(Reflected, Eye), 0.0), Normal.a) * attenuation;

  gl_FragData[1] = vec4(gl_FragData[0].a * gl_FragData[0].rgb, 1.0);

  if (abs(Normal.x) + abs(Normal.y) + abs(Normal.z) == 0.0)
    gl_FragData[0].a = -1.0;
}