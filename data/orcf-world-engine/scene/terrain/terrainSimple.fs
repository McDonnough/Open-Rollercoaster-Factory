#version 120

uniform sampler2D TerrainTexture;

varying vec3 Vertex;

void main(void) {
  gl_FragData[5] = vec4(0.0, 0.0, 0.0, 1.0);
  gl_FragData[4] = vec4(0.0, 0.0, 0.0, 0.0);
  
  gl_FragData[3] = vec4(0.0, 0.0, 0.0, 1.0);

  gl_FragData[2].rgb = Vertex;
  gl_FragData[2].a = length(vec3(gl_ModelViewMatrix * vec4(Vertex, 1.0)));
  
  gl_FragData[1] = vec4(0.0, 1.0, 0.0, 2.0);
  gl_FragData[0].rgb = texture2D(TerrainTexture, clamp((Vertex.xz / 32.0 - floor(Vertex.xz / 32.0)), 1.0 / 512.0, 1.0 - 1.0 / 512.0) / 4.0).rgb;
  gl_FragData[0].a = 0.02;
}