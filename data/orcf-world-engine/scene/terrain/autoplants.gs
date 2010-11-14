#version 120

#extension GL_EXT_geometry_shader4 : enable

uniform sampler2D TerrainMap;
uniform vec2 TerrainSize;

varying out vec3 normal;
varying out vec3 Vertex;
varying out vec2 texCoord;

float fetchHeightAtOffset(int id, vec2 O) {
  return texture2D(TerrainMap, (gl_PositionIn[id].xy + O) / TerrainSize).b * 256.0;
}

void main(void) {
  if (gl_PositionIn[0].z >= 0.0) {
    vec3 Positions[4];
    float VY = fetchHeightAtOffset(0, vec2(0.0, 0.0));
    vec3 Normal = normalize(
      normalize(cross(vec3(+0.0, fetchHeightAtOffset(0, vec2(+0.0, -0.2)) - VY, -0.2), vec3(-0.2, fetchHeightAtOffset(0, vec2(-0.2, +0.0)) - VY, +0.0)))
    + normalize(cross(vec3(+0.2, fetchHeightAtOffset(0, vec2(+0.2, +0.0)) - VY, +0.0), vec3(+0.0, fetchHeightAtOffset(0, vec2(+0.0, -0.2)) - VY, -0.2)))
    + normalize(cross(vec3(+0.0, fetchHeightAtOffset(0, vec2(+0.0, +0.2)) - VY, +0.2), vec3(+0.2, fetchHeightAtOffset(0, vec2(+0.2, +0.0)) - VY, -0.0)))
    + normalize(cross(vec3(-0.2, fetchHeightAtOffset(0, vec2(-0.2, +0.0)) - VY, +0.0), vec3(+0.0, fetchHeightAtOffset(0, vec2(+0.0, +0.2)) - VY, +0.2))));
    vec2 A = vec2(sin(gl_PositionIn[0].z), cos(gl_PositionIn[0].z));
    float VY2 = fetchHeightAtOffset(0, A);
    Positions[0] = vec3(gl_PositionIn[0].x, VY, gl_PositionIn[0].y);
    Positions[1] = vec3(gl_PositionIn[0].x, VY, gl_PositionIn[0].y) + 0.4 * Normal;
    Positions[2] = vec3(gl_PositionIn[0].x + 0.8 * A.x, VY2, gl_PositionIn[0].y + 0.8 * A.y);
    Positions[3] = vec3(gl_PositionIn[0].x + 0.8 * A.x, VY2, gl_PositionIn[0].y + 0.8 * A.y) + 0.4 * Normal;
    normal = Normal; Vertex = Positions[0]; texCoord = vec2(0.0, 1.0); gl_Position = gl_ModelViewProjectionMatrix * vec4(Positions[0], 1.0); EmitVertex();
    normal = Normal; Vertex = Positions[1]; texCoord = vec2(0.0, 0.0); gl_Position = gl_ModelViewProjectionMatrix * vec4(Positions[1], 1.0); EmitVertex();
    normal = Normal; Vertex = Positions[2]; texCoord = vec2(1.0, 1.0); gl_Position = gl_ModelViewProjectionMatrix * vec4(Positions[2], 1.0); EmitVertex();
    normal = Normal; Vertex = Positions[3]; texCoord = vec2(1.0, 0.0); gl_Position = gl_ModelViewProjectionMatrix * vec4(Positions[3], 1.0); EmitVertex();
    EndPrimitive();
  }

  if (gl_PositionIn[1].z >= 0.0) {
    vec3 Positions[4];
    float VY = fetchHeightAtOffset(1, vec2(0.0, 0.0));
    vec3 Normal = normalize(
      normalize(cross(vec3(+0.0, fetchHeightAtOffset(1, vec2(+0.0, -0.2)) - VY, -0.2), vec3(-0.2, fetchHeightAtOffset(1, vec2(-0.2, +0.0)) - VY, +0.0)))
    + normalize(cross(vec3(+0.2, fetchHeightAtOffset(1, vec2(+0.2, +0.0)) - VY, +0.0), vec3(+0.0, fetchHeightAtOffset(1, vec2(+0.0, -0.2)) - VY, -0.2)))
    + normalize(cross(vec3(+0.0, fetchHeightAtOffset(1, vec2(+0.0, +0.2)) - VY, +0.2), vec3(+0.2, fetchHeightAtOffset(1, vec2(+0.2, +0.0)) - VY, -0.0)))
    + normalize(cross(vec3(-0.2, fetchHeightAtOffset(1, vec2(-0.2, +0.0)) - VY, +0.0), vec3(+0.0, fetchHeightAtOffset(1, vec2(+0.0, +0.2)) - VY, +0.2))));
    vec2 A = vec2(sin(gl_PositionIn[1].z), cos(gl_PositionIn[1].z));
    float VY2 = fetchHeightAtOffset(1, A);
    Positions[0] = vec3(gl_PositionIn[1].x, VY, gl_PositionIn[1].y);
    Positions[1] = vec3(gl_PositionIn[1].x, VY, gl_PositionIn[1].y) + 0.4 * Normal;
    Positions[2] = vec3(gl_PositionIn[1].x + 0.8 * A.x, VY2, gl_PositionIn[1].y + 0.8 * A.y);
    Positions[3] = vec3(gl_PositionIn[1].x + 0.8 * A.x, VY2, gl_PositionIn[1].y + 0.8 * A.y) + 0.4 * Normal;
    normal = Normal; Vertex = Positions[0]; texCoord = vec2(0.0, 1.0); gl_Position = gl_ModelViewProjectionMatrix * vec4(Positions[0], 1.0); EmitVertex();
    normal = Normal; Vertex = Positions[1]; texCoord = vec2(0.0, 0.0); gl_Position = gl_ModelViewProjectionMatrix * vec4(Positions[1], 1.0); EmitVertex();
    normal = Normal; Vertex = Positions[2]; texCoord = vec2(1.0, 1.0); gl_Position = gl_ModelViewProjectionMatrix * vec4(Positions[2], 1.0); EmitVertex();
    normal = Normal; Vertex = Positions[3]; texCoord = vec2(1.0, 0.0); gl_Position = gl_ModelViewProjectionMatrix * vec4(Positions[3], 1.0); EmitVertex();
    EndPrimitive();
  }

  if (gl_PositionIn[2].z >= 0.0) {
    vec3 Positions[4];
    float VY = fetchHeightAtOffset(2, vec2(0.0, 0.0));
    vec3 Normal = normalize(
      normalize(cross(vec3(+0.0, fetchHeightAtOffset(2, vec2(+0.0, -0.2)) - VY, -0.2), vec3(-0.2, fetchHeightAtOffset(2, vec2(-0.2, +0.0)) - VY, +0.0)))
    + normalize(cross(vec3(+0.2, fetchHeightAtOffset(2, vec2(+0.2, +0.0)) - VY, +0.0), vec3(+0.0, fetchHeightAtOffset(2, vec2(+0.0, -0.2)) - VY, -0.2)))
    + normalize(cross(vec3(+0.0, fetchHeightAtOffset(2, vec2(+0.0, +0.2)) - VY, +0.2), vec3(+0.2, fetchHeightAtOffset(2, vec2(+0.2, +0.0)) - VY, -0.0)))
    + normalize(cross(vec3(-0.2, fetchHeightAtOffset(2, vec2(-0.2, +0.0)) - VY, +0.0), vec3(+0.0, fetchHeightAtOffset(2, vec2(+0.0, +0.2)) - VY, +0.2))));
    vec2 A = vec2(sin(gl_PositionIn[2].z), cos(gl_PositionIn[2].z));
    float VY2 = fetchHeightAtOffset(2, A);
    Positions[0] = vec3(gl_PositionIn[2].x, VY, gl_PositionIn[2].y);
    Positions[1] = vec3(gl_PositionIn[2].x, VY, gl_PositionIn[2].y) + 0.4 * Normal;
    Positions[2] = vec3(gl_PositionIn[2].x + 0.8 * A.x, VY2, gl_PositionIn[2].y + 0.8 * A.y);
    Positions[3] = vec3(gl_PositionIn[2].x + 0.8 * A.x, VY2, gl_PositionIn[2].y + 0.8 * A.y) + 0.4 * Normal;
    normal = Normal; Vertex = Positions[0]; texCoord = vec2(0.0, 1.0); gl_Position = gl_ModelViewProjectionMatrix * vec4(Positions[0], 1.0); EmitVertex();
    normal = Normal; Vertex = Positions[1]; texCoord = vec2(0.0, 0.0); gl_Position = gl_ModelViewProjectionMatrix * vec4(Positions[1], 1.0); EmitVertex();
    normal = Normal; Vertex = Positions[2]; texCoord = vec2(1.0, 1.0); gl_Position = gl_ModelViewProjectionMatrix * vec4(Positions[2], 1.0); EmitVertex();
    normal = Normal; Vertex = Positions[3]; texCoord = vec2(1.0, 0.0); gl_Position = gl_ModelViewProjectionMatrix * vec4(Positions[3], 1.0); EmitVertex();
    EndPrimitive();
  }
}