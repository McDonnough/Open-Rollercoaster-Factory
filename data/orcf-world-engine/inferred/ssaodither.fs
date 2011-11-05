#version 120

uniform sampler2D GeometryTexture;
uniform sampler2D SSAOTexture;
uniform vec2 Screen;

void main(void) {
  gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
  float Samples = 0.0;
  float dist = texture2D(GeometryTexture, gl_TexCoord[0].xy).a;
  for (int i = -2; i <= 2; i++) {
    for (int j = -2; j <= 2; j++) {
      vec2 tc = gl_TexCoord[0].xy + 1.75 * vec2(i, j) / Screen;
      float d = texture2D(GeometryTexture, tc).a;
//       if (abs(dist - d) / dist < 0.1) {
        gl_FragColor += texture2D(SSAOTexture, tc);
        Samples += 1.0;
//       }
    }
  }
  gl_FragColor /= Samples;
}