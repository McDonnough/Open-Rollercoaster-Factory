#version 120

#extension GL_EXT_gpu_shader4 : require

uniform int AdvanceSamples;
uniform sampler2D GeometryTexture;

void main(void) {
  gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
  gl_FragDepth = sqrt(length((gl_ModelViewMatrix * (vec4(texelFetch2D(GeometryTexture, AdvanceSamples * ivec2(floor(gl_FragCoord.xy)), 0).rgb, 1.0))).xyz) / 5000.0) - 0.0005;
}