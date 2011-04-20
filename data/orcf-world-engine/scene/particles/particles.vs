#version 120

uniform mat4 BillboardMatrix;

uniform vec3 ViewPoint;

varying vec3 Vertex;
varying vec3 Normal;

void main(void) {
  gl_TexCoord[0] = gl_MultiTexCoord0;
  float c = cos(gl_Vertex.w);
  float s = sin(gl_Vertex.w);
  mat4 RotationMatrix = BillboardMatrix * mat4(c, -s, 0, 0, s, c, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1);
  Vertex = (vec4(gl_Vertex.xyz, 1.0) + (RotationMatrix * vec4(gl_TexCoord[0].zw, 0.0, 0.0))).xyz;
//   Normal = vec3(0.0, 1.0, 0.0);
  Normal = normalize(gl_Normal);
  if (abs(dot(Normal, vec3(0.0, 1.0, 0.0))) > 0.99)
    Normal = normalize(ViewPoint - Vertex);
  else {
    Normal = normalize(cross(cross(Normal, vec3(0.0, 1.0, 0.0)), Normal));
    Normal *= sign(dot(Normal, ViewPoint - Vertex));
  }
  

  gl_FrontColor = gl_Color;
  gl_BackColor = gl_Color;
  
  gl_Position = gl_ModelViewProjectionMatrix * vec4(Vertex, 1.0);
  gl_ClipVertex = gl_ModelViewMatrix * vec4(Vertex, 1.0);
}