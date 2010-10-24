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

  TSphere = record
    Position: TVector3D;
    Radius: Single;
    end;

  PVector2D = ^TVector2D;
  PVector3D = ^TVector3D;
  PVector4D = ^TVector4D;

  TMatrix = Array[0..15] of Single;

  TMatrix3D = Array[0..2] of TVector3D;
  TMatrix4D = Array[0..3] of TVector4D;

  TQuad = Array[0..3] of TVector2D;

function Quad(A, B, C, D: TVector2D): TQuad;

function Vector(X, Y: Single): TVector2D;
function Vector(X, Y, Z: Single): TVector3D;
function Vector(X, Y, Z, W: Single): TVector4D;

function Vector(XY: TVector2D; Z: Single): TVector3D;
function Vector(XY: TVector2D; Z, W: Single): TVector4D;
function Vector(X: Single; YZ: TVector2D): TVector3D;
function Vector(X: Single; YZ: TVector2D; W: Single): TVector4D;
function Vector(X, Y: Single; ZW: TVector2D): TVector4D;
function Vector(XY, ZW: TVector2D): TVector4D;
function Vector(XYZ: TVector3D; W: Single): TVector4D;
function Vector(X: Single; YZW: TVector3D): TVector4D;

function MixVec(A, B: TVector2D; F: Single): TVector2D;
function MixVec(A, B: TVector3D; F: Single): TVector3D;
function MixVec(A, B: TVector4D; F: Single): TVector4D;

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
function Matrix4D(A: TMatrix3D): TMatrix4D;


operator * (A: TVector3D; B: TMatrix3D): TVector3D;
operator * (A: TVector4D; B: TMatrix4D): TVector4D;
operator * (A, B: TMatrix3D): TMatrix3D;
operator * (A, B: TMatrix4D): TMatrix4D;

function Rotate(Deg: Single; AVector, Axis: TVector3D): TVector3D;
function RotationMatrix(Deg: Single; Axis: TVector3D): TMatrix4D;


function TranslationMatrix(P: TVector3D): TMatrix4D;


function Identity3D: TMatrix3D;
function Identity4D: TMatrix4D;

function Vector2D(A: TVector3D): TVector2D;
function Vector2D(A: TVector4D): TVector2D;
function Vector3D(A: TVector4D): TVector3D;

procedure MakeOGLCompatibleMatrix(A: TMatrix3D; B: Pointer);
procedure MakeOGLCompatibleMatrix(A: TMatrix4D; B: Pointer);

function LineIntersection(p1, p2, p3, p4: TVector2D): TVector2D;

function PointInQuad(Q: TQuad; P: TVector2D): Boolean;


function Sphere(Pos: TVector3D; Rad: Single): TSphere;

function SphereSphereIntersection(A, B: TSphere): Boolean;

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



function MixVec(A, B: TVector2D; F: Single): TVector2D;
begin
  Result := B * F + A * (1 - F);
end;

function MixVec(A, B: TVector3D; F: Single): TVector3D;
begin
  Result := B * F + A * (1 - F);
end;

function MixVec(A, B: TVector4D; F: Single): TVector4D;
begin
  Result := B * F + A * (1 - F);
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

function Vector(XY: TVector2D; Z: Single): TVector3D;
begin
  Result := Vector(XY.X, XY.Y, Z);
end;

function Vector(XY: TVector2D; Z, W: Single): TVector4D;
begin
  Result := Vector(XY.X, XY.Y, Z, W);
end;

function Vector(X: Single; YZ: TVector2D): TVector3D;
begin
  Result := Vector(X, YZ.X, YZ.Y);
end;

function Vector(X: Single; YZ: TVector2D; W: Single): TVector4D;
begin
  Result := Vector(X, YZ.X, YZ.Y, W);
end;

function Vector(X, Y: Single; ZW: TVector2D): TVector4D;
begin
  Result := Vector(X, Y, ZW.X, ZW.Y);
end;

function Vector(XY, ZW: TVector2D): TVector4D;
begin
  Result := Vector(XY.X, XY.Y, ZW.X, ZW.Y);
end;

function Vector(XYZ: TVector3D; W: Single): TVector4D;
begin
  Result := Vector(XYZ.X, XYZ.Y, XYZ.Z, W);
end;

function Vector(X: Single; YZW: TVector3D): TVector4D;
begin
  Result := Vector(X, YZW.X, YZW.Y, YZW.Z);
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

operator * (A, B: TMatrix3D): TMatrix3D;
begin
  Result[0] := Vector(A[0].X * B[0].X + A[0].Y * B[1].X + A[0].Z * B[2].X, A[0].X * B[0].Y + A[0].Y * B[1].Y + A[0].Z * B[2].Y, A[0].X * B[0].Z + A[0].Y * B[1].Z + A[0].Z * B[2].Z);
  Result[1] := Vector(A[1].X * B[0].X + A[1].Y * B[1].X + A[1].Z * B[2].X, A[1].X * B[0].Y + A[1].Y * B[1].Y + A[1].Z * B[2].Y, A[1].X * B[0].Z + A[1].Y * B[1].Z + A[1].Z * B[2].Z);
  Result[2] := Vector(A[2].X * B[0].X + A[2].Y * B[1].X + A[2].Z * B[2].X, A[2].X * B[0].Y + A[2].Y * B[1].Y + A[2].Z * B[2].Y, A[2].X * B[0].Z + A[2].Y * B[1].Z + A[2].Z * B[2].Z);
end;

operator * (A, B: TMatrix4D): TMatrix4D;
begin
  Result[0] := Vector(A[0].X * B[0].X + A[0].Y * B[1].X + A[0].Z * B[2].X + A[0].W * B[3].X, A[0].X * B[0].Y + A[0].Y * B[1].Y + A[0].Z * B[2].Y + A[0].W * B[3].Y, A[0].X * B[0].Z + A[0].Y * B[1].Z + A[0].Z * B[2].Z + A[0].W * B[3].Z, A[0].X * B[0].W + A[0].Y * B[1].W + A[0].Z * B[2].W + A[0].W * B[3].W);
  Result[1] := Vector(A[1].X * B[0].X + A[1].Y * B[1].X + A[1].Z * B[2].X + A[1].W * B[3].X, A[1].X * B[0].Y + A[1].Y * B[1].Y + A[1].Z * B[2].Y + A[1].W * B[3].Y, A[1].X * B[0].Z + A[1].Y * B[1].Z + A[1].Z * B[2].Z + A[1].W * B[3].Z, A[1].X * B[0].W + A[1].Y * B[1].W + A[1].Z * B[2].W + A[1].W * B[3].W);
  Result[2] := Vector(A[2].X * B[0].X + A[2].Y * B[1].X + A[2].Z * B[2].X + A[2].W * B[3].X, A[2].X * B[0].Y + A[2].Y * B[1].Y + A[2].Z * B[2].Y + A[2].W * B[3].Y, A[2].X * B[0].Z + A[2].Y * B[1].Z + A[2].Z * B[2].Z + A[2].W * B[3].Z, A[2].X * B[0].W + A[2].Y * B[1].W + A[2].Z * B[2].W + A[2].W * B[3].W);
  Result[3] := Vector(A[3].X * B[0].X + A[3].Y * B[1].X + A[3].Z * B[2].X + A[3].W * B[3].X, A[3].X * B[0].Y + A[3].Y * B[1].Y + A[3].Z * B[2].Y + A[3].W * B[3].Y, A[3].X * B[0].Z + A[3].Y * B[1].Z + A[3].Z * B[2].Z + A[3].W * B[3].Z, A[3].X * B[0].W + A[3].Y * B[1].W + A[3].Z * B[2].W + A[3].W * B[3].W);
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

function RotationMatrix(Deg: Single; Axis: TVector3D): TMatrix4D;
var
  c, s: Single;
begin
  Axis := Normalize(Axis);
  C := Cos(DegToRad(Deg));
  S := Sin(DegToRad(Deg));
  Result := Matrix4D(Vector(Axis.X * Axis.X * (1 - C) + C, Axis.X * Axis.Y * (1 - C) - Axis.Z * s, Axis.X * Axis.Z * (1 - C) + Axis.Y * s, 0),
                     Vector(Axis.Y * Axis.X * (1 - C) + Axis.Z * S, Axis.Y * Axis.Y * (1 - C) + C, Axis.Y * Axis.Z * (1 - C) - Axis.X * s, 0),
                     Vector(Axis.X * Axis.Z * (1 - C) - Axis.Y * S, Axis.Y * Axis.Z * (1 - C) + Axis.X * s, Axis.Z * Axis.Z * (1 - C) + C, 0),
                     Vector(0,                                      0,                                      0,                             1));
end;

function Identity3D: TMatrix3D;
begin
  Result[0] := Vector(1, 0, 0);
  Result[1] := Vector(0, 1, 0);
  Result[2] := Vector(0, 0, 1);
end;

function Identity4D: TMatrix4D;
begin
  Result[0] := Vector(1, 0, 0, 0);
  Result[1] := Vector(0, 1, 0, 0);
  Result[2] := Vector(0, 0, 1, 0);
  Result[3] := Vector(0, 0, 0, 1);
end;

function Vector2D(A: TVector3D): TVector2D;
begin
  Result := Vector(A.X, A.Y);
end;

function Vector2D(A: TVector4D): TVector2D;
begin
  Result := Vector(A.X, A.Y);
end;

function Vector3D(A: TVector4D): TVector3D;
begin
  Result := Vector(A.X, A.Y, A.Z);
end;

procedure MakeOGLCompatibleMatrix(A: TMatrix3D; B: Pointer);
begin
  Single(B^) := A[0].X; Inc(B, SizeOf(Single));
  Single(B^) := A[1].X; Inc(B, SizeOf(Single));
  Single(B^) := A[2].X; Inc(B, SizeOf(Single));
  Single(B^) := A[0].Y; Inc(B, SizeOf(Single));
  Single(B^) := A[1].Y; Inc(B, SizeOf(Single));
  Single(B^) := A[2].Y; Inc(B, SizeOf(Single));
  Single(B^) := A[0].Z; Inc(B, SizeOf(Single));
  Single(B^) := A[1].Z; Inc(B, SizeOf(Single));
  Single(B^) := A[2].Z; Inc(B, SizeOf(Single));
end;

procedure MakeOGLCompatibleMatrix(A: TMatrix4D; B: Pointer);
begin
  Single(B^) := A[0].X; Inc(B, SizeOf(Single));
  Single(B^) := A[1].X; Inc(B, SizeOf(Single));
  Single(B^) := A[2].X; Inc(B, SizeOf(Single));
  Single(B^) := A[3].X; Inc(B, SizeOf(Single));
  Single(B^) := A[0].Y; Inc(B, SizeOf(Single));
  Single(B^) := A[1].Y; Inc(B, SizeOf(Single));
  Single(B^) := A[2].Y; Inc(B, SizeOf(Single));
  Single(B^) := A[3].Y; Inc(B, SizeOf(Single));
  Single(B^) := A[0].Z; Inc(B, SizeOf(Single));
  Single(B^) := A[1].Z; Inc(B, SizeOf(Single));
  Single(B^) := A[2].Z; Inc(B, SizeOf(Single));
  Single(B^) := A[3].Z; Inc(B, SizeOf(Single));
  Single(B^) := A[0].W; Inc(B, SizeOf(Single));
  Single(B^) := A[1].W; Inc(B, SizeOf(Single));
  Single(B^) := A[2].W; Inc(B, SizeOf(Single));
  Single(B^) := A[3].W; Inc(B, SizeOf(Single));
end;

function Matrix4D(A: TMatrix3D): TMatrix4D;
begin
  Result[0] := Vector(A[0], 0);
  Result[1] := Vector(A[1], 0);
  Result[2] := Vector(A[2], 0);
  Result[3] := Vector(0, 0, 0, 1);
end;

function TranslationMatrix(P: TVector3D): TMatrix4D;
begin
  Result := Identity4D;
  Result[0].W := P.X;
  Result[1].W := P.Y;
  Result[2].W := P.Z;
end;

function LineIntersection(p1, p2, p3, p4: TVector2D): TVector2D;
var
  divisor, fac1, fac2: Single;
begin
  divisor := (p1.x - p2.x) * (p3.y - p4.y) - (p1.y - p2.y) * (p3.x - p4.x);
  fac1 := p1.x * p2.y - p1.y * p2.x;
  fac2 := p3.x * p4.y - p3.y * p4.x;
  Result := Vector((fac1 * (p3.x - p4.x) - fac2 * (p1.x - p2.x)) / divisor,
                   (fac1 * (p3.y - p4.y) - fac2 * (p1.y - p2.y)) / divisor);
end;

function PointInQuad(Q: TQuad; P: TVector2D): Boolean;
var
  AD1, AB1, BC1, DC1: TVector2D;
  A: TVector3D;
begin
  Result := true;
  A := Cross(Vector(Q[0].X - Q[1].X, 0, Q[0].Y - Q[1].Y), Vector(0, 1, 0));
  AB1 := LineIntersection(Q[0], Q[1], P, P + Vector(A.X, A.Z));
  DC1 := LineIntersection(Q[3], Q[2], P, P + Vector(A.X, A.Z));
  if (VecLengthNoRoot(P - AB1) > VecLengthNoRoot(AB1 - DC1)) or (VecLengthNoRoot(P - DC1) > VecLengthNoRoot(AB1 - DC1)) then
    exit(false);
  AD1 := LineIntersection(Q[0], Q[3], P, P + Q[0] - Q[1]);
  BC1 := LineIntersection(Q[1], Q[2], P, P + Q[0] - Q[1]);
  if (VecLengthNoRoot(P - AD1) > VecLengthNoRoot(AD1 - BC1)) or (VecLengthNoRoot(P - BC1) > VecLengthNoRoot(AD1 - BC1)) then
    exit(false);
end;

function Quad(A, B, C, D: TVector2D): TQuad;
begin
  Result[0] := A;
  Result[1] := B;
  Result[2] := C;
  Result[3] := D;
end;

function Sphere(Pos: TVector3D; Rad: Single): TSphere;
begin
  Result.Position := Pos;
  Result.Radius := Rad;
end;

function SphereSphereIntersection(A, B: TSphere): Boolean;
begin
  Result := VecLengthNoRoot(A.Position - B.Position) < (A.Radius + B.Radius) * (A.Radius + B.Radius);
end;

end.