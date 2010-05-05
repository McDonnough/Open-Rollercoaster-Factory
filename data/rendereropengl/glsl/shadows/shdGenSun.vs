#version 120

uniform float Radius;

varying vec4 Vertex;

void main(void) {
  Vertex = gl_ModelViewMatrix * gl_Vertex;
  Vertex.xz = Vertex.xz - Vertex.y * gl_LightSource[0].position.xz / gl_LightSource[0].position.y;
  gl_TexCoord[0] = gl_MultiTexCoord0;
  gl_Position = gl_ProjectionMatrix * (sqrt(abs(Vertex)) / sqrt(Radius) * sign(Vertex)).xzyw;
}