#version 120

uniform sampler2D ModelTexture;
uniform int UseTexture;
uniform vec4 MeshColor;

varying vec4 Vertex;

void main(void) {
  float dist = distance(Vertex.xyz, gl_LightSource[1].position.xyz);
  gl_FragColor = vec4(1.0, 1.0, 1.0, dist);
  vec4 tex = MeshColor;
  if (UseTexture == 1)
    tex *= texture2D(ModelTexture, gl_TexCoord[0].xy);
  gl_FragColor.rgb *= (1.0 - tex.rgb * (1.0 - tex.a));
  gl_FragColor.rgb *= tex.a;
}
