unit u_selection;

interface

uses
  SysUtils, Classes, u_geometry, u_vectors, u_math;

type
  TSelectableObject = record
    Mesh: TMesh;
    Selected: Boolean;
    IntersectionPoint: TVector3D;
    Event: String;
    end;

  TSelectionEngine = class
    protected
      fSelectableObjects: Array of TSelectableObject;
    public
      procedure Add(Mesh: TMesh; Event: String = '');
      procedure Delete(Mesh: TMesh);
      function IsSelected(Mesh: TMesh): Boolean;
      procedure Update;
    end;

implementation

uses
  m_varlist, u_events;

procedure TSelectionEngine.Add(Mesh: TMesh; Event: String = '');
begin
  setLength(fSelectableObjects, length(fSelectableObjects) + 1);
  fSelectableObjects[high(fSelectableObjects)].Mesh := Mesh;
  fSelectableObjects[high(fSelectableObjects)].Selected := false;
  fSelectableObjects[high(fSelectableObjects)].IntersectionPoint := Vector(0, 0, 0);
  fSelectableObjects[high(fSelectableObjects)].Event := Event;
end;

procedure TSelectionEngine.Delete(Mesh: TMesh);
var
  i: Integer;
begin
  for i := 0 to high(fSelectableObjects) do
    if fSelectableObjects[i].Mesh = Mesh then
      begin
      fSelectableObjects[i] := fSelectableObjects[high(fSelectableObjects)];
      setLength(fSelectableObjects, length(fSelectableObjects) - 1);
      end;
end;

function TSelectionEngine.IsSelected(Mesh: TMesh): Boolean;
var
  i: Integer;
begin
  Result := false;
  for i := 0 to high(fSelectableObjects) do
    if fSelectableObjects[i].Mesh = Mesh then
      exit(fSelectableObjects[i].Selected);
end;

procedure TSelectionEngine.Update;
var
  i, j: Integer;
  MinDist: Single;
begin
  MinDist := 2000 * 2000;
  for i := 0 to high(fSelectableObjects) do
    begin
    fSelectableObjects[i].Selected := false;
    for j := 0 to fSelectableObjects[i].Mesh.TriangleCount do
      if RayTriangleIntersection(MakeRay(ModuleManager.ModRenderer.SelectionStart, ModuleManager.ModRenderer.SelectionRay), MakeTriangleFromMeshTriangleVertexArray(fSelectableObjects[i].Mesh, fSelectableObjects[i].Mesh.Triangles[j]), fSelectableObjects[i].IntersectionPoint) then
        if MinDist > VecLengthNoRoot(fSelectableObjects[i].IntersectionPoint - ModuleManager.ModRenderer.SelectionStart) then
          begin
          MinDist := VecLengthNoRoot(fSelectableObjects[i].IntersectionPoint - ModuleManager.ModRenderer.SelectionStart);
          fSelectableObjects[i].Selected := true;
          break;
          end;
    end;
  for i := 0 to high(fSelectableObjects) do
    if VecLengthNoRoot(fSelectableObjects[i].IntersectionPoint - ModuleManager.ModRenderer.SelectionStart) > MinDist then
      fSelectableObjects[i].Selected := false
    else if (fSelectableObjects[i].Selected) and (fSelectableObjects[i].Event <> '') then
      EventManager.CallEvent(fSelectableObjects[i].Event, fSelectableObjects[i].Mesh, nil);
end;

end.