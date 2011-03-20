#version 120

uniform float Height;

varying vec2 Vertex;

void main(void) {
  Vertex = gl_Vertex.xy;
  gl_Position = gl_ModelViewProjectionMatrix * vec4(gl_Vertex.x, Height, gl_Vertex.y, 1.0);
}
