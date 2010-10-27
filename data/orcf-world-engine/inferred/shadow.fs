#version 120

void main(void) {
  gl_FragColor = vec4(gl_FrontMaterial.diffuse.rgb * (1.0 - gl_FrontMaterial.diffuse.a), 1.0);
}