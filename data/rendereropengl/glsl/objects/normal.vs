#version 120

uniform mat4 TransformMatrix;

varying vec4 Vertex;
varying float dist;
varying vec3 Normal;

vec4 mapPixelToQuad(vec2 P) {
  vec2 result = P / 204.8;
  return vec4(result, 1.0, 1.0);
}

void main(void) {
  Normal = mat3(TransformMatrix) * gl_Normal;
  gl_TexCoord[0] = vec4(gl_MultiTexCoord0.xy, gl_Color.rg);
  Vertex = TransformMatrix * gl_Vertex;
  gl_ClipVertex = gl_ModelViewMatrix * Vertex;
  dist = length(gl_ClipVertex);
  vec4 LightVec = Vertex - gl_LightSource[0].position;
  gl_TexCoord[7] = mapPixelToQuad(Vertex.xz + LightVec.xz / abs(LightVec.y) * Vertex.y);
  gl_Position = gl_ModelViewProjectionMatrix * Vertex;
}