unit m_renderer_opengl_sky;

interface

uses
  SysUtils, Classes, DGLOpenGL, m_renderer_opengl_lights, math, u_math, u_vectors, u_events, m_shdmng_class;

type
  TRSky = class
    protected
      fSun: TSun;
      fShader: TShader;
    public
      property Sun: TSun read fSun;
      procedure Render;
      constructor Create;
      destructor Free;
    end;

implementation

uses
  g_park;

procedure TRSky.Render;
begin
  fSun.Position := Vector(sin(2 * PI * Park.pSky.Time / 86400), -cos(2 * PI * Park.pSky.Time / 86400), cos(2 * PI * Park.pSky.Time / 86400), 0);
  fSun.AmbientColor := Vector(0.05, 0.05, 0.05, 0.0) + Vector(0.3, 0.3, 0.35, 0.0) * Clamp(2 * fSun.Position.Y, 0, 1) + Vector(0.02, 0.04, 0.1, 0.0) * Clamp(-2 * fSun.Position.Y, 0, 1);
  fSun.Color := Vector(0.9, 0.85, 0.8, 1);
  fSun.Color := fSun.Color * Clamp(1.4 * fSun.Position.Y, 0, 1);
  fSun.Color.Y := fSun.Color.Y * Clamp(0.8 + fSun.Position.Y / 2, 0, 1);
  fSun.Color.Z := fSun.Color.Z * Clamp(0.6 + fSun.Position.Y, 0, 1);
  fSun.Color := fSun.Color + Vector(0.02, 0.04, 0.1, 0.0) * Clamp(-2 * fSun.Position.Y, 0, 1);
  fSun.Position := fSun.Position * 1000000000;
  if fSun.Position.Y < 0 then
    fSun.Position := Vector(0, 0, 0, 0) - fSun.Position;
  fSun.Bind(0);
  fShader.Bind;
  glDepthMask(false);
  glBegin(GL_QUADS);
    glVertex3f(-5000, 2500, -5000);
    glVertex3f( 5000, 2500, -5000);
    glVertex3f( 5000, 2500,  5000);
    glVertex3f(-5000, 2500,  5000);

    glVertex3f(-5000,    0, -5000);
    glVertex3f( 5000,    0, -5000);
    glVertex3f( 5000, 2500, -5000);
    glVertex3f(-5000, 2500, -5000);

    glVertex3f(-5000, 2500,  5000);
    glVertex3f( 5000, 2500,  5000);
    glVertex3f( 5000,    0,  5000);
    glVertex3f(-5000,    0,  5000);

    glVertex3f(-5000, 2500, -5000);
    glVertex3f(-5000, 2500,  5000);
    glVertex3f(-5000,    0,  5000);
    glVertex3f(-5000,    0, -5000);

    glVertex3f( 5000,    0, -5000);
    glVertex3f( 5000,    0,  5000);
    glVertex3f( 5000, 2500,  5000);
    glVertex3f( 5000, 2500, -5000);
  glEnd;
  glDepthMask(true);
  fShader.Unbind;
end;

constructor TRSky.Create;
begin
  fShader := TShader.Create('rendereropengl/glsl/sky/sky.vs', 'rendereropengl/glsl/sky/sky.fs');
  fSun := TSun.Create;
end;

destructor TRSky.Free;
begin
  fSun.Free;
  fShader.Free;
end;

end.