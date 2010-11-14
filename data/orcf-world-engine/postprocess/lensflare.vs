#version 120

uniform vec2 AspectRatio;

void main(void) {
  float P = gl_Vertex.z;
  vec4 vec = gl_ModelViewProjectionMatrix * gl_LightSource[0].position;
  vec2 LightOnScreen = vec.xy / vec.w;
  vec2 V = -P * LightOnScreen;
  gl_FrontColor = gl_Color;
  gl_BackColor = gl_Color;
  gl_TexCoord[0] = 0.5 + 0.5 * gl_Vertex;
  gl_Position = vec4(V + gl_Vertex.xy * 0.06 * AspectRatio * P, 1.0, 1.0);
}