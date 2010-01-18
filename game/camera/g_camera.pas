unit g_camera;

interface

uses
  SysUtils, Classes, u_math, u_vectors, l_ocf, g_park_types;

type
  TCamera = class(TParkChild)
    public
      CamType: Byte;
      Position: TVector3D;
      Rotation: TVector3D;
      procedure LookAt(Dest: TVector3D);
      procedure WriteOCFSection(var Section: TOCFSection);
      procedure ReadFromOCFSection(Section: TOCFSection);
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

procedure TCamera.WriteOCFSection(var Section: TOCFSection);
begin
  Section.SectionType := 'Camera';
  Section.Data.CopyFromByteArray(@CamType, SizeOf(Byte));
  Section.Data.AppendByteArray(@Position, SizeOf(TVector3D));
  Section.Data.AppendByteArray(@Rotation, SizeOf(TVector3D));
end;

procedure TCamera.ReadFromOCFSection(Section: TOCFSection);
begin
  Section.Data.ReadBytes(@CamType, SizeOf(Byte));
  Section.Data.ReadBytes(@Position, SizeOf(TVector3D));
  Section.Data.ReadBytes(@Rotation, SizeOf(TVector3D));
  fLoaded := true;
end;

procedure TCamera.LoadDefaults;
begin
  if fLoaded then exit;
  CamType := CAM_MOVABLE;
  Position := Vector(0, 1, 0);
  Rotation := Vector(0, 0, 0);
  fLoaded := true;
end;

end.