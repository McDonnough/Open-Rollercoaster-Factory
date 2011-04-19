unit u_particles;

interface

uses
  SysUtils, Classes, u_linkedlists, u_vectors, u_scene, u_math, math;

type
  TParticle = class(TLinkedListItem)
    public
      MaxLifetime, TimeLived: Single;
      Size, InitialSize, SizeExponent: TVector2D;
      Color, InitialColor, ColorExponent: TVector4D;
      Lighting, InitialLighting, LightingExponent: Single;
      Velocity, Acceleration: TVector3D;
      Position: TVector3D;
      Rotation, InitialSpin, Spin, SpinExponent: Single;
      procedure AdvanceNormal(TimeFactor: Single);
    end;

  TParticleGroup = class(TLinkedList)
    public
//       Script: TScript;
      Running: Boolean;
      Material: TMaterial;
      Lifetime, LifetimeVariance: Single;
      GenerationTime, GenerationTimeVariance: Single;
      NextGenerationTime: Single;
      InitialSize, SizeExponent, SizeVariance: TVector2D;
      InitialColor, ColorExponent, ColorVariance: TVector4D;
      InitialLighting, LightingExponent, LightingVariance: Single;
      InitialVelocity, VelocityVariance: TVector3D;
      InitialAcceleration, AccelerationVariance: TVector3D;
      InitialPosition, PositionVariance: TVector3D;
      InitialRotation, RotationVariance: Single;
      InitialSpin, SpinExponent, SpinVariance: Single;
      procedure AdvanceGroup(TimeFactor: Single);
      function AddParticle: TParticle;
    end;

implementation

procedure TParticle.AdvanceNormal(TimeFactor: Single);
begin
  TimeLived := TimeLived + TimeFactor;
  Spin := InitialSpin * Power(2.7183, SpinExponent);
  Rotation := Rotation + Spin / TimeFactor;
  Velocity := Velocity + Acceleration * TimeFactor;
  Position := Position + Velocity * TimeFactor;
  Size := Vector(InitialSize.X * Power(2.7183, SizeExponent.X * TimeLived),
                 InitialSize.Y * Power(2.7183, SizeExponent.Y * TimeLived));
  Color := Vector(InitialColor.X * Power(2.7183, ColorExponent.X * TimeLived),
                  InitialColor.Y * Power(2.7183, ColorExponent.Y * TimeLived),
                  InitialColor.Z * Power(2.7183, ColorExponent.Z * TimeLived),
                  InitialColor.W * Power(2.7183, ColorExponent.W * TimeLived));
  Lighting := InitialLighting * Power(2.7183, LightingExponent * TimeLived);
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

  Result.InitialLighting := InitialLighting * Power(2, LightingVariance * QRandom);
  Result.LightingExponent := LightingExponent;
  Result.Lighting := Result.InitialLighting;

  Result.Velocity := Vector(InitialVelocity.X * Power(2, VelocityVariance.X * QRandom),
                            InitialVelocity.Y * Power(2, VelocityVariance.Y * QRandom),
                            InitialVelocity.Z * Power(2, VelocityVariance.Z * QRandom));

  Result.Acceleration := Vector(InitialAcceleration.X * Power(2, AccelerationVariance.X * QRandom),
                                InitialAcceleration.Y * Power(2, AccelerationVariance.Y * QRandom),
                                InitialAcceleration.Z * Power(2, AccelerationVariance.Z * QRandom));

  Result.Position := InitialPosition + PositionVariance * Vector(QRandom, QRandom, QRandom);

  Result.Rotation := InitialRotation + RotationVariance * QRandom;
  Result.InitialSpin := InitialSpin * Power(2, SpinVariance * QRandom);
  Result.SpinExponent := SpinExponent;
  Result.Spin := Result.InitialSpin;

  Append(Result);
end;

end.