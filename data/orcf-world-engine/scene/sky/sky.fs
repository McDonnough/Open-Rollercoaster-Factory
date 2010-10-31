#version 120

varying vec3 Vertex;

void main(void) {
  gl_FragData[0] = vec4(0.0, 0.0, 0.0, 0.0);
  gl_FragData[1] = vec4(0.0, 0.0, 0.0, 0.0);

  vec3 pos = gl_LightSource[0].position.xyz;
  float angle = max(0.0, dot(normalize(pos), normalize(Vertex)));

  gl_FragData[2].rgb = gl_LightSource[0].ambient.rgb * pow(0.5, distance(pos, Vertex) / 5000.0);
  gl_FragData[2].rgb *= (0.25 + 0.75 * pow((500 - Vertex.y) / 500.0, 2.0)) * 3.0;
  gl_FragData[2].rgb += gl_LightSource[0].diffuse.rgb * pow(0.5, distance(pos, Vertex) / 2000.0) / 2.0;
  gl_FragData[2].rgb += gl_LightSource[0].diffuse.rgb * pow(angle, 1000.0);
  gl_FragData[2].rgb += 0.1 * gl_LightSource[0].diffuse.rgb * pow(angle, 20.0);
  gl_FragData[2].a = 1.0;
}