#version 120

#extension GL_EXT_geometry_shader4: enable

uniform sampler2D TerrainMap;
uniform float TerrainTesselationDistance;
uniform int Tesselation;
uniform vec2 TerrainSize;

vec3 BasePoints[3];
vec3 TransformedBasePoints[3];
float TransformedBasePointDistanceValues[3];

varying out vec3 Vertex;

void main(void) {
  BasePoints[0] = vec3(gl_PositionIn[0].x, texture2D(TerrainMap, gl_PositionIn[0].xz / TerrainSize).b * 256.0, gl_PositionIn[0].z);
  BasePoints[1] = vec3(gl_PositionIn[1].x, texture2D(TerrainMap, gl_PositionIn[1].xz / TerrainSize).b * 256.0, gl_PositionIn[1].z);
  BasePoints[2] = vec3(gl_PositionIn[2].x, texture2D(TerrainMap, gl_PositionIn[2].xz / TerrainSize).b * 256.0, gl_PositionIn[2].z);

  TransformedBasePoints[0] = (gl_ModelViewMatrix * vec4(BasePoints[0], 1.0)).xyz;
  TransformedBasePoints[1] = (gl_ModelViewMatrix * vec4(BasePoints[1], 1.0)).xyz;
  TransformedBasePoints[2] = (gl_ModelViewMatrix * vec4(BasePoints[2], 1.0)).xyz;

  // Avoid sqrt function
  TransformedBasePointDistanceValues[0] = dot(TransformedBasePoints[0], TransformedBasePoints[0]);
  TransformedBasePointDistanceValues[1] = dot(TransformedBasePoints[1], TransformedBasePoints[1]);
  TransformedBasePointDistanceValues[2] = dot(TransformedBasePoints[2], TransformedBasePoints[2]);

  float qTerrainTesselationDistance = TerrainTesselationDistance * TerrainTesselationDistance;

  if (Tesselation == 0 || TransformedBasePointDistanceValues[0] > qTerrainTesselationDistance || TransformedBasePointDistanceValues[1] > qTerrainTesselationDistance || TransformedBasePointDistanceValues[2] > qTerrainTesselationDistance) {
    // Simply output given vertices
    Vertex = BasePoints[0]; gl_Position = gl_ProjectionMatrix * vec4(TransformedBasePoints[0], 1.0); EmitVertex();
    Vertex = BasePoints[1]; gl_Position = gl_ProjectionMatrix * vec4(TransformedBasePoints[1], 1.0); EmitVertex();
    Vertex = BasePoints[2]; gl_Position = gl_ProjectionMatrix * vec4(TransformedBasePoints[2], 1.0); EmitVertex();
  } else {
//     vec3 Vertices[15];
//     Vertices[0] = BasePoints[0];
//     Vertices[1] = mix(BasePoints[0], BasePoints[1], 0.25); Vertices[1].y = mix(Vertices[1].y, texture2D(TerrainMap, Vertices[1].xz / TerrainSize).b * 256.0,
  }
}
