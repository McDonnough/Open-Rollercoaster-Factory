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

  TMatrix = Array[0..15] of Single;

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
  VectorA := Normalize(VectorA);
  VectorB := Normalize(VectorB);
  Result := VectorA.x * VectorB.x + VectorA.y * VectorB.y + VectorA.z * VectorB.z;
end;


function Normalize(A: TVector2D): TVector2D;
begin
  Result := A / VecLength(A);
end;

function Normalize(A: TVector3D): TVector3D;
begin
  Result := A / VecLength(A);
end;

function Normalize(A: TVector4D): TVector4D;
begin
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


end.