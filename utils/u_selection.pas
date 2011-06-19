unit u_selection;

interface

uses
  SysUtils, Classes, u_vectors, u_math, u_scene, u_geometry;

type
  TSelectableObject = record
    O: TGeoObject;
    Selected: Boolean;
    Event: String;
    end;

  PSelectableObject = ^TSelectableObject;

  TSelectionEngine = class
    protected
      MinDist: Single;
      fSelectionCoord: TVector3D;
    public
      fSelectableObjects: Array of TSelectableObject;
      RenderTerrain: Boolean;
      RenderObjects: Boolean;
      property SelectionCoord: TVector3D read fSelectionCoord;
      function ObjectCount: Integer;
      function Add(O: TGeoObject; Event: String): PSelectableObject;
      procedure Delete(O: TGeoObject);
      function IsSelected(O: TGeoObject): Boolean;
      procedure Update;
      constructor Create;
    end;

implementation

uses
  m_varlist, u_events, math;

function TSelectionEngine.ObjectCount: Integer;
begin
  Result := Length(fSelectableObjects);
end;

function TSelectionEngine.Add(O: TGeoObject; Event: String = ''): PSelectableObject;
begin
  if O = nil then
    RenderTerrain := True
  else
    RenderObjects := True;
  setLength(fSelectableObjects, length(fSelectableObjects) + 1);
  Result := @fSelectableObjects[high(fSelectableObjects)];
  Result^.O := O;
  Result^.Selected := False;
  Result^.Event := Event;
end;

procedure TSelectionEngine.Delete(O: TGeoObject);
var
  i: Integer;
begin
  for i := 0 to high(fSelectableObjects) do
    if fSelectableObjects[i].O = O then
      begin
      fSelectableObjects[i] := fSelectableObjects[high(fSelectableObjects)];
      setLength(fSelectableObjects, length(fSelectableObjects) - 1);
      end;
end;

function TSelectionEngine.IsSelected(O: TGeoObject): Boolean;
var
  i: Integer;
begin
  Result := false;
  for i := 0 to high(fSelectableObjects) do
    if fSelectableObjects[i].O = O then
      exit(fSelectableObjects[i].Selected);
end;

procedure TSelectionEngine.Update;
var
  i: Integer;
begin
  fSelectionCoord := ModuleManager.ModRenderer.SelectionStart + ModuleManager.ModRenderer.SelectionRay;
  for i := 0 to high(fSelectableObjects) do
    begin
    if fSelectableObjects[i].O = nil then
      fSelectableObjects[i].Selected := ModuleManager.ModRenderer.SelectedMaterialID = 1
    else
      fSelectableObjects[i].Selected := ModuleManager.ModRenderer.SelectedMaterialID = fSelectableObjects[i].O.SelectionID;
    if fSelectableObjects[i].Selected then
      EventManager.CallEvent(fSelectableObjects[i].Event, @fSelectableObjects[i], nil);
    end;
end;

constructor TSelectionEngine.Create;
begin
  RenderTerrain := False;
  RenderObjects := False;
  fSelectionCoord := Vector(0, 0, 0);
end;

end.