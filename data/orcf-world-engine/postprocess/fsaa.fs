#version 120

#extension GL_EXT_gpu_shader4 : require

uniform sampler2D Texture;
uniform sampler2D HDRColor;
uniform ivec2 ScreenSize;
uniform float Gamma;

const int Samples = {{{owe.samples}}};

void main(void) {
  vec3 HDRAverage = texelFetch2D(HDRColor, ivec2(0, 0), 0).rgb;
  float HDRLighting = length(HDRAverage) / 1.73;
  float HDRLightingFactor = 1.0 / (HDRLighting * HDRLighting + 0.5) / 1.5;

  // IF [ NEQ owe.samples 1 ]
  gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
  for (int i = 0; i < Samples; i++) {
    for (int j = 0; j < Samples; j++)
      gl_FragColor.rgb += texelFetch2D(Texture, Samples * ivec2(floor(gl_FragCoord.xy)) + ivec2(i, j), 0).rgb;
  }
  gl_FragColor.rgb /= (Samples * Samples);
  // END
  // IF [ EQ owe.samples 1 ]
    // IF [ NEQ owe.s3d.mode 0 ]
    gl_FragColor.rgb = texelFetch2D(Texture, ivec2(floor(gl_FragCoord.xy)), 0).rgb;
    // END
    // IF [ EQ owe.s3d.mode 0 ]
    gl_FragColor.rgb = texture2D(Texture, gl_TexCoord[0].xy).rgb;
    // END
  gl_FragColor.a = 1.0;
  // END
  
  gl_FragColor *= gl_Color * HDRLightingFactor;
  gl_FragColor.rgb += 0.5 * max(0.0, max(gl_FragColor.r, max(gl_FragColor.g, gl_FragColor.b)) - 1.0);

  // IF [ EQ owe.gamma 1 ]
  gl_FragColor.rgb = vec3(pow(gl_FragColor.r, Gamma), pow(gl_FragColor.g, Gamma), pow(gl_FragColor.b, Gamma));
  // END
}