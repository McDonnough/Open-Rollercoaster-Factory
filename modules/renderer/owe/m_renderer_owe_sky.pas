unit m_renderer_owe_sky;

interface

uses
  SysUtils, Classes, DGLOpenGL, m_renderer_owe_lights, math, u_math, u_vectors, u_events, m_shdmng_class, u_graphics, u_files, m_texmng_class,
  u_scene, u_particles;

type
  TRSky = class
    protected
      fSun: TSun;
      fCameraLight, fCameraLight2: TLight;
      fShader: TShader;
      fSunColor: TTexImage;
      fStarTexture: TTexture;
      fFogStrength: Single;
      A: TParticleGroup;
    public
      property FogStrength: Single read fFogStrength;
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
  fStarTexture.Bind(0);
  fShader.Bind;
  glBegin(GL_QUADS);
    for i := 0 to 17 do
      for j := 0 to 11 do
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
  A.InitialPosition := ModuleManager.ModRenderer.SelectionStart + ModuleManager.ModRenderer.SelectionRay;
  fFogStrength := 0.0;
  SunYAngle := 11 * (power(1 + cos(DegToRad(Park.pSky.Time / 86400 * 360)), 2)) + 1;
  SunXAngle := 180 - Park.pSky.Time / 86400 * 360;
  fSun.Position := Vector(28793 * sin(DegToRad((SunXAngle))) * sin(DegToRad(SunYAngle)), (cos(DegToRad(SunYAngle)) - cos(DegToRad(10))) * 32911, 28793 * cos(DegToRad((SunXAngle))) * sin(DegToRad(SunYAngle)), 1.0);
  fSun.AmbientColor := (Vector(0.05, 0.05, 0.05, 0.0) + Vector(0.32, 0.35, 0.5, 0.0) * Clamp(2 * (12 - SunYAngle) / 12, 0, 1) + Vector(0.00, 0.01, 0.05, 0.0) * Clamp(-2 * (12 - SunYAngle) / 12, 0, 1)) * Vector(1.0, 0.8, 0.6, 1.0);
  fSun.Color.X := fSunColor.Data[3 * (Round(Park.pSky.Time) div 10) + 0] / 255;
  fSun.Color.Y := fSunColor.Data[3 * (Round(Park.pSky.Time) div 10) + 1] / 255;
  fSun.Color.Z := fSunColor.Data[3 * (Round(Park.pSky.Time) div 10) + 2] / 255;
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


  A := TParticleGroup.Create;

  A.Running := True;
  A.Material := TMaterial.Create;
  A.Material.Color := Vector(0.5, 0.5, 0.5, 1);
  A.Material.Emission := Vector(0, 0, 0, 1);
  A.Material.Reflectivity := 0;
  A.Material.Specularity := 0.2;
  A.Material.Hardness := 5;
  A.Material.OnlyEnvironmentMapHint := True;
  A.Material.Texture := TTexture.Create;
  A.Material.Texture.FromFile('scenery/testparticle.tga');

  A.Lifetime := 10.0;
  A.LifetimeVariance := 0.0;
  A.GenerationTime := 0.20;
  A.GenerationTimeVariance := 0.1;
  A.NextGenerationTime := -1;
  A.InitialSize := Vector(1, 1);
  A.SizeExponent := Vector(0.2, 0.2);
  A.SizeVariance := Vector(0.2, 0.2);
  A.InitialColor := Vector(1.0, 1.0, 1.0, 1);
  A.ColorExponent := Vector(0, 0, 0, -0.3);
  A.ColorVariance := Vector(0, 0, 0, 0);
  A.InitialVelocity := Vector(0, 0, 0);
  A.VelocityVariance := Vector(0, 0, 0);
  A.InitialAcceleration := Vector(0.1, 0.4, 0);
  A.AccelerationVariance := Vector(1, 0.8, 1);
  A.InitialPosition := Vector(160, 64, 160);
  A.PositionVariance := Vector(0.1, 0, 0.1);
  A.InitialRotation := 0;
  A.RotationVariance := 3.141592;
  A.InitialSpin := 1;
  A.SpinExponent := -0.1;
  A.SpinVariance := 0.1;
  A.NeedsIllumination := False;

  Park.pParticles.Add(A);

  A := TParticleGroup.Create;

  A.Running := True;
  A.Material := TMaterial.Create;
  A.Material.Color := Vector(1, 1, 1, 1);
  A.Material.Emission := Vector(1, 1, 1, 1);
  A.Material.Reflectivity := 0;
  A.Material.Specularity := 0;
  A.Material.Hardness := 1;
  A.Material.OnlyEnvironmentMapHint := True;
  A.Material.Texture := TTexture.Create;
  A.Material.Texture.FromFile('scenery/testparticle.tga');

  A.Lifetime := 5.0;
  A.LifetimeVariance := 0.0;
  A.GenerationTime := 0.20;
  A.GenerationTimeVariance := 0.1;
  A.NextGenerationTime := -1;
  A.InitialSize := Vector(1, 1);
  A.SizeExponent := Vector(0.5, 0.5);
  A.SizeVariance := Vector(0.2, 0.2);
  A.InitialColor := Vector(1.0, 1.0, 1.0, 1);
  A.ColorExponent := Vector(0, -0.2, -0.6, -0.5);
  A.ColorVariance := Vector(0, 0, 0, 0);
  A.InitialVelocity := Vector(0, 0, 0);
  A.VelocityVariance := Vector(0, 0, 0);
  A.InitialAcceleration := Vector(0.1, 0.4, 0);
  A.AccelerationVariance := Vector(0, 0.5, 0);
  A.InitialPosition := Vector(0, 64, 0);
  A.PositionVariance := Vector(0.1, 0, 0.1);
  A.InitialRotation := 0;
  A.RotationVariance := 3.141592;
  A.InitialSpin := 1;
  A.SpinExponent := -0.1;
  A.SpinVariance := 0.1;
  A.NeedsIllumination := False;

  Park.pParticles.Add(A);
end;

destructor TRSky.Free;
begin
  fStarTexture.Free;
  fSun.Free;
  fShader.Free;
end;

end.