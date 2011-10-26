#version 120

#extension GL_EXT_gpu_shader4 : require

uniform sampler2D Texture;
uniform int Size;
uniform ivec2 Dir;

void main(void) {
  ivec2 Start = ivec2(gl_FragCoord.xy);
  gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
  for (int i = 0; i < Size; i++) {
    vec3 Color = texelFetch2D(Texture, Start + i * Dir, 0).rgb;
    gl_FragColor.rgb += Color;
  }
  gl_FragColor.rgb /= Size;
}