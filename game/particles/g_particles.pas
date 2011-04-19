unit g_particles;

interface

uses
  SysUtils, Classes, u_particles, u_linkedlists;

type
  TParticleGroupList = TLinkedList;

  TParticleGroupItem = class(TLinkedListItem)
    protected
      fGroup: TParticleGroup;
    public
      property Group: TParticleGroup read fGroup;
      constructor Create(TheGroup: TParticleGroup);
      procedure Free;
    end;

  TParticleManager = class
    protected
      fEmitters: TParticleGroupList;
    public
      property Emitters: TParticleGroupList read fEmitters;
      procedure Add(Group: TParticleGroup);
      procedure Delete(Group: TParticleGroup);
      procedure Advance;
      constructor Create;
      destructor Free;
    end;

implementation

uses
  Main, m_texmng_class, u_math, u_vectors, u_scene;

constructor TParticleGroupItem.Create(TheGroup: TParticleGroup);
begin
  inherited Create;
  fGroup := TheGroup;
end;

procedure TParticleGroupItem.Free;
begin
  Group.Free;
  inherited Free;
end;

procedure TParticleManager.Add(Group: TParticleGroup);
begin
  Emitters.Append(TParticleGroupItem.Create(Group));
end;

procedure TParticleManager.Delete(Group: TParticleGroup);
var
  CurrentGroup, NextGroup: TParticleGroupItem;
begin
  CurrentGroup := TParticleGroupItem(Emitters.First);
  while CurrentGroup <> nil do
    begin
    NextGroup := TParticleGroupItem(CurrentGroup.Next);
    if CurrentGroup.Group = Group then
      CurrentGroup.Group.Running := False;
    CurrentGroup := NextGroup;
    end;
end;

procedure TParticleManager.Advance;
var
  CurrentGroup, NextGroup: TParticleGroupItem;
begin
  CurrentGroup := TParticleGroupItem(Emitters.First);
  while CurrentGroup <> nil do
    begin
    NextGroup := TParticleGroupItem(CurrentGroup.Next);

    if (CurrentGroup.Group.Running) or (not CurrentGroup.Group.IsEmpty) then
      CurrentGroup.Group.AdvanceGroup(0.001 * FPSDisplay.MS)
    else
      CurrentGroup.Free;

    CurrentGroup := NextGroup;
    end;
end;

constructor TParticleManager.Create;
var
  A: TParticleGroup;
begin
  writeln('Hint: Creating ParticleManager object');
  fEmitters := TParticleGroupList.Create;

  // TEST

  A := TParticleGroup.Create;
  
  A.Running := True;
  A.Material := TMaterial.Create;
  A.Material.Color := Vector(1, 1, 1, 1);
  A.Material.Emission := Vector(0, 0, 0, 1);
  A.Material.Reflectivity := 0;
  A.Material.Specularity := 1;
  A.Material.Hardness := 20;
  A.Material.OnlyEnvironmentMapHint := True;
  A.Material.Texture := TTexture.Create;
  A.Material.Texture.FromFile('scenery/testparticle.tga');
  
  A.Lifetime := 5.0;
  A.LifetimeVariance := 0.1;
  A.GenerationTime := 1;
  A.GenerationTimeVariance := 0.1;
  A.NextGenerationTime := -1;
  A.InitialSize := Vector(1, 1);
  A.SizeExponent := Vector(0.2, 0.2);
  A.SizeVariance := Vector(0.2, 0.2);
  A.InitialColor := Vector(0, 0, 0, 1);
  A.ColorExponent := Vector(0, 0, 0, -0.8);
  A.ColorVariance := Vector(0, 0, 0, 0);
  A.InitialLighting := 0;
  A.LightingExponent := 0;
  A.LightingVariance := 0;
  A.InitialVelocity := Vector(0, 0, 0);
  A.VelocityVariance := Vector(0, 0, 0);
  A.InitialAcceleration := Vector(0, 0.4, 0);
  A.AccelerationVariance := Vector(0, 0.5, 0);
  A.InitialPosition := Vector(0, 64, 0);
  A.PositionVariance := Vector(0, 0, 0);
  A.InitialRotation := 0;
  A.RotationVariance := 3.141592;
  A.InitialSpin := 1;
  A.SpinExponent := 0;
  A.SpinVariance := 0.1;

  Add(A);
end;

destructor TParticleManager.Free;
begin
  writeln('Hint: Deleting ParticleManager object');
  fEmitters.Free;
end;

end.