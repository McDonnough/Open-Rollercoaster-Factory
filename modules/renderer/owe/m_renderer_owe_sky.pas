unit m_renderer_owe_sky;

interface

uses
  SysUtils, Classes, DGLOpenGL, m_renderer_owe_lights, math, u_math, u_vectors, u_events, m_shdmng_class, u_graphics, u_files;

type
  TRSky = class
    protected
      fSun: TSun;
      fCameraLight, fCameraLight2: TLight;
      fShader: TShader;
      fSunColor: TTexImage;
    public
      property Sun: TSun read fSun;
      procedure Render;
      procedure Advance;
      constructor Create;
      destructor Free;
    end;

implementation

uses
  g_park, m_varlist, m_renderer_owe, u_functions;

procedure TRSky.Render;
var
  i, j: Integer;
begin
  fShader.Bind;
  glBegin(GL_QUADS);
    for i := 0 to 17 do
      for j := 0 to 9 do
        begin
        glVertex3f(28793 * sin(DegToRad(20 * (i + 0))) * sin(DegToRad(j + 0)), (cos(DegToRad(j + 0)) - cos(DegToRad(10))) * 32911, 28793 * cos(DegToRad(20 * (i + 0))) * sin(DegToRad(j + 0)));
        glVertex3f(28793 * sin(DegToRad(20 * (i + 1))) * sin(DegToRad(j + 0)), (cos(DegToRad(j + 0)) - cos(DegToRad(10))) * 32911, 28793 * cos(DegToRad(20 * (i + 1))) * sin(DegToRad(j + 0)));
        glVertex3f(28793 * sin(DegToRad(20 * (i + 1))) * sin(DegToRad(j + 1)), (cos(DegToRad(j + 1)) - cos(DegToRad(10))) * 32911, 28793 * cos(DegToRad(20 * (i + 1))) * sin(DegToRad(j + 1)));
        glVertex3f(28793 * sin(DegToRad(20 * (i + 0))) * sin(DegToRad(j + 1)), (cos(DegToRad(j + 1)) - cos(DegToRad(10))) * 32911, 28793 * cos(DegToRad(20 * (i + 0))) * sin(DegToRad(j + 1)));
        end;
  glEnd;
  fShader.Unbind;
end;

procedure TRSky.Advance;
var
  SunXAngle, SunYAngle: Single;
begin
  SunYAngle := 11 * (power(1 + cos(DegToRad(Park.pSky.Time / 86400 * 360)), 2)) + 1;
  SunXAngle := 180 - Park.pSky.Time / 86400 * 360;
  fSun.Position := Vector(28793 * sin(DegToRad((SunXAngle))) * sin(DegToRad(SunYAngle)), (cos(DegToRad(SunYAngle)) - cos(DegToRad(10))) * 32911, 28793 * cos(DegToRad((SunXAngle))) * sin(DegToRad(SunYAngle)), 1.0);
  fSun.AmbientColor := (Vector(0.05, 0.05, 0.05, 0.0) + Vector(0.32, 0.35, 0.5, 0.0) * Clamp(2 * (12 - SunYAngle) / 12, 0, 1) + Vector(0.00, 0.01, 0.05, 0.0) * Clamp(-2 * (12 - SunYAngle) / 12, 0, 1)) * 0.3;
  try
    fSun.Color.X := fSunColor.Data[3 * (Round(Park.pSky.Time) div 10) + 0] / 255;
    fSun.Color.Y := fSunColor.Data[3 * (Round(Park.pSky.Time) div 10) + 1] / 255;
    fSun.Color.Z := fSunColor.Data[3 * (Round(Park.pSky.Time) div 10) + 2] / 255;
//     fSun.Color := fSun.Color - fSun.AmbientColor;
  except
    writeln(Round(Park.pSky.Time) div 10);
  end;
{  if fSun.Position.Y < 0 then
    fSun.Position := Vector(0, 0, 0, 0) - fSun.Position;}
end;

constructor TRSky.Create;
begin
  writeln('Hint: Initializing sky renderer');
  fShader := TShader.Create('orcf-world-engine/scene/sky/sky.vs', 'orcf-world-engine/scene/sky/sky.fs');
  fShader.UniformF('Factor', 1.0);
  if ModuleManager.ModRenderer.UseBloom then
    fShader.UniformF('Factor', 0.8);
  fSun := TSun.Create;
  fSunColor := TexFromStream(ByteStreamFromFile('orcf-world-engine/scene/sky/sun-color/suncolor.tga'), '.tga');
end;

destructor TRSky.Free;
begin
  fSun.Free;
  fShader.Free;
end;

end.