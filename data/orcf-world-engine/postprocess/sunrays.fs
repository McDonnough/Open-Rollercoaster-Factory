#version 120

// Technique and shader from http://www.fabiensanglard.net/lightScattering/index.php

uniform float exposure;
uniform float decay;
uniform float density;
uniform float weight;
uniform sampler2D NormalTexture;
uniform sampler2D MaterialTexture;
uniform vec3 VecToFront;

varying vec2 lightPositionOnScreen;

const int NUM_SAMPLES = 100;

void main() {
  float angleFactor = clamp(2.0 * dot(normalize(VecToFront), normalize(gl_LightSource[0].position.xyz)), 0.0, 1.0);
  if (angleFactor <= 0.0)
    discard;

  vec2 deltaTextCoord = gl_TexCoord[0].xy - lightPositionOnScreen;
  vec2 textCoo = gl_TexCoord[0].xy;
  deltaTextCoord *= 1.0 / float(NUM_SAMPLES) * density;
  float illuminationDecay = 1.0;

  gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);

  for(int i = 0; i < NUM_SAMPLES; i++) {
      textCoo -= deltaTextCoord;
      vec4 sample = texture2D(MaterialTexture, textCoo) * 0.2;
      vec3 a = texture2D(NormalTexture, textCoo).rgb;
      if (max(max(a.r, a.g), a.b) > 0.0)
        sample *= 0.0;
      sample *= illuminationDecay * weight * 100.0 / float(NUM_SAMPLES);
      gl_FragColor += sample;
      illuminationDecay *= decay;
  }

  gl_FragColor *= exposure * angleFactor;
}
