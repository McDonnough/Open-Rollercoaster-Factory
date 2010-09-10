#version 120

#extension GL_EXT_geometry_shader4 : enable

void main(void) {
  gl_Position = gl_PositionIn[0];
  EmitVertex();
  gl_Position = gl_PositionIn[1];
  EmitVertex();
  gl_Position = gl_PositionIn[2];
  EmitVertex();
}