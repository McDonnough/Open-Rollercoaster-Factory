#version 120

uniform vec2 AspectRatio;
uniform sampler2D GeometryTexture;

varying float alpha;
varying vec2 LightOnScreen;

void main(void) {
  float P = gl_Vertex.z;
  vec4 vec = gl_ProjectionMatrix * vec4(gl_NormalMatrix * gl_LightSource[0].position.xyz, 1.0);
  LightOnScreen = vec.xy / vec.w;
  alpha = 0.0;
  for (int i = 1; i <= 4; i++) {
    for (int j = 0; j < 12; j++) {
      alpha += (texture2D(GeometryTexture, 0.5 + 0.5 * LightOnScreen + 0.005 * i * vec2(sin(radians(30.0 * j)), cos(radians(30.0 * j)))).a > 4500.0) ? 1.0 / 48.0 : 0.0;
    }
  }
  vec2 V = -P * LightOnScreen;
  gl_FrontColor = gl_Color;
  gl_BackColor = gl_Color;
  gl_TexCoord[0] = 0.5 + 0.5 * gl_Vertex;
  gl_Position = vec4(V + gl_Vertex.xy * 0.06 * AspectRatio * P, 1.0, 1.0);
}