#version 120

uniform sampler2D HeightMap;
uniform sampler2D Autoplant;
uniform sampler2D SunShadowMap;
uniform vec2 TerrainSize;

varying float dist;
varying float SDist;
varying vec4 result;
varying vec4 Vertex;
varying vec4 BaseVertex;
varying vec3 normal;

vec4 Diffuse = vec4(0.0, 0.0, 0.0, 1.0);
vec4 Ambient = vec4(0.0, 0.0, 0.0, 1.0);

void AddLight(int ID) {
  vec3 DistVector = gl_LightSource[ID].position.xyz - Vertex.xyz;
  float lnrDistVector = max(0.5, DistVector.x * DistVector.x + DistVector.y * DistVector.y + DistVector.z * DistVector.z);
  Diffuse += gl_LightSource[ID].diffuse * gl_LightSource[ID].diffuse.a * dot(normal, normalize(DistVector)) * gl_LightSource[ID].position.w * gl_LightSource[ID].position.w / lnrDistVector;
}

void main(void) {
  if (dist > 30.0)
    discard;
  gl_FragColor = texture2D(Autoplant, gl_TexCoord[0].xy);
  vec4 SunShadow = vec4(0.0, 0.0, 0.0, 0.0);
  if (length(result.xy / result.w) < 1.0)
    SunShadow = texture2D(SunShadowMap, 0.5 + 0.5 * result.xy / result.w);
  if (SunShadow.a + 0.1 >= SDist)
    SunShadow = vec4(0.0, 0.0, 0.0, 0.0);
  Diffuse = gl_LightSource[0].diffuse * (((1.0 - vec4(SunShadow.rgb * clamp(SDist - SunShadow.a, 0.0, 1.0), 0.0)) * max(0.0, dot(normal, normalize(gl_LightSource[0].position.xyz - Vertex.xyz)))));
  Ambient = gl_LightSource[0].ambient;
  AddLight(1);
  gl_FragColor.rgb *= (Diffuse + Ambient).rgb;
  gl_FragColor.a *= 1.2 * clamp(0.2 * (20 - dist), 0.0, 1.0);
}