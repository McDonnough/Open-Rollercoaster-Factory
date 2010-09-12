#version 120

#extension GL_EXT_geometry_shader4 : enable

uniform sampler2D Bump;
uniform vec2 TexSize;
uniform float TessFactor;

varying in vec4 Vertex[3];
varying in vec3 Normal[3];

vec4 normal(int a, int b) {
  return vec4(Normal[0], 0.0);
}

void main(void) {
  vec4 D = Vertex[2] + Vertex[0] - Vertex[1];
  ivec2 OutputSize = ivec2(8, 8);
  vec4 AB = (Vertex[1] - Vertex[0]) / OutputSize.x;
  vec4 BC = (Vertex[2] - Vertex[1]) / OutputSize.y;
  vec2 tD = (gl_TexCoordIn[2][0] + gl_TexCoordIn[0][0] - gl_TexCoordIn[1][0]).zw;
  vec2 tAB = ((gl_TexCoordIn[1][0] - gl_TexCoordIn[0][0]) / OutputSize.x).zw;
  vec2 tBC = ((gl_TexCoordIn[2][0] - gl_TexCoordIn[1][0]) / OutputSize.y).zw;
  float Alpha;
  for (int i = 0; i < OutputSize.x; i++)
    for (int j = 0; j < OutputSize.y; j++) {
      Alpha = (i * j) / OutputSize.x / OutputSize.y;
      gl_Position = gl_ModelViewProjectionMatrix * (Vertex[0] + AB * i + BC * j + normal(i, j) * Alpha);
      EmitVertex();
      gl_Position = gl_ModelViewProjectionMatrix * (Vertex[0] + AB * (i + 1) + BC * j + normal(i + 1, j) * Alpha);
      EmitVertex();
      gl_Position = gl_ModelViewProjectionMatrix * (Vertex[0] + AB * (i + 1) + BC * (j + 1) + normal(i + 1, j + 1) * Alpha);
      EmitVertex();
      gl_Position = gl_ModelViewProjectionMatrix * (Vertex[0] + AB * i + BC * (j + 1) + normal(i, j + 1) * Alpha);
      EmitVertex();
      EndPrimitive();
    }


/*  gl_Position = gl_PositionIn[0];
  EmitVertex();
  gl_Position = gl_PositionIn[1];
  EmitVertex();
  gl_Position = gl_PositionIn[2];
  EmitVertex();*/
}