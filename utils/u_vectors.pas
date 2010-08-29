unit u_vectors;

interface

uses
  Classes, SysUtils;

type
  TVector2D = record
    X, Y: Single;
    end;

  TVector3D = record
    X, Y, Z: Single;
    end;

  TVector4D = record
    X, Y, Z, W: Single;
    end;

  PVector2D = ^TVector2D;
  PVector3D = ^TVector3D;
  PVector4D = ^TVector4D;

  TMatrix = Array[0..15] of Single;

  TMatrix3D = Array[0..2] of TVector3D;
  TMatrix4D = Array[0..3] of TVector4D;

function Vector(X, Y: Single): TVector2D;
function Vector(X, Y, Z: Single): TVector3D;
function Vector(X, Y, Z, W: Single): TVector4D;

operator + (A, B: TVector2D): TVector2D;
operator + (A, B: TVector3D): TVector3D;
operator + (A, B: TVector4D): TVector4D;

operator - (A, B: TVector2D): TVector2D;
operator - (A, B: TVector3D): TVector3D;
operator - (A, B: TVector4D): TVector4D;

operator * (A, B: TVector2D): TVector2D;
operator * (A, B: TVector3D): TVector3D;
operator * (A, B: TVector4D): TVector4D;

operator / (A, B: TVector2D): TVector2D;
operator / (A, B: TVector3D): TVector3D;
operator / (A, B: TVector4D): TVector4D;


operator = (A, B: TVector2D): Boolean;
operator = (A, B: TVector3D): Boolean;
operator = (A, B: TVector4D): Boolean;


operator + (A: TVector2D; B: Single): TVector2D;
operator + (A: TVector3D; B: Single): TVector3D;
operator + (A: TVector4D; B: Single): TVector4D;

operator - (A: TVector2D; B: Single): TVector2D;
operator - (A: TVector3D; B: Single): TVector3D;
operator - (A: TVector4D; B: Single): TVector4D;

operator * (A: TVector2D; B: Single): TVector2D;
operator * (A: TVector3D; B: Single): TVector3D;
operator * (A: TVector4D; B: Single): TVector4D;

operator * (A: TVector2D; B: TMatrix): TVector2D;
operator * (A: TVector3D; B: TMatrix): TVector3D;
operator * (A: TVector4D; B: TMatrix): TVector4D;

operator / (A: TVector2D; B: Single): TVector2D;
operator / (A: TVector3D; B: Single): TVector3D;
operator / (A: TVector4D; B: Single): TVector4D;



function VecRound(A: TVector2D): TVector2D;
function VecRound(A: TVector3D): TVector3D;
function VecRound(A: TVector4D): TVector4D;



function VecLength(A: TVector2D): Single;
function VecLength(A: TVector3D): Single;
function VecLength(A: TVector4D): Single;

function VecLengthNoRoot(A: TVector2D): Single;
function VecLengthNoRoot(A: TVector3D): Single;
function VecLengthNoRoot(A: TVector4D): Single;

function Cross(VectorA, VectorB: TVector3D): TVector3D;
function Normal(VectorA, VectorB: TVector3D): TVector3D;
function DotProduct(VectorA, VectorB: TVector3D): Single;

function Normalize(A: TVector2D): TVector2D;
function Normalize(A: TVector3D): TVector3D;
function Normalize(A: TVector4D): TVector4D;

function Vec4toVec3(A: TVector4D): TVector3D;
function Vec3toVec2(A: TVector3D): TVector2D;


function Matrix3D(A, B, C: TVector3D): TMatrix3D;
function Matrix4D(A, B, C, D: TVector4D): TMatrix4D;

operator * (A: TVector3D; B: TMatrix3D): TVector3D;
operator * (A: TVector4D; B: TMatrix4D): TVector4D;

function Rotate(Deg: Single; AVector, Axis: TVector3D): TVector3D;

implementation

uses
  math;

operator + (A, B: TVector2D): TVector2D;
begin
  Result.X := A.X + B.X;
  Result.Y := A.Y + B.Y;
end;

operator + (A, B: TVector3D): TVector3D;
begin
  Result.X := A.X + B.X;
  Result.Y := A.Y + B.Y;
  Result.Z := A.Z + B.Z;
end;

operator + (A, B: TVector4D): TVector4D;
begin
  Result.X := A.X + B.X;
  Result.Y := A.Y + B.Y;
  Result.Z := A.Z + B.Z;
  Result.W := A.W + B.W;
end;

operator - (A, B: TVector2D): TVector2D;
begin
  Result.X := A.X - B.X;
  Result.Y := A.Y - B.Y;
end;

operator - (A, B: TVector3D): TVector3D;
begin
  Result.X := A.X - B.X;
  Result.Y := A.Y - B.Y;
  Result.Z := A.Z - B.Z;
end;

operator - (A, B: TVector4D): TVector4D;
begin
  Result.X := A.X - B.X;
  Result.Y := A.Y - B.Y;
  Result.Z := A.Z - B.Z;
  Result.W := A.W - B.W;
end;


operator * (A, B: TVector2D): TVector2D;
begin
  Result.X := A.X * B.X;
  Result.Y := A.Y * B.Y;
end;

operator * (A, B: TVector3D): TVector3D;
begin
  Result.X := A.X * B.X;
  Result.Y := A.Y * B.Y;
  Result.Z := A.Z * B.Z;
end;

operator * (A, B: TVector4D): TVector4D;
begin
  Result.X := A.X * B.X;
  Result.Y := A.Y * B.Y;
  Result.Z := A.Z * B.Z;
  Result.W := A.W * B.W;
end;


operator / (A, B: TVector2D): TVector2D;
begin
  Result.X := A.X / B.X;
  Result.Y := A.Y / B.Y;
end;

operator / (A, B: TVector3D): TVector3D;
begin
  Result.X := A.X / B.X;
  Result.Y := A.Y / B.Y;
  Result.Z := A.Z / B.Z;
end;

operator / (A, B: TVector4D): TVector4D;
begin
  Result.X := A.X / B.X;
  Result.Y := A.Y / B.Y;
  Result.Z := A.Z / B.Z;
  Result.W := A.W / B.W;
end;


operator = (A, B: TVector2D): Boolean;
begin
  Result := (A.X = B.X) and (A.Y = B.Y);
end;

operator = (A, B: TVector3D): Boolean;
begin
  Result := (A.X = B.X) and (A.Y = B.Y) and (A.Z = B.Z);
end;

operator = (A, B: TVector4D): Boolean;
begin
  Result := (A.X = B.X) and (A.Y = B.Y) and (A.Z = B.Z) and (A.W = B.W);
end;




operator + (A: TVector2D; B: Single): TVector2D;
begin
  Result.X := A.X + B;
  Result.Y := A.Y + B;
end;

operator + (A: TVector3D; B: Single): TVector3D;
begin
  Result.X := A.X + B;
  Result.Y := A.Y + B;
  Result.Z := A.Z + B;
end;

operator + (A: TVector4D; B: Single): TVector4D;
begin
  Result.X := A.X + B;
  Result.Y := A.Y + B;
  Result.Z := A.Z + B;
  Result.W := A.W + B;
end;


operator - (A: TVector2D; B: Single): TVector2D;
begin
  Result.X := A.X - B;
  Result.Y := A.Y - B;
end;

operator - (A: TVector3D; B: Single): TVector3D;
begin
  Result.X := A.X - B;
  Result.Y := A.Y - B;
  Result.Z := A.Z - B;
end;

operator - (A: TVector4D; B: Single): TVector4D;
begin
  Result.X := A.X - B;
  Result.Y := A.Y - B;
  Result.Z := A.Z - B;
  Result.W := A.W - B;
end;


operator * (A: TVector2D; B: Single): TVector2D;
begin
  Result.X := A.X * B;
  Result.Y := A.Y * B;
end;

operator * (A: TVector3D; B: Single): TVector3D;
begin
  Result.X := A.X * B;
  Result.Y := A.Y * B;
  Result.Z := A.Z * B;
end;

operator * (A: TVector4D; B: Single): TVector4D;
begin
  Result.X := A.X * B;
  Result.Y := A.Y * B;
  Result.Z := A.Z * B;
  Result.W := A.W * B;
end;


operator * (A: TVector2D; B: TMatrix): TVector2D;
var
  Tmp: TVector4D;
begin
  Tmp := Vector(A.X, A.Y, 0, 1) * B;
  Result := Vector(Tmp.X, Tmp.Y);
end;

operator * (A: TVector3D; B: TMatrix): TVector3D;
var
  Tmp: TVector4D;
begin
  Tmp := Vector(A.X, A.Y, A.Z, 1) * B;
  Result := Vector(Tmp.X, Tmp.Y, Tmp.Z);
end;

operator * (A: TVector4D; B: TMatrix): TVector4D;
begin
  Result := Vector(A.X * B[0] + A.Y * B[4] + A.Z * B[8]  + A.W * B[12],
                   A.X * B[1] + A.Y * B[5] + A.Z * B[9]  + A.W * B[13],
                   A.X * B[2] + A.Y * B[6] + A.Z * B[10] + A.W * B[14],
                   A.X * B[3] + A.Y * B[7] + A.Z * B[10] + A.W * B[15]);
end;


operator / (A: TVector2D; B: Single): TVector2D;
begin
  Result.X := A.X / B;
  Result.Y := A.Y / B;
end;

operator / (A: TVector3D; B: Single): TVector3D;
begin
  Result.X := A.X / B;
  Result.Y := A.Y / B;
  Result.Z := A.Z / B;
end;

operator / (A: TVector4D; B: Single): TVector4D;
begin
  Result.X := A.X / B;
  Result.Y := A.Y / B;
  Result.Z := A.Z / B;
  Result.W := A.W / B;
end;



function VecRound(A: TVector2D): TVector2D;
begin
  Result := Vector(Round(A.X), Round(A.Y));
end;

function VecRound(A: TVector3D): TVector3D;
begin
  Result := Vector(Round(A.X), Round(A.Y), Round(A.Z));
end;

function VecRound(A: TVector4D): TVector4D;
begin
  Result := Vector(Round(A.X), Round(A.Y), ROund(A.Z), Round(A.W));
end;



function Vector(X, Y: Single): TVector2D;
begin
  Result.X := X;
  Result.Y := Y;
end;

function Vector(X, Y, Z: Single): TVector3D;
begin
  Result.X := X;
  Result.Y := Y;
  Result.Z := Z;
end;

function Vector(X, Y, Z, W: Single): TVector4D;
begin
  Result.X := X;
  Result.Y := Y;
  Result.Z := Z;
  Result.W := W;
end;


function VecLength(A: TVector2D): Single;
begin
  Result := SQRT(VecLengthNoRoot(A));
end;

function VecLength(A: TVector3D): Single;
begin
  Result := SQRT(VecLengthNoRoot(A));
end;

function VecLength(A: TVector4D): Single;
begin
  Result := SQRT(VecLengthNoRoot(A));
end;


function Cross(VectorA, VectorB: TVector3D): TVector3D;
begin
  Result.X := VectorA.Y * VectorB.Z - VectorA.Z * VectorB.Y;
  Result.Y := VectorA.Z * VectorB.X - VectorA.X * VectorB.Z;
  Result.Z := VectorA.X * VectorB.Y - VectorA.Y * VectorB.X;
end;

function Normal(VectorA, VectorB: TVector3D): TVector3D;
begin
  Result := Normalize(Cross(VectorA, VectorB));
end;

function DotProduct(VectorA, VectorB: TVector3D): Single;
begin
  Result := VectorA.x * VectorB.x + VectorA.y * VectorB.y + VectorA.z * VectorB.z;
end;


function Normalize(A: TVector2D): TVector2D;
begin
  if VecLength(A) = 0 then exit(A);
  Result := A / VecLength(A);
end;

function Normalize(A: TVector3D): TVector3D;
begin
  if VecLength(A) = 0 then exit(A);
  Result := A / VecLength(A);
end;

function Normalize(A: TVector4D): TVector4D;
begin
  if VecLength(A) = 0 then exit(A);
  Result := A / VecLength(A);
end;


function VecLengthNoRoot(A: TVector2D): Single;
begin
  Result := A.X * A.X + A.Y * A.Y;
end;

function VecLengthNoRoot(A: TVector3D): Single;
begin
  Result := A.X * A.X + A.Y * A.Y + A.Z * A.Z;
end;

function VecLengthNoRoot(A: TVector4D): Single;
begin
  Result := A.X * A.X + A.Y * A.Y + A.Z * A.Z + A.W * A.W;
end;

function Vec4toVec3(A: TVector4D): TVector3D;
begin
  Result := Vector(A.X, A.Y, A.Z) * A.W;
end;

function Vec3toVec2(A: TVector3D): TVector2D;
begin
  Result := Vector(A.X, A.Y) / A.Z;
end;


function Matrix3D(A, B, C: TVector3D): TMatrix3D;
begin
  Result[0] := A;
  Result[1] := B;
  Result[2] := C;
end;

function Matrix4D(A, B, C, D: TVector4D): TMatrix4D;
begin
  Result[0] := A;
  Result[1] := B;
  Result[2] := C;
  Result[3] := D;
end;


operator * (A: TVector3D; B: TMatrix3D): TVector3D;
begin
  Result.X := B[0].X * A.X + B[0].Y * A.Y + B[0].Z * A.Z;
  Result.Y := B[1].X * A.X + B[1].Y * A.Y + B[1].Z * A.Z;
  Result.Z := B[2].X * A.X + B[2].Y * A.Y + B[2].Z * A.Z;
end;

operator * (A: TVector4D; B: TMatrix4D): TVector4D;
begin
  Result.X := B[0].X * A.X + B[0].Y * A.Y + B[0].Z * A.Z + B[0].W * A.W;
  Result.Y := B[1].X * A.X + B[1].Y * A.Y + B[1].Z * A.Z + B[1].W * A.W;
  Result.Z := B[2].X * A.X + B[2].Y * A.Y + B[2].Z * A.Z + B[2].W * A.W;
  Result.W := B[3].X * A.X + B[3].Y * A.Y + B[3].Z * A.Z + B[3].W * A.W;
end;


function Rotate(Deg: Single; AVector, Axis: TVector3D): TVector3D;
var
  c, s: Single;
begin
  Axis := Normalize(Axis);
  C := Cos(DegToRad(Deg));
  S := Sin(DegToRad(Deg));
  Result := AVector * Matrix3D(Vector(Axis.X * Axis.X * (1 - C) + C, Axis.X * Axis.Y * (1 - C) - Axis.Z * s, Axis.X * Axis.Z * (1 - C) + Axis.Y * s),
                               Vector(Axis.Y * Axis.X * (1 - C) + Axis.Z * S, Axis.Y * Axis.Y * (1 - C) + C, Axis.Y * Axis.Z * (1 - C) - Axis.X * s),
                               Vector(Axis.X * Axis.Z * (1 - C) - Axis.Y * S, Axis.Y * Axis.Z * (1 - C) + Axis.X * s, Axis.Z * Axis.Z * (1 - C) + C));
end;

end.