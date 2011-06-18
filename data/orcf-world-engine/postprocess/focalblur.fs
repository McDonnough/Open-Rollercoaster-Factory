#version 120

#extension GL_EXT_gpu_shader4 : require

uniform sampler2D SceneTexture;
uniform sampler2D GeometryTexture;

uniform vec2 Screen;
uniform float FocusDistance;
uniform float Strength;

const int SAMPLES = 5;
const float PIXELS_PER_SAMPLE = 1.0;

void main(void) {
  gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
  float Distance = texture2D(GeometryTexture, gl_TexCoord[0].xy).a;
  float Factor = min(2.0 / PIXELS_PER_SAMPLE, Distance / FocusDistance - 1.0) * 0.25;
  if (Distance < 5000.0) {
    for (int i = -SAMPLES; i < SAMPLES; i++) {
      for (int j = -SAMPLES; j < SAMPLES; j++) {
        gl_FragColor.rgb += texture2D(SceneTexture, gl_TexCoord[0].xy + (PIXELS_PER_SAMPLE * vec2(float(i) + 0.5, float(j) + 0.5) / Screen * Factor * Strength)).rgb;
        gl_FragColor.a += 1.0;
      }
    }
    gl_FragColor.rgb /= gl_FragColor.a;
  } else {
    gl_FragColor = texelFetch2D(SceneTexture, ivec2(floor(gl_FragCoord.xy)), 0);
  }
}