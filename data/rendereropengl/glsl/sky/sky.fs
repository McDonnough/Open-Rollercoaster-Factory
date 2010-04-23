#version 120

varying vec3 Vertex;
varying vec3 EndlessVertex;

void main(void) {
  gl_FragColor = 10.0 * gl_LightSource[0].diffuse * pow(dot(normalize(gl_LightSource[0].position.xyz), normalize(Vertex)), 2048.0);
  gl_FragColor += gl_LightSource[0].diffuse * clamp((250000000 - distance(EndlessVertex.xz, gl_LightSource[0].position.xz)), 0.0, 1.0);
  gl_FragColor.a = 1.0;
}