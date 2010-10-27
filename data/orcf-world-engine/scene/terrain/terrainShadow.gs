#version 120

#extension GL_EXT_geometry_shader4: enable

uniform sampler2D TerrainMap;
uniform float TerrainTesselationDistance;
uniform int Tesselation;
uniform vec2 TerrainSize;

void main(void) {
  if (Tesselation == 0) { // Simply output given vertices
    gl_Position = gl_ModelViewProjectionMatrix * gl_PositionIn[0];
    EmitVertex();
    gl_Position = gl_ModelViewProjectionMatrix * gl_PositionIn[1];
    EmitVertex();
    gl_Position = gl_ModelViewProjectionMatrix * gl_PositionIn[2];
    EmitVertex();
  }
}
