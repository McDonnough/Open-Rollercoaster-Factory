unit m_renderer_opengl_sky;

interface

uses
  SysUtils, Classes, DGLOpenGL, m_renderer_opengl_lights, math, u_math, u_vectors, u_events, m_shdmng_class, m_renderer_opengl_interface;

type
  TRSky = class
    protected
      fSun: TSun;
      fShader: TShader;
    public
      property Sun: TSun read fSun;
      procedure Render;
      procedure Advance;
      constructor Create;
      destructor Free;
    end;

implementation

uses
  g_park;

procedure TRSky.Render;
begin
  glPushMatrix;
  glLoadIdentity;
  fSun.Bind(0);
  glPopMatrix;
  if fInterface.Options.Items['sky:rendering'] = 'off' then
    exit;
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

procedure TRSky.Advance;
begin
  fSun.Position := Vector(sin(2 * PI * Park.pSky.Time / 86400), -cos(2 * PI * Park.pSky.Time / 86400), -cos(2 * PI * Park.pSky.Time / 86400), 0);
  fSun.AmbientColor := Vector(0.05, 0.05, 0.05, 0.0) + Vector(0.2, 0.25, 0.32, 0.0) * Clamp(2 * fSun.Position.Y, 0, 1) + Vector(0.00, 0.01, 0.05, 0.0) * Clamp(-2 * fSun.Position.Y, 0, 1);
  fSun.Color := Vector(1.0, 0.95, 0.88, 1);
  fSun.Color := fSun.Color * Clamp(2.0 * fSun.Position.Y, 0, 1);
  fSun.Color.Y := fSun.Color.Y * Clamp(0.6 + 1.0 * fSun.Position.Y, 0, 1);
  fSun.Color.Z := fSun.Color.Z * Clamp(0.4 + 1.8 * fSun.Position.Y, 0, 1);
  fSun.Color := fSun.Color + Vector(0.02, 0.04, 0.1, 0.0) * Clamp(-2 * fSun.Position.Y, 0, 1);
  fSun.Position := fSun.Position * 10000;
  if fSun.Position.Y < 0 then
    fSun.Position := Vector(0, 0, 0, 0) - fSun.Position;
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