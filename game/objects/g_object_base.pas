unit g_object_base;

interface

uses
  SysUtils, Classes, u_geometry, u_vectors, u_math, u_arrays, u_functions, m_texmng_class, g_loader_ocf;

type
  TBasicObject = class
    protected
//       fScript: TScript;
      fOffset: TVector3D;
      fRotation: TMatrix3D;
    public
      fMeshes: Array of TMesh;
//       property Script: TScript read fScript;
      property Position: TVector3D read fOffset;
      property Rotation: TMatrix3D read fRotation;
      function AddMesh(Mesh: TMesh): TMesh;
      function AddMesh: TMesh;
      procedure DeleteMesh(I: Integer);
      procedure ReadFromOCFFile(F: TOCFFile);
      procedure Rotate(Matrix: TMatrix3D);
      procedure Move(Offset: TVector3D);
      constructor Create;
      destructor Free;
    end;

implementation

uses
  m_varlist, u_events;

function TBasicObject.AddMesh(Mesh: TMesh): TMesh;
var
  i: Integer;
begin
  Result := Mesh;
  Result.Parent := Self;
  Result.StaticOffset := fOffset;
  Result.StaticRotationMatrix := fRotation;
  SetLength(fMeshes, length(fMeshes) + 1);
  i := high(fMeshes);
  fMeshes[i] := Result;
  EventManager.CallEvent('TBasicObject.AddedMesh', Self, @I);
end;

function TBasicObject.AddMesh: TMesh;
begin
  Result := AddMesh(TMesh.Create);
end;

procedure TBasicObject.DeleteMesh(I: Integer);
begin
  if (i >= 0) and (i <= high(fMeshes)) then
    begin
    EventManager.CallEvent('TBasicObject.DeletedMesh', Self, @I);
    fMeshes[i].Free;
    fMeshes[i] := fMeshes[high(fMeshes)];
    SetLength(fMeshes, length(fMeshes) - 1);
    end;
end;

procedure TBasicObject.ReadFromOCFFile(F: TOCFFile);
begin

end;

procedure TBasicObject.Rotate(Matrix: TMatrix3D);
var
  i: Integer;
begin
  fRotation := Matrix;
  for i := 0 to high(fMeshes) do
    fMeshes[i].StaticRotationMatrix := Matrix;
end;

procedure TBasicObject.Move(Offset: TVector3D);
var
  i: Integer;
begin
  fOffset := Offset;
  for i := 0 to high(fMeshes) do
    fMeshes[i].StaticOffset := Offset;
end;

constructor TBasicObject.Create;
begin
  fOffset := Vector(0, 0, 0);
  fRotation := Identity3D;
  EventManager.CallEvent('TBasicObject.Created', Self, nil);
end;

destructor TBasicObject.Free;
begin
  while length(fMeshes) > 0 do
    DeleteMesh(0);
  EventManager.CallEvent('TBasicObject.Deleted', Self, nil);
end;

end.