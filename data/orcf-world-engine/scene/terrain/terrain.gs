#version 120

#extension GL_EXT_geometry_shader4: enable

uniform sampler2D TerrainMap;
uniform float TerrainTesselationDistance;
uniform int Tesselation;
uniform vec2 TerrainSize;
uniform vec2 TOffset;

vec3 BasePoints[3];
vec3 TransformedBasePoints[3];
float TransformedBasePointDistanceValues[3];

varying out vec3 Vertex;

void main(void) {
  BasePoints[0] = vec3(gl_PositionIn[0].x, texture2D(TerrainMap, gl_PositionIn[0].xz / TerrainSize + TOffset).b * 256.0, gl_PositionIn[0].z);
  BasePoints[1] = vec3(gl_PositionIn[1].x, texture2D(TerrainMap, gl_PositionIn[1].xz / TerrainSize + TOffset).b * 256.0, gl_PositionIn[1].z);
  BasePoints[2] = vec3(gl_PositionIn[2].x, texture2D(TerrainMap, gl_PositionIn[2].xz / TerrainSize + TOffset).b * 256.0, gl_PositionIn[2].z);

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
    Vertex = BasePoints[0]; gl_Position = gl_ModelViewProjectionMatrix * vec4(BasePoints[0], 1.0); EmitVertex();
    Vertex = BasePoints[1]; gl_Position = gl_ModelViewProjectionMatrix * vec4(BasePoints[1], 1.0); EmitVertex();
    Vertex = BasePoints[2]; gl_Position = gl_ModelViewProjectionMatrix * vec4(BasePoints[2], 1.0); EmitVertex();
    EndPrimitive();
  } else {
    vec3 Vertices[15];

    // Interpolate new vertices
    Vertices[ 0] = BasePoints[0];
    Vertices[ 1] = mix(BasePoints[0], BasePoints[1], 0.25);
    Vertices[ 2] = mix(BasePoints[0], BasePoints[1], 0.50);
    Vertices[ 3] = mix(BasePoints[0], BasePoints[1], 0.75);
    Vertices[ 4] = BasePoints[1];

    Vertices[ 5] = mix(BasePoints[0], BasePoints[2], 0.25);
    Vertices[ 6] = mix(mix(BasePoints[0], BasePoints[1], 0.33), BasePoints[2], 0.25);
    Vertices[ 7] = mix(mix(BasePoints[0], BasePoints[1], 0.67), BasePoints[2], 0.25);
    Vertices[ 8] = mix(BasePoints[1], BasePoints[2], 0.25);

    Vertices[ 9] = mix(BasePoints[0], BasePoints[2], 0.50);
    Vertices[10] = mix(mix(BasePoints[0], BasePoints[1], 0.50), BasePoints[2], 0.50);
    Vertices[11] = mix(BasePoints[1], BasePoints[2], 0.50);

    Vertices[12] = mix(BasePoints[0], BasePoints[2], 0.75);
    Vertices[13] = mix(BasePoints[1], BasePoints[2], 0.75);

    Vertices[14] = BasePoints[2];

    // Save old vertex y coordinates
    float owh[15];

    owh[ 0] = Vertices[ 0].y;
    owh[ 1] = Vertices[ 1].y;
    owh[ 2] = Vertices[ 2].y;
    owh[ 3] = Vertices[ 3].y;
    owh[ 4] = Vertices[ 4].y;
    owh[ 5] = Vertices[ 5].y;
    owh[ 6] = Vertices[ 6].y;
    owh[ 7] = Vertices[ 7].y;
    owh[ 8] = Vertices[ 8].y;
    owh[ 9] = Vertices[ 9].y;
    owh[10] = Vertices[10].y;
    owh[11] = Vertices[11].y;
    owh[12] = Vertices[12].y;
    owh[13] = Vertices[13].y;
    owh[14] = Vertices[14].y;

    // Get new height values
    Vertices[ 0].y = 256.0 * texture2D(TerrainMap, Vertices[ 0].xz / TerrainSize + TOffset).b;
    Vertices[ 1].y = 256.0 * texture2D(TerrainMap, Vertices[ 1].xz / TerrainSize + TOffset).b;
    Vertices[ 2].y = 256.0 * texture2D(TerrainMap, Vertices[ 2].xz / TerrainSize + TOffset).b;
    Vertices[ 3].y = 256.0 * texture2D(TerrainMap, Vertices[ 3].xz / TerrainSize + TOffset).b;
    Vertices[ 4].y = 256.0 * texture2D(TerrainMap, Vertices[ 4].xz / TerrainSize + TOffset).b;
    Vertices[ 5].y = 256.0 * texture2D(TerrainMap, Vertices[ 5].xz / TerrainSize + TOffset).b;
    Vertices[ 6].y = 256.0 * texture2D(TerrainMap, Vertices[ 6].xz / TerrainSize + TOffset).b;
    Vertices[ 7].y = 256.0 * texture2D(TerrainMap, Vertices[ 7].xz / TerrainSize + TOffset).b;
    Vertices[ 8].y = 256.0 * texture2D(TerrainMap, Vertices[ 8].xz / TerrainSize + TOffset).b;
    Vertices[ 9].y = 256.0 * texture2D(TerrainMap, Vertices[ 9].xz / TerrainSize + TOffset).b;
    Vertices[10].y = 256.0 * texture2D(TerrainMap, Vertices[10].xz / TerrainSize + TOffset).b;
    Vertices[11].y = 256.0 * texture2D(TerrainMap, Vertices[11].xz / TerrainSize + TOffset).b;
    Vertices[12].y = 256.0 * texture2D(TerrainMap, Vertices[12].xz / TerrainSize + TOffset).b;
    Vertices[13].y = 256.0 * texture2D(TerrainMap, Vertices[13].xz / TerrainSize + TOffset).b;
    Vertices[14].y = 256.0 * texture2D(TerrainMap, Vertices[14].xz / TerrainSize + TOffset).b;

    // Prevent black holes
    Vertices[ 0].y = mix(owh[ 0], Vertices[ 0].y, 0.2 * clamp(TerrainTesselationDistance - 1.0 - length((gl_ModelViewMatrix * vec4(Vertices[ 0], 1.0)).xyz), 0.0, 5.0));
    Vertices[ 1].y = mix(owh[ 1], Vertices[ 1].y, 0.2 * clamp(TerrainTesselationDistance - 1.0 - length((gl_ModelViewMatrix * vec4(Vertices[ 1], 1.0)).xyz), 0.0, 5.0));
    Vertices[ 2].y = mix(owh[ 2], Vertices[ 2].y, 0.2 * clamp(TerrainTesselationDistance - 1.0 - length((gl_ModelViewMatrix * vec4(Vertices[ 2], 1.0)).xyz), 0.0, 5.0));
    Vertices[ 3].y = mix(owh[ 3], Vertices[ 3].y, 0.2 * clamp(TerrainTesselationDistance - 1.0 - length((gl_ModelViewMatrix * vec4(Vertices[ 3], 1.0)).xyz), 0.0, 5.0));
    Vertices[ 4].y = mix(owh[ 4], Vertices[ 4].y, 0.2 * clamp(TerrainTesselationDistance - 1.0 - length((gl_ModelViewMatrix * vec4(Vertices[ 4], 1.0)).xyz), 0.0, 5.0));
    Vertices[ 5].y = mix(owh[ 5], Vertices[ 5].y, 0.2 * clamp(TerrainTesselationDistance - 1.0 - length((gl_ModelViewMatrix * vec4(Vertices[ 5], 1.0)).xyz), 0.0, 5.0));
    Vertices[ 6].y = mix(owh[ 6], Vertices[ 6].y, 0.2 * clamp(TerrainTesselationDistance - 1.0 - length((gl_ModelViewMatrix * vec4(Vertices[ 6], 1.0)).xyz), 0.0, 5.0));
    Vertices[ 7].y = mix(owh[ 7], Vertices[ 7].y, 0.2 * clamp(TerrainTesselationDistance - 1.0 - length((gl_ModelViewMatrix * vec4(Vertices[ 7], 1.0)).xyz), 0.0, 5.0));
    Vertices[ 8].y = mix(owh[ 8], Vertices[ 8].y, 0.2 * clamp(TerrainTesselationDistance - 1.0 - length((gl_ModelViewMatrix * vec4(Vertices[ 8], 1.0)).xyz), 0.0, 5.0));
    Vertices[ 9].y = mix(owh[ 9], Vertices[ 9].y, 0.2 * clamp(TerrainTesselationDistance - 1.0 - length((gl_ModelViewMatrix * vec4(Vertices[ 9], 1.0)).xyz), 0.0, 5.0));
    Vertices[10].y = mix(owh[10], Vertices[10].y, 0.2 * clamp(TerrainTesselationDistance - 1.0 - length((gl_ModelViewMatrix * vec4(Vertices[10], 1.0)).xyz), 0.0, 5.0));
    Vertices[11].y = mix(owh[11], Vertices[11].y, 0.2 * clamp(TerrainTesselationDistance - 1.0 - length((gl_ModelViewMatrix * vec4(Vertices[11], 1.0)).xyz), 0.0, 5.0));
    Vertices[12].y = mix(owh[12], Vertices[12].y, 0.2 * clamp(TerrainTesselationDistance - 1.0 - length((gl_ModelViewMatrix * vec4(Vertices[12], 1.0)).xyz), 0.0, 5.0));
    Vertices[13].y = mix(owh[13], Vertices[13].y, 0.2 * clamp(TerrainTesselationDistance - 1.0 - length((gl_ModelViewMatrix * vec4(Vertices[13], 1.0)).xyz), 0.0, 5.0));
    Vertices[14].y = mix(owh[14], Vertices[14].y, 0.2 * clamp(TerrainTesselationDistance - 1.0 - length((gl_ModelViewMatrix * vec4(Vertices[14], 1.0)).xyz), 0.0, 5.0));

    // Output new triangles
    Vertex = Vertices[ 0]; gl_Position = gl_ModelViewProjectionMatrix * vec4(Vertices[ 0], 1.0); EmitVertex();
    Vertex = Vertices[ 5]; gl_Position = gl_ModelViewProjectionMatrix * vec4(Vertices[ 5], 1.0); EmitVertex();
    Vertex = Vertices[ 1]; gl_Position = gl_ModelViewProjectionMatrix * vec4(Vertices[ 1], 1.0); EmitVertex();
    Vertex = Vertices[ 6]; gl_Position = gl_ModelViewProjectionMatrix * vec4(Vertices[ 6], 1.0); EmitVertex();
    Vertex = Vertices[ 2]; gl_Position = gl_ModelViewProjectionMatrix * vec4(Vertices[ 2], 1.0); EmitVertex();
    Vertex = Vertices[ 7]; gl_Position = gl_ModelViewProjectionMatrix * vec4(Vertices[ 7], 1.0); EmitVertex();
    Vertex = Vertices[ 3]; gl_Position = gl_ModelViewProjectionMatrix * vec4(Vertices[ 3], 1.0); EmitVertex();
    Vertex = Vertices[ 8]; gl_Position = gl_ModelViewProjectionMatrix * vec4(Vertices[ 8], 1.0); EmitVertex();
    Vertex = Vertices[ 4]; gl_Position = gl_ModelViewProjectionMatrix * vec4(Vertices[ 4], 1.0); EmitVertex();
    EndPrimitive();

    Vertex = Vertices[ 5]; gl_Position = gl_ModelViewProjectionMatrix * vec4(Vertices[ 5], 1.0); EmitVertex();
    Vertex = Vertices[ 9]; gl_Position = gl_ModelViewProjectionMatrix * vec4(Vertices[ 9], 1.0); EmitVertex();
    Vertex = Vertices[ 6]; gl_Position = gl_ModelViewProjectionMatrix * vec4(Vertices[ 6], 1.0); EmitVertex();
    Vertex = Vertices[10]; gl_Position = gl_ModelViewProjectionMatrix * vec4(Vertices[10], 1.0); EmitVertex();
    Vertex = Vertices[ 7]; gl_Position = gl_ModelViewProjectionMatrix * vec4(Vertices[ 7], 1.0); EmitVertex();
    Vertex = Vertices[11]; gl_Position = gl_ModelViewProjectionMatrix * vec4(Vertices[11], 1.0); EmitVertex();
    Vertex = Vertices[ 8]; gl_Position = gl_ModelViewProjectionMatrix * vec4(Vertices[ 8], 1.0); EmitVertex();
    EndPrimitive();

    Vertex = Vertices[ 9]; gl_Position = gl_ModelViewProjectionMatrix * vec4(Vertices[ 9], 1.0); EmitVertex();
    Vertex = Vertices[12]; gl_Position = gl_ModelViewProjectionMatrix * vec4(Vertices[12], 1.0); EmitVertex();
    Vertex = Vertices[10]; gl_Position = gl_ModelViewProjectionMatrix * vec4(Vertices[10], 1.0); EmitVertex();
    Vertex = Vertices[13]; gl_Position = gl_ModelViewProjectionMatrix * vec4(Vertices[13], 1.0); EmitVertex();
    Vertex = Vertices[11]; gl_Position = gl_ModelViewProjectionMatrix * vec4(Vertices[11], 1.0); EmitVertex();
    EndPrimitive();

    Vertex = Vertices[12]; gl_Position = gl_ModelViewProjectionMatrix * vec4(Vertices[12], 1.0); EmitVertex();
    Vertex = Vertices[14]; gl_Position = gl_ModelViewProjectionMatrix * vec4(Vertices[14], 1.0); EmitVertex();
    Vertex = Vertices[13]; gl_Position = gl_ModelViewProjectionMatrix * vec4(Vertices[13], 1.0); EmitVertex();
    EndPrimitive();
  }
}
