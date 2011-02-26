#version 120

#extension GL_EXT_gpu_shader4 : enable

uniform sampler2D Texture;
uniform sampler2D TransparencyMask;
uniform vec2 MaskOffset;
uniform vec2 MaskSize;
uniform float MaxDist;

varying vec3 normal;
varying vec3 Vertex;
varying vec2 texCoord;

void main(void) {
  gl_FragData[0] = texture2D(Texture, texCoord);
  float dist = length(gl_ModelViewMatrix * vec4(Vertex, 1.0));
  float alpha = clamp(MaxDist - dist, 0.0, 5.0) * 0.2;
//   if (gl_FragData[0].a * alpha < texture2D(TransparencyMask, (gl_FragCoord.xy) / MaskSize + MaskOffset).a)
  if (gl_FragData[0].a * alpha < 0.2)
    discard;
  gl_FragData[1] = vec4(normal, 2.0);
  gl_FragData[2].rgb = Vertex;
  gl_FragData[2].a = dist;
  gl_FragData[3].rgb = vec3(0.0, 0.0, 0.0);
}