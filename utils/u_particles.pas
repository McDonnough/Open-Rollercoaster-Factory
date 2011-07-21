unit u_particles;

interface

uses
  SysUtils, Classes, u_linkedlists, u_vectors, u_scene, u_math, math, u_scripts;

type
  TParticle = class(TLinkedListItem)
    public
      MaxLifetime, TimeLived: Single;
      Size, InitialSize, SizeExponent: TVector2D;
      Color, InitialColor, ColorExponent: TVector4D;
      Velocity, Acceleration: TVector3D;
      Position: TVector3D;
      Rotation, InitialSpin, Spin, SpinExponent: Single;
      procedure AdvanceNormal(TimeFactor: Single);
    end;

  TParticleGroup = class(TLinkedList)
    public
//       Script: TScript;
      Name: String;
      Running: Boolean;
      NeedsIllumination: Boolean;
      Material: TMaterial;
      Lifetime, LifetimeVariance: Single;
      GenerationTime, GenerationTimeVariance: Single;
      NextGenerationTime: Single;
      InitialSize, SizeExponent, SizeVariance: TVector2D;
      InitialColor, ColorExponent, ColorVariance: TVector4D;
      InitialVelocity, VelocityVariance: TVector3D;
      InitialAcceleration, AccelerationVariance: TVector3D;
      InitialPosition, PositionVariance: TVector3D;
      InitialRotation, RotationVariance: Single;
      InitialSpin, SpinExponent, SpinVariance: Single;
      OriginalVelocity, OriginalVelocityVariance: TVector3D;
      OriginalPosition, OriginalVariance: TVector3D;
      procedure AdvanceGroup(TimeFactor: Single);
      function AddParticle: TParticle;
      function Duplicate: TParticleGroup;
      procedure Register;
      procedure SetIO(Script: TScript);
      class procedure RegisterStruct;
      constructor Create;
      procedure Free;
    end;

implementation

uses
  u_events, m_varlist;

var
  ioSize: Integer;

procedure TParticle.AdvanceNormal(TimeFactor: Single);
begin
  TimeLived := TimeLived + TimeFactor;
  Spin := InitialSpin * Power(2.7183, SpinExponent);
  Rotation := Rotation + Spin * TimeFactor;
  Velocity := Velocity + Acceleration * TimeFactor;
  Position := Position + Velocity * TimeFactor;
  Size := Vector(InitialSize.X * Power(2.7183, SizeExponent.X * TimeLived),
                 InitialSize.Y * Power(2.7183, SizeExponent.Y * TimeLived));
  Color := Vector(InitialColor.X * Power(2.7183, ColorExponent.X * TimeLived),
                  InitialColor.Y * Power(2.7183, ColorExponent.Y * TimeLived),
                  InitialColor.Z * Power(2.7183, ColorExponent.Z * TimeLived),
                  InitialColor.W * Power(2.7183, ColorExponent.W * TimeLived) * Min(1.0, 5 * TimeLived) * Min(1.0, 5 * (MaxLifetime - TimeLived)));
end;


procedure TParticleGroup.AdvanceGroup(TimeFactor: Single);
var
  CurrItem, NextItem: TParticle;
begin
  CurrItem := TParticle(First);
  while CurrItem <> nil do
    begin
    NextItem := TParticle(CurrItem.Next);
    if CurrItem.TimeLived > CurrItem.MaxLifetime then
      CurrItem.Free
    else
      CurrItem.AdvanceNormal(TimeFactor);
    CurrItem := NextItem;
    end;
  if Running then
    begin
    if NextGenerationTime <= 0 then
      begin
      NextGenerationTime := GenerationTime * Power(2, GenerationTimeVariance * QRandom);
      AddParticle;
      end;
    NextGenerationTime := NextGenerationTime - TimeFactor;
    end;
end;

function TParticleGroup.AddParticle: TParticle;
begin
  Result := TParticle.Create;

  Result.TimeLived := 0;
  Result.MaxLifetime := Lifetime * Power(2, LifetimeVariance * QRandom);

  Result.InitialSize := Vector(InitialSize.X * Power(2, SizeVariance.X * QRandom),
                               InitialSize.Y * Power(2, SizeVariance.Y * QRandom));
  Result.SizeExponent := SizeExponent;
  Result.Size := Result.InitialSize;

  Result.InitialColor := Vector(InitialColor.X * Power(2, ColorVariance.X * QRandom),
                                InitialColor.Y * Power(2, ColorVariance.Y * QRandom),
                                InitialColor.Z * Power(2, ColorVariance.Z * QRandom),
                                InitialColor.W * Power(2, ColorVariance.W * QRandom));
  Result.ColorExponent := ColorExponent;
  Result.Color := Result.InitialColor;
  Result.Color.W := 0;

  Result.Velocity := InitialVelocity + VelocityVariance * Vector(QRandom, QRandom, QRandom);

  Result.Acceleration := Vector(InitialAcceleration.X * Power(2, AccelerationVariance.X * QRandom),
                                InitialAcceleration.Y * Power(2, AccelerationVariance.Y * QRandom),
                                InitialAcceleration.Z * Power(2, AccelerationVariance.Z * QRandom));

  Result.Position := InitialPosition + PositionVariance * Vector(QRandom, QRandom, QRandom);

  Result.Rotation := InitialRotation + RotationVariance * QRandom;
  Result.InitialSpin := InitialSpin * Power(2, SpinVariance * QRandom);
  Result.SpinExponent := SpinExponent;
  Result.Spin := Result.InitialSpin;

  Prepend(Result);
end;

function TParticleGroup.Duplicate: TParticleGroup;
begin
  Result := TParticleGroup.Create;
  Result.Name := Name;
  Result.Running := Running;
  Result.NeedsIllumination := NeedsIllumination;
  Result.Material := Material.Duplicate;
  Result.Lifetime := Lifetime;
  Result.LifetimeVariance := LifetimeVariance;
  Result.GenerationTime := GenerationTime;
  Result.GenerationTimeVariance := GenerationTimeVariance;
  Result.NextGenerationTime := NextGenerationTime;
  Result.InitialSize := InitialSize;
  Result.SizeExponent := SizeExponent;
  Result.SizeVariance := SizeVariance;
  Result.InitialColor := InitialColor;
  Result.ColorExponent := ColorExponent;
  Result.ColorVariance := ColorVariance;
  Result.InitialVelocity := InitialVelocity;
  Result.VelocityVariance := VelocityVariance;
  Result.OriginalVelocity := OriginalVelocity;
  Result.OriginalVelocityVariance := OriginalVelocityVariance;
  Result.InitialAcceleration := InitialAcceleration;
  Result.AccelerationVariance := AccelerationVariance;
  Result.InitialPosition := InitialPosition;
  Result.PositionVariance := PositionVariance;
  Result.OriginalPosition := OriginalPosition;
  Result.OriginalVariance := OriginalVariance;
  Result.InitialRotation := InitialRotation;
  Result.RotationVariance := RotationVariance;
  Result.InitialSpin := InitialSpin;
  Result.SpinExponent := SpinExponent;
  Result.SpinVariance := SpinVariance;
end;

procedure TParticleGroup.Register;
begin
  EventManager.CallEvent('TParticleGroup.Added', self, nil);
end;

procedure TParticleGroup.SetIO(Script: TScript);
begin
  Script.SetIO(@lifetime, ioSize, True);
end;

class procedure TParticleGroup.RegisterStruct;
begin
  ModuleManager.ModScriptManager.SetDataStructure('ParticleEmitter',
   'float lifetime' + #10 +
   'float lifetimeVariance' + #10 +
   'float generationTime' + #10 +
   'float generationTimeVariance' + #10 +
   'float nextGenerationTime' + #10 +
   'vec2 initialSize' + #10 +
   'vec2 sizeExponent' + #10 +
   'vec2 sizeVariance' + #10 +
   'vec4 initialColor' + #10 +
   'vec4 colorExponent' + #10 +
   'vec4 colorVariance' + #10 +
   'vec3 initialVelocity' + #10 +
   'vec3 velocityVariance' + #10 +
   'vec3 initialAcceleration' + #10 +
   'vec3 accelerationVariance' + #10 +
   'vec3 initialPosition' + #10 +
   'vec3 positionVariance' + #10 +
   'float initialRotation' + #10 +
   'float rotationVariance' + #10 +
   'float initialSpin' + #10 +
   'float spinExponent' + #10 +
   'float spinVariance');
  ioSize := ModuleManager.ModScriptManager.DataStructureSize('ParticleEmitter');
end;

constructor TParticleGroup.Create;
begin
  inherited Create;
  Name := '';
  Running := True;
  NeedsIllumination := False;
  Material := nil;
  Lifetime := 10;
  LifetimeVariance := 0;
  GenerationTime := 1;
  GenerationTimeVariance := 0;
  NextGenerationTime := 0;
  InitialSize := Vector(1, 1);
  SizeExponent := Vector(0, 0);
  SizeVariance := Vector(0, 0);
  InitialColor := Vector(0, 0, 0, 0);
  ColorExponent := Vector(0, 0, 0, 0);
  ColorVariance := Vector(0, 0, 0, 0);
  InitialVelocity := Vector(0, 0, 0);
  VelocityVariance := Vector(0, 0, 0);
  OriginalVelocity := Vector(0, 0, 0);
  OriginalVelocityVariance := Vector(0, 0, 0);
  InitialAcceleration := Vector(0, 0, 0);
  AccelerationVariance := Vector(0, 0, 0);
  InitialPosition := Vector(0, 0, 0);
  PositionVariance := Vector(0, 0, 0);
  OriginalPosition := Vector(0, 0, 0);
  OriginalVariance := Vector(0, 0, 0);
  InitialRotation := 0;
  RotationVariance := 0;
  InitialSpin := 0;
  SpinExponent := 0;
  SpinVariance := 0;
end;

procedure TParticleGroup.Free;
begin
  EventManager.CallEvent('TParticleGroup.Deleted', self, nil);
  inherited Free;
end;

end.