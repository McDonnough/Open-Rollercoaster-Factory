#version 120

uniform vec4 MeshColor;
uniform vec2 offset;
uniform int LOD;

varying vec4 Vertex;

void main(void) {
  if ((clamp(Vertex.xz, offset + 0.8, offset + 50.4) == Vertex.xz) && (LOD != 2))
    discard;
  float dist = distance(Vertex.xyz, gl_LightSource[1].position.xyz);
  gl_FragColor = vec4(1.0, 1.0, 1.0, dist);
}
