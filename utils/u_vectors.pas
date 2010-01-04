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

function Vector(X, Y: Integer): TVector2D;
function Vector(X, Y, Z: Integer): TVector3D;
function Vector(X, Y, Z, W: Integer): TVector4D;

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

operator / (A: TVector2D; B: Single): TVector2D;
operator / (A: TVector3D; B: Single): TVector3D;
operator / (A: TVector4D; B: Single): TVector4D;


function Length(A: TVector2D): Single;
function Length(A: TVector3D): Single;
function Length(A: TVector4D): Single;

function LengthNoRoot(A: TVector2D): Single;
function LengthNoRoot(A: TVector3D): Single;
function LengthNoRoot(A: TVector4D): Single;

function Normal(VectorA, VectorB: TVector3D): TVector3D;

function Normalize(A: TVector2D): TVector2D;
function Normalize(A: TVector3D): TVector3D;
function Normalize(A: TVector4D): TVector4D;

implementation

uses
  math;


function Length(A: TVector2D): Single;
begin
  Result := SQRT(LengthNoRoot(A));
end;

function Length(A: TVector3D): Single;
begin
  Result := SQRT(LengthNoRoot(A));
end;

function Length(A: TVector4D): Single;
begin
  Result := SQRT(LengthNoRoot(A));
end;


function Normal(VectorA, VectorB: TVector3D): TVector3D;
begin
  Result.X := VectorA.Y * VectorB.Z - VectorA.Z * VectorB.Y;
  Result.Y := VectorA.Z * VectorB.X - VectorA.X * VectorB.Z;
  Result.Z := VectorA.X * VectorB.Y - VectorA.Y * VectorB.X;

  Result := Normalize(Result);
end;

function Normalize(A: TVector2D): TVector2D;
begin
  Result := A / Length(A);
end;

function Normalize(A: TVector3D): TVector3D;
begin
  Result := A / Length(A);
end;

function Normalize(A: TVector4D): TVector4D;
begin
  Result := A / Length(A);
end;


function LengthNoRoot(A: TVector2D): Single;
begin
  Result := A.X * A.X + A.Y * A.Y;
end;

function LengthNoRoot(A: TVector3D): Single;
begin
  Result := A.X * A.X + A.Y * A.Y + A.Z * A.Z;
end;

function LengthNoRoot(A: TVector4D): Single;
begin
  Result := A.X * A.X + A.Y * A.Y + A.Z * A.Z + A.W * A.W;
end;


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



function Vector(X, Y: Integer): TVector2D;
begin
  Result.X := X;
  Result.Y := Y;
end;

function Vector(X, Y, Z: Integer): TVector3D;
begin
  Result.X := X;
  Result.Y := Y;
  Result.Z := Z;
end;

function Vector(X, Y, Z, W: Integer): TVector4D;
begin
  Result.X := X;
  Result.Y := Y;
  Result.Z := Z;
  Result.W := W;
end;

end.