#version 120

uniform sampler2D StarTexture;
uniform float Factor;

varying vec3 Vertex;

void main(void) {
  gl_FragData[2] = vec4(0.0, 0.0, 0.0, 5000.0);
  gl_FragData[1] = vec4(0.0, 0.0, 0.0, 0.0);

  float StarFac = 4.0 * clamp(0.2 + dot(normalize(gl_LightSource[0].position.rgb), vec3(0.0, -1.0, 0.0)), 0.0, 0.25);

  vec3 pos = gl_LightSource[0].position.xyz;
  float angle = max(0.0, dot(normalize(pos), normalize(Vertex)));
  float dist = distance(pos, Vertex);
  float len = length(Vertex);

/*  gl_FragData[0].rgb = 3.0 * (300.0 * pow(gl_LightSource[0].ambient.rgb, vec3(4.0, 4.0, 4.0))) * pow(0.5, dist / 10000.0);
  gl_FragData[0].rgb *= (0.25 + 0.75 * pow((500 - Vertex.y) / 500.0, 2.0)) * 3.0;
  gl_FragData[0].rgb += gl_LightSource[0].diffuse.rgb * pow(0.5, dist / 2000.0) / 2.0;
  gl_FragData[0].rgb += gl_LightSource[0].diffuse.rgb * pow(angle, 1000.0);
  gl_FragData[0].rgb += 0.1 * gl_LightSource[0].diffuse.rgb * pow(angle, 20.0);
  gl_FragData[0].rgb += gl_LightSource[0].diffuse.rgb * pow(len / 5500.0, 4.0) * clamp(5.0 - 5.0 * dot(normalize(pos), normalize(pos * vec3(1.0, 0.0, 1.0))), 0.0, 1.0);*/
  gl_FragData[0].rgb = mix(vec3(0.24, 0.54, 0.82), vec3(1.0, 1.0, 1.0), 1.0 - Vertex.y / 500.0) * clamp(0.05 + 2.5 * dot(normalize(pos), vec3(0.0, 1.0, 0.0)), 0.0, 1.0);
  gl_FragData[0].rgb += mix(vec3(0.03, 0.02, 0.18), vec3(0.03, 0, 0.49), 1.0 - Vertex.y / 500.0) * clamp(0.05 + 4.0 * dot(normalize(pos), vec3(0.0, -1.0, 0.0)), 0.0, 1.0);
  gl_FragData[0].rgb = mix(gl_FragData[0].rgb, gl_LightSource[0].diffuse.rgb, max(0.0, 0.5 - Vertex.y / 1000.0) * dot(normalize(pos), normalize(pos * vec3(1.0, 0.0, 1.0))) * angle * 2.0);
  gl_FragData[0].rgb += gl_LightSource[0].diffuse.rgb * angle * 0.05;
  gl_FragData[0].rgb += gl_LightSource[0].diffuse.rgb * pow(angle, 20.0) * 0.2;
  gl_FragData[0].rgb += 1.5 * gl_LightSource[0].diffuse.rgb * pow(angle, 1000.0);
  gl_FragData[0].rgb *= 0.9 * Factor;
  gl_FragData[0].rgb += StarFac * texture2D(StarTexture, vec2(pow(abs(Vertex.x / 5000.0), 0.33), pow(abs(Vertex.z / 5000.0), 0.33)) * 3.0 * sign(Vertex.xz)).rgb;
  gl_FragData[0].a = 1.0;
}