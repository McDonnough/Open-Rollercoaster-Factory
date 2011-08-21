#version 120

#extension GL_EXT_geometry_shader4 : require

uniform mat4 TransformMatrix;
uniform vec3 Mirror;

varying in vec3 _Normal[3];
varying in vec3 _Vertex[3];
varying in vec3 _OrigVertex[3];
varying in vec3 _TransformedVertex[3];
varying in vec3 _TransformedNormal[3];

varying out vec3 Normal;
varying out vec3 Vertex;
varying out vec3 OrigVertex;
varying out vec3 Tangent;
varying out vec3 Bitangent;
varying out vec3 TransformedVertex;
varying out vec3 TransformedNormal;

void main(void) {
  // Tangent stuff
  
  vec3 v1 = _Vertex[1] - _Vertex[0];
  vec3 v2 = _Vertex[2] - _Vertex[0];

  vec2 w1 = gl_TexCoordIn[1][0].xy - gl_TexCoordIn[0][0].xy;
  vec2 w2 = gl_TexCoordIn[2][0].xy - gl_TexCoordIn[0][0].xy;

  float r = 1.0 / (w1.s * w2.t - w2.s * w1.t);

  vec3 sdir = (w2.t * v1 - w1.t * v2) * r;
  vec3 tdir = (w1.s * v2 - w2.s * v1) * r;

  // Vertices

  for (int i = 0; i < 3; i++) {
    Normal = _Normal[i];
    Vertex = _Vertex[i];
    OrigVertex = _OrigVertex[i];
    Normal = _Normal[i];
    TransformedNormal = _TransformedNormal[i];
    TransformedVertex = _TransformedVertex[i];
    Tangent = normalize(sdir - Normal * dot(Normal, sdir));
    Bitangent = cross(Normal, Tangent) * sign(dot(cross(Normal, sdir), tdir));
    gl_TexCoord[0] = gl_TexCoordIn[i][0];
    gl_Position = gl_PositionIn[i];
    gl_ClipVertex = vec4(TransformedVertex, 1.0);
    EmitVertex();
  }
}