unit g_terrain_edit;

interface

uses
  SysUtils, Classes, g_parkui, m_gui_iconifiedbutton_class, u_selection, u_geometry, u_math, u_vectors;

type
  TGameTerrainEdit = class(TParkUIWindow)
    protected
      MarkMode: TIconifiedButton;
      fSelectionMap: TMesh;
      fTerrainSelectionEngine, fFlagSelectionEngine: TSelectionEngine;
      fCameraOffset: TVector3D;
    public
      procedure CreateNewMark(Event: String; Data, Result: Pointer);
      procedure UpdateTerrainSelectionMap(Event: String; Data, Result: Pointer);
      procedure MarksChange(Event: String; Data, Result: Pointer);
      procedure changeTab(Event: String; Data, Result: Pointer);
      constructor Create(Resource: String; ParkUI: TParkUI);
      destructor Free;
    end;

implementation

uses
  u_events, g_park, main, m_gui_label_class, m_gui_tabbar_class, m_varlist;

procedure TGameTerrainEdit.CreateNewMark(Event: String; Data, Result: Pointer);
begin
  Park.pTerrain.TexMap[TSelectableObject(Data^).IntersectionPoint.X, TSelectableObject(Data^).IntersectionPoint.Z] := 2;
end;

procedure TGameTerrainEdit.UpdateTerrainSelectionMap(Event: String; Data, Result: Pointer);
var
  fTmpCameraOffset: TVector3D;
  i, j: Integer;
begin
  fTmpCameraOffset := VecRound(ModuleManager.ModCamera.ActiveCamera.Position * 5) / 5;
  if fTmpCameraOffset = fCameraOffset then
    exit;
  for j := 0 to 100 do
    for i := 0 to 100 do
      begin
      fSelectionMap.pVertices[100 * j + i]^.Position := fSelectionMap.Vertices[100 * j + i].Position - fCameraOffset + fTmpCameraOffset;
      fSelectionMap.pVertices[100 * j + i]^.Position.Y := Park.pTerrain.HeightMap[fSelectionMap.Vertices[100 * j + i].Position.X, fSelectionMap.Vertices[100 * j + i].Position.Z];
      end;

  fCameraOffset := fTmpCameraOffset;
end;

procedure TGameTerrainEdit.MarksChange(Event: String; Data, Result: Pointer);
begin
  if Pointer(MarkMode) = Data then
    Data := nil;
  if MarkMode <> nil then
    MarkMode.Left := 678;
  EventManager.RemoveCallback(@UpdateTerrainSelectionMap);
  if Data = Pointer(fWindow.GetChildByName('terrain_edit.add_marks')) then
    begin
    Park.SelectionEngine := fTerrainSelectionEngine;
    EventManager.AddCallback('TPark.Render', @UpdateTerrainSelectionMap);
    MarkMode := TIconifiedButton(Data);
    MarkMode.Left := 678 + 16;
    end
  else if Data = Pointer(fWindow.GetChildByName('terrain_edit.delete_marks')) then
    begin
    Park.SelectionEngine := fFlagSelectionEngine;
    MarkMode := TIconifiedButton(Data);
    MarkMode.Left := 678 + 16;
    end
  else
    begin
    Park.SelectionEngine := Park.NormalSelectionEngine;
    end;
  MarkMode := TIconifiedButton(Data);
end;

procedure TGameTerrainEdit.changeTab(Event: String; Data, Result: Pointer);
begin
  TLabel(fWindow.GetChildByName('terrain_edit.tab.container')).Left := -750 * TTabBar(fWindow.GetChildByName('terrain_edit.tabbar')).SelectedTab;
end;

constructor TGameTerrainEdit.Create(Resource: String; ParkUI: TParkUI);
var
  i, j: Integer;
begin
  inherited Create(Resource, ParkUI);
  MarkMode := nil;
  EventManager.AddCallback('GUIActions.terrain_edit.changeTab', @changeTab);
  EventManager.AddCallback('GUIActions.terrain_edit.marks.add', @MarksChange);
  EventManager.AddCallback('GUIActions.terrain_edit.marks.delete', @MarksChange);
  EventManager.AddCallback('GUIActions.terrain_edit.final.marks.add', @CreateNewMark);
  fCameraOffset := Vector(0, 0, 0);
  fSelectionMap := TMesh.Create;
  for j := 0 to 100 do
    for i := 0 to 100 do
      begin
      fSelectionMap.Vertices[101 * j + i] := MakeMeshVertex(Vector(i - 50, 0, j - 50) * 0.2, Vector(0.0, 1.0, 0.0), Vector(0.0, 0.0));
      if (i < 100) and (j < 100) then
        begin
        fSelectionMap.Triangles[2 * (100 * j + i) + 0] := MakeTriangleVertexArray(101 * j + i, 101 * (j + 1) + i, 101 * (j + 1) + (i + 1));
        fSelectionMap.Triangles[2 * (100 * j + i) + 1] := MakeTriangleVertexArray(101 * (j + 1) + i, 101 * (j + 1) + (i + 1), 101 * j + i + 1 );
        end;
      end;
  fFlagSelectionEngine := TSelectionEngine.Create;
  fTerrainSelectionEngine := TSelectionEngine.Create;
  fTerrainSelectionEngine.Add(fSelectionMap, 'GUIActions.terrain_edit.final.marks.add');
end;

destructor TGameTerrainEdit.Free;
begin
  fFlagSelectionEngine.Free;
  fTerrainSelectionEngine.Free;
  fSelectionMap.Free;
  EventManager.RemoveCallback(@changeTab);
  EventManager.RemoveCallback(@MarksChange);
  inherited Free;
end;

end.