#version 120

#extension GL_EXT_gpu_shader4 : enable

uniform sampler2D GeometryMap;
uniform sampler2D RenderedScene;
uniform float Height;
uniform vec3 ViewPoint;
uniform vec2 BumpOffset;

varying float DirectionFactor;

void main(void) {
  vec4 Vertex = texelFetch2D(GeometryMap, ivec2(floor(gl_FragCoord.xy)), 0);
  if (Vertex.y - 0.4 > Height)
    discard;
  float OffsetMod = 10.0 * gl_TexCoord[0].x + 0.3 * ViewPoint.x + 0.3 * ViewPoint.z + BumpOffset.x + BumpOffset.y;
  vec2 Offset = 0.03 * vec2((0.166 + DirectionFactor) * sin(OffsetMod), 0.166 * cos(OffsetMod));
  gl_FragColor.rgb = mix(texture2D(RenderedScene, gl_TexCoord[0].xy + Offset).rgb, vec3(0.20, 0.30, 0.27) * 3.0 * gl_LightSource[0].ambient.rgb, 1.0 - pow(0.75, texture2D(GeometryMap, gl_TexCoord[0].xy + Offset).a));
  gl_FragColor.a = 1.0;
}