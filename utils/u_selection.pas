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

  PSelectableObject = ^TSelectableObject;

  TSelectionEngine = class(TThread)
    protected
      MinDist: Single;
      fCanWork: Boolean;
      fWorking: Boolean;
      fSelectableObjects: Array of TSelectableObject;
      procedure Execute; override;
      procedure Sync;
    public
      function ObjectCount: Integer;
      function Add(Mesh: TMesh; Event: String = ''): PSelectableObject;
      procedure Delete(Mesh: TMesh);
      function IsSelected(Mesh: TMesh): Boolean;
      procedure Update;
      constructor Create;
    end;

implementation

uses
  m_varlist, u_events;

procedure TSelectionEngine.Execute;
var
  i, j: Integer;
  Sel: TVector3D;
begin
  while not Terminated do
    begin
    try
      if fCanWork then
        begin
        fWorking := true;
        MinDist := 2000 * 2000;
        for i := 0 to high(fSelectableObjects) do
          begin
          fSelectableObjects[i].Selected := false;
          for j := 0 to fSelectableObjects[i].Mesh.TriangleCount do
            if RayTriangleIntersection(MakeRay(ModuleManager.ModRenderer.SelectionStart, ModuleManager.ModRenderer.SelectionRay), MakeTriangleFromMeshTriangleVertexArray(fSelectableObjects[i].Mesh, fSelectableObjects[i].Mesh.Triangles[j]), fSelectableObjects[i].IntersectionPoint) then
              if MinDist > VecLengthNoRoot(fSelectableObjects[i].IntersectionPoint - ModuleManager.ModRenderer.SelectionStart) then
                begin
                Sel := fSelectableObjects[i].IntersectionPoint;
                MinDist := VecLengthNoRoot(fSelectableObjects[i].IntersectionPoint - ModuleManager.ModRenderer.SelectionStart);
                fSelectableObjects[i].Selected := true;
                end;
          if fSelectableObjects[i].Selected then
            fSelectableObjects[i].IntersectionPoint := Sel;
          end;
        fCanWork := false;
        end
      else
        sleep(1);
      fWorking := false;
    except
      ModuleManager.ModLog.AddError('Exception in selection engine thread');
    end;
    end;
  writeln('Hint: Terminated search engine thread');
end;

procedure TSelectionEngine.Sync;
begin
  while fWorking do
    sleep(1);
end;

function TSelectionEngine.ObjectCount: Integer;
begin
  Result := Length(fSelectableObjects);
end;

function TSelectionEngine.Add(Mesh: TMesh; Event: String = ''): PSelectableObject;
begin
  Sync;
  setLength(fSelectableObjects, length(fSelectableObjects) + 1);
  Result := @fSelectableObjects[high(fSelectableObjects)];
  Result^.Mesh := Mesh;
  Result^.Selected := false;
  Result^.IntersectionPoint := Vector(0, 0, 0);
  Result^.Event := Event;
end;

procedure TSelectionEngine.Delete(Mesh: TMesh);
var
  i: Integer;
begin
  Sync;
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
  i: Integer;
begin
  Sync;
  for i := 0 to high(fSelectableObjects) do
    if VecLengthNoRoot(fSelectableObjects[i].IntersectionPoint - ModuleManager.ModRenderer.SelectionStart) > MinDist then
      fSelectableObjects[i].Selected := false
    else if (fSelectableObjects[i].Selected) and (fSelectableObjects[i].Event <> '') then
      EventManager.CallEvent(fSelectableObjects[i].Event, @fSelectableObjects[i], nil);
  fCanWork := True;
end;

constructor TSelectionEngine.Create;
begin
  inherited Create(false);
end;

end.