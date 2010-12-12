unit m_renderer_owe_sky;

interface

uses
  SysUtils, Classes, DGLOpenGL, m_renderer_owe_lights, math, u_math, u_vectors, u_events, m_shdmng_class, u_graphics, u_files, m_texmng_class;

type
  TRSky = class
    protected
      fSun: TSun;
      fCameraLight, fCameraLight2: TLight;
      fShader: TShader;
      fSunColor: TTexImage;
      fStarTexture: TTexture;
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
  fStarTexture.Bind;
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
  fSun.AmbientColor := (Vector(0.05, 0.05, 0.05, 0.0) + Vector(0.32, 0.35, 0.5, 0.0) * Clamp(2 * (12 - SunYAngle) / 12, 0, 1) + Vector(0.00, 0.01, 0.05, 0.0) * Clamp(-2 * (12 - SunYAngle) / 12, 0, 1)) * Vector(1.0, 0.8, 0.6, 1.0);
  fSun.Color.X := fSunColor.Data[3 * (Round(Park.pSky.Time) div 10) + 0] / 255;
  fSun.Color.Y := fSunColor.Data[3 * (Round(Park.pSky.Time) div 10) + 1] / 255;
  fSun.Color.Z := fSunColor.Data[3 * (Round(Park.pSky.Time) div 10) + 2] / 255;
//     fSun.Color := fSun.Color - fSun.AmbientColor;
{  if fSun.Position.Y < 0 then
    fSun.Position := Vector(0, 0, 0, 0) - fSun.Position;}
end;

constructor TRSky.Create;
begin
  writeln('Hint: Initializing sky renderer');
  fShader := TShader.Create('orcf-world-engine/scene/sky/sky.vs', 'orcf-world-engine/scene/sky/sky.fs');
  fShader.UniformI('StarTexture', 0);
  fShader.UniformF('Factor', 1.0 - 0.2 * ModuleManager.ModRenderer.BloomFactor);
  fSun := TSun.Create;
  fSunColor := TexFromStream(ByteStreamFromFile('orcf-world-engine/scene/sky/sun-color/suncolor.tga'), '.tga');
  fStarTexture := TTexture.Create;
  fStarTexture.FromFile('orcf-world-engine/scene/sky/stars.tga');
end;

destructor TRSky.Free;
begin
  fStarTexture.Free;
  fSun.Free;
  fShader.Free;
end;

end.