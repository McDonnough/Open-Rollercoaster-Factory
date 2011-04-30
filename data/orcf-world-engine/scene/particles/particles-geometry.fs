#version 120

uniform sampler2D TransparencyMask;
uniform sampler2D Texture;

uniform vec3 ViewPoint;

uniform vec2 MaskOffset;
uniform vec2 MaskSize;

uniform ivec3 MaterialID;

varying vec3 Vertex;
varying vec3 Normal;

void main(void) {
  gl_FragData[3].a = 1.0;
  gl_FragData[3].rgb = MaterialID;
  gl_FragData[3].rgb /= 255.0;
  gl_FragData[0] = gl_FrontMaterial.diffuse * gl_Color;
  gl_FragData[0] *= texture2D(Texture, gl_TexCoord[0].xy);
  if (gl_FragData[0].a <= texture2D(TransparencyMask, (gl_FragCoord.xy) / MaskSize + MaskOffset).a)
    discard;
  gl_FragData[0].a = gl_FrontMaterial.specular.r;
  gl_FragData[5] = gl_FrontMaterial.emission * vec4(gl_FragData[0].rgb, 1.0);
  gl_FragData[4] = vec4(0.0, 0.0, 0.0, 0.0);
  gl_FragData[2].rgb = Vertex;
  gl_FragData[2].a = length(gl_ModelViewMatrix * vec4(Vertex, 1.0));
  gl_FragData[1] = vec4(Normal, gl_FrontMaterial.shininess);
}