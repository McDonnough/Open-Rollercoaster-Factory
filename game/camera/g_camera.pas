unit g_camera;

interface

uses
  SysUtils, Classes, u_math, u_vectors;

type
  TCamera = class
    protected
      fRotation, fPosition: TVector3D;
      fMatrix: TMatrix4D;
      procedure UpdateMatrix;
      procedure SetPosition(A: TVector3D);
      procedure SetRotation(A: TVector3D);
    public
      CamType: Byte;
      property Rotation: TVector3D read fRotation write SetRotation;
      property Position: TVector3D read fPosition write SetPosition;
      property Matrix: TMatrix4D read fMatrix;
      procedure LookAt(Dest: TVector3D);
      procedure LoadDefaults;
    end;

const
  CAM_MOVABLE = 0;
  CAM_STATIC = 1;
  CAM_DYNAMIC = 2;

implementation

uses
  math, main;

procedure TCamera.UpdateMatrix;
begin
  fMatrix := Identity4D;
//   fMatrix :=           RotationMatrix(Rotation.Z, Vector(0, 0, 1));
//   fMatrix := fMatrix * RotationMatrix(Rotation.X, Vector(1, 0, 0));
  fMatrix := fMatrix * RotationMatrix(Rotation.Y, Vector(0, -1, 0));
end;

procedure TCamera.SetPosition(A: TVector3D);
begin
  fPosition := A;
  UpdateMatrix;
end;

procedure TCamera.SetRotation(A: TVector3D);
begin
  fRotation := A;
  UpdateMatrix;
end;

procedure TCamera.LookAt(Dest: TVector3D);
var
  Diff: TVector3D;
begin
  Diff := Normalize(Dest - Position);
  fRotation.X := ArcCos(Dest.Y);
  fRotation.Y := ArcCos(DotProduct(Vector(0, 0, -1), Normalize(Diff * Vector(1, 0, 1))));
  UpdateMatrix;
end;

procedure TCamera.LoadDefaults;
begin
  CamType := CAM_MOVABLE;
  Position := Vector(100, 200, 100);
  Rotation := Vector(60, 135, 0);
end;

end.