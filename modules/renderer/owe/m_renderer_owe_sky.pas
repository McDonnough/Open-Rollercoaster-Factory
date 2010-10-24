unit m_renderer_owe_sky;

interface

uses
  SysUtils, Classes, DGLOpenGL, m_renderer_owe_lights, math, u_math, u_vectors, u_events, m_shdmng_class;

type
  TRSky = class
    protected
      fSun: TSun;
      fCameraLight, fCameraLight2: TLight;
      fShader: TShader;
    public
      property Sun: TSun read fSun;
      procedure Render(Event: String; Data, Result: Pointer);
      procedure Advance;
      constructor Create;
      destructor Free;
    end;

implementation

uses
  g_park, m_varlist, m_renderer_owe, u_functions;

procedure TRSky.Render(Event: String; Data, Result: Pointer);
begin
  fShader.Bind;
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

    glVertex3f(-5000,    0, -5000);
    glVertex3f(-5000,    0,  5000);
    glVertex3f( 5000,    0,  5000);
    glVertex3f( 5000,    0, -5000);
  glEnd;
  fShader.Unbind;
end;

procedure TRSky.Advance;
begin
  fSun.Position := Vector(sin(2 * PI * Park.pSky.Time / 86400), -cos(2 * PI * Park.pSky.Time / 86400), -cos(2 * PI * Park.pSky.Time / 86400), 0);
  fSun.Position.Y *= 2;
  fSun.AmbientColor := Vector(0.05, 0.05, 0.05, 0.0) + Vector(0.32, 0.35, 0.5, 0.0) * Clamp(2 * fSun.Position.Y, 0, 1) + Vector(0.00, 0.01, 0.05, 0.0) * Clamp(-2 * fSun.Position.Y, 0, 1);
  fSun.Color := Vector(0.9, 0.85, 0.78, 1);
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
  writeln('Hint: Initializing sky renderer');
  fShader := TShader.Create('orcf-world-engine/scene/sky/sky.vs', 'orcf-world-engine/scene/sky/sky.fs');
  fSun := TSun.Create;
end;

destructor TRSky.Free;
begin
  fSun.Free;
  fShader.Free;
end;

end.