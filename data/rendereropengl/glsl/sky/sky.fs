#version 120

varying vec3 Vertex;
varying vec3 BaseVertex;

void main(void) {
  float angle = max(0.0, dot(normalize(gl_LightSource[0].position.xyz), normalize(Vertex)));
  gl_FragColor = mix(gl_LightSource[0].ambient * gl_LightSource[0].ambient,
                     2.0 * gl_LightSource[0].diffuse * gl_LightSource[0].diffuse * pow(length(gl_LightSource[0].ambient) / length(gl_LightSource[0].diffuse), 2.0),
                     max(0.0, pow(angle, 2.0)) * (1.0 - pow(dot(vec3(0.0, 1.0, 0.0), normalize(BaseVertex)), 0.5)))
                   * 4.5 / (0.3 + 0.7 * (1.0 - pow(1.0 - dot(vec3(0.0, 1.0, 0.0), normalize(BaseVertex)), 4.0)));
  gl_FragColor += 10.0 * gl_LightSource[0].diffuse * pow(angle, 2048.0);
  gl_FragColor.a = 1.0;
}