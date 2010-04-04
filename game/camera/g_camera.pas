unit g_camera;

interface

uses
  SysUtils, Classes, u_math, u_vectors;

type
  TCamera = class
    public
      CamType: Byte;
      Position: TVector3D;
      Rotation: TVector3D;
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

procedure TCamera.LookAt(Dest: TVector3D);
var
  Diff: TVector3D;
begin
  Diff := Normalize(Dest - Position);
  Rotation.X := ArcCos(Dest.Y);
  Rotation.Y := ArcCos(DotProduct(Vector(0, 0, -1), Normalize(Diff * Vector(1, 0, 1))));
end;

procedure TCamera.LoadDefaults;
begin
  CamType := CAM_MOVABLE;
  Position := Vector(0, 30, 0);
  Rotation := Vector(0, 135, 0);
end;

end.