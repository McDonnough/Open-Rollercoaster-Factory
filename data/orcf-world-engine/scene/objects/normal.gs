#version 120

#extension GL_EXT_geometry_shader4 : require

uniform mat4 MeshTransformMatrix;
uniform mat4 TransformMatrix;
uniform mat4 DeformMatrix;
uniform vec3 Mirror;
uniform vec3 VirtScale;

varying in vec3 _Normal[3];
varying in vec3 _Vertex[3];
varying in vec3 _OrigVertex[3];
varying in vec3 _TransformedVertex[3];

varying out vec3 Normal;
varying out vec3 Vertex;
varying out vec3 OrigVertex;
varying out vec3 Tangent;
varying out vec3 Bitangent;

void main(void) {
  // Tangent stuff
  
  vec3 v1 = _Vertex[1] - _Vertex[0];
  vec3 v2 = _Vertex[2] - _Vertex[0];

  vec2 w1 = gl_TexCoordIn[1][0].xy - gl_TexCoordIn[0][0].xy;
  vec2 w2 = gl_TexCoordIn[2][0].xy - gl_TexCoordIn[0][0].xy;

  float r = 1.0 / (w1.s * w2.t - w2.s * w1.t);

  vec3 sdir = (w2.t * v1 - w1.t * v2) * r;
  vec3 tdir = (w1.s * v2 - w2.s * v1) * r;

  mat4 allMats = TransformMatrix * DeformMatrix * MeshTransformMatrix;
  vec3 axes[3];
  axes[0] = normalize(allMats[0].xyz);
  axes[1] = normalize(allMats[1].xyz);
  axes[2] = normalize(allMats[2].xyz);

  vec2 stFactor = vec2(
    length(vec3(dot(normalize(sdir), axes[0]) * VirtScale.x, dot(normalize(sdir), axes[1]) * VirtScale.y, dot(normalize(sdir), axes[2]) * VirtScale.z)),
    length(vec3(dot(normalize(tdir), axes[0]) * VirtScale.x, dot(normalize(tdir), axes[1]) * VirtScale.y, dot(normalize(tdir), axes[2]) * VirtScale.z)));

  // Vertices

  for (int i = 0; i < 3; i++) {
    Normal = _Normal[i];
    Vertex = _Vertex[i];
    OrigVertex = _OrigVertex[i];
    Normal = _Normal[i];
    Tangent = normalize(sdir - Normal * dot(Normal, sdir));
    Bitangent = cross(Normal, Tangent) * sign(dot(cross(Normal, sdir), tdir));
    gl_TexCoord[0] = gl_TexCoordIn[i][0];
    gl_TexCoord[0].st *= stFactor;
    gl_Position = gl_PositionIn[i];
    gl_ClipVertex = vec4(_TransformedVertex[i], 1.0);
    EmitVertex();
  }
}