unit u_math;

interface

uses
  SysUtils, Classes, Math, u_vectors;

function Mix(A, B, C: Single): Single; inline;
function Mix(A, B: TVector2D; C: Single): TVector2D; inline;
function Mix(A, B: TVector3D; C: Single): TVector3D; inline;
function Mix(A, B: TVector4D; C: Single): TVector4D; inline;

function Ceil(A: Single): Integer; inline;
function Ceil(A: TVector2D): TVector2D; inline;
function Ceil(A: TVector3D): TVector3D; inline;
function Ceil(A: TVector4D): TVector4D; inline;

function Floor(A: Single): Integer; inline;
function Floor(A: TVector2D): TVector2D; inline;
function Floor(A: TVector3D): TVector3D; inline;
function Floor(A: TVector4D): TVector4D; inline;

function FPart(A: Single): Single; inline;
function FPart(A: TVector2D): TVector2D; inline;
function FPart(A: TVector3D): TVector3D; inline;
function FPart(A: TVector4D): TVector4D; inline;

function Clamp(A, Min, Max: Single): Single;

implementation

function Mix(A, B, C: Single): Single;
begin
  Result := C * B + (1 - C) * A;
end;

function Mix(A, B: TVector2D; C: Single): TVector2D;
begin
  Result.X := C * B.X + (1 - C) * A.X;
  Result.Y := C * B.Y + (1 - C) * A.Y;
end;

function Mix(A, B: TVector3D; C: Single): TVector3D;
begin
  Result.X := C * B.X + (1 - C) * A.X;
  Result.Y := C * B.Y + (1 - C) * A.Y;
  Result.Z := C * B.Z + (1 - C) * A.Z;
end;

function Mix(A, B: TVector4D; C: Single): TVector4D;
begin
  Result.X := C * B.X + (1 - C) * A.X;
  Result.Y := C * B.Y + (1 - C) * A.Y;
  Result.Z := C * B.Z + (1 - C) * A.Z;
  Result.W := C * B.W + (1 - C) * A.W;
end;


function Ceil(A: Single): Integer;
begin
  Result := Floor(A);
  if FPart(A) <> 0 then
    Inc(Result);
end;

function Ceil(A: TVector2D): TVector2D;
begin
  Result := Floor(A);
  if FPart(A.X) <> 0 then
    Result.X := Result.X + 1;
  if FPart(A.Y) <> 0 then
    Result.Y := Result.Y + 1;
end;

function Ceil(A: TVector3D): TVector3D;
begin
  Result := Floor(A);
  if FPart(A.X) <> 0 then
    Result.X := Result.X + 1;
  if FPart(A.Y) <> 0 then
    Result.Y := Result.Y + 1;
  if FPart(A.Z) <> 0 then
    Result.Z := Result.Z + 1;
end;

function Ceil(A: TVector4D): TVector4D;
begin
  Result := Floor(A);
  if FPart(A.X) <> 0 then
    Result.X := Result.X + 1;
  if FPart(A.Y) <> 0 then
    Result.Y := Result.Y + 1;
  if FPart(A.Z) <> 0 then
    Result.Z := Result.Z + 1;
  if FPart(A.W) <> 0 then
    Result.W := Result.W + 1;
end;


function Floor(A: Single): Integer;
begin
  Result := Round(A - FPart(A));
end;

function Floor(A: TVector2D): TVector2D;
begin
  Result := A - FPart(A);
end;

function Floor(A: TVector3D): TVector3D;
begin
  Result := A - FPart(A);
end;

function Floor(A: TVector4D): TVector4D;
begin
  Result := A - FPart(A);
end;


function FPart(A: Single): Single;
begin
  Result := A - Int(A);
end;

function FPart(A: TVector2D): TVector2D;
begin
  Result.X := A.X - Int(A.X);
  Result.Y := A.Y - Int(A.Y);
end;

function FPart(A: TVector3D): TVector3D;
begin
  Result.X := A.X - Int(A.X);
  Result.Y := A.Y - Int(A.Y);
  Result.Z := A.Z - Int(A.Z);
end;

function FPart(A: TVector4D): TVector4D;
begin
  Result.X := A.X - Int(A.X);
  Result.Y := A.Y - Int(A.Y);
  Result.Z := A.Z - Int(A.Z);
  Result.W := A.W - Int(A.W);
end;


function Clamp(A, Min, Max: Single): Single;
begin
  if A < Min then
    exit(Min)
  else if A > Max then
    exit(Max);
  Result := A;
end;

end.