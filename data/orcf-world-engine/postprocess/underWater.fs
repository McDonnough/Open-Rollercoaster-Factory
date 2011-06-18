#version 120

#extension GL_EXT_gpu_shader4 : require

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
  vec2 Offset = 0.03 * vec2((0.166 + DirectionFactor) * sin(OffsetMod) * sin(4.0 * gl_TexCoord[0].y), 0.166 * cos(OffsetMod));
  gl_FragColor.rgb = texture2D(RenderedScene, gl_TexCoord[0].xy + Offset).rgb;
  gl_FragColor.a = 1.0;
}