unit g_terrain_edit;

interface

uses
  SysUtils, Classes, g_parkui, m_gui_iconifiedbutton_class, u_selection, u_geometry, u_math, u_vectors, u_arrays;

type
  TGameTerrainEdit = class(TParkUIWindow)
    protected
      MarkMode: TIconifiedButton;
      fSelectionMap: TMesh;
      fSelectionObject: PSelectableObject;
      fTerrainSelectionEngine, fFlagSelectionEngine: TSelectionEngine;
      fCameraOffset: TVector3D;
    public
      procedure MoveMark(Event: String; Data, Result: Pointer);
      procedure CreateNewMark(Event: String; Data, Result: Pointer);
      procedure UpdateTerrainSelectionMap(Event: String; Data, Result: Pointer);
      procedure MarksChange(Event: String; Data, Result: Pointer);
      procedure ChangeTab(Event: String; Data, Result: Pointer);
      procedure OnClose(Event: String; Data, Result: Pointer);
      constructor Create(Resource: String; ParkUI: TParkUI);
      destructor Free;
    end;

implementation

uses
  u_events, g_park, main, m_gui_label_class, m_gui_tabbar_class, m_varlist, m_inputhandler_class;

const
  SELECTION_SIZE = 200;

procedure TGameTerrainEdit.MoveMark(Event: String; Data, Result: Pointer);
begin
  Park.pTerrain.CurrMark := Vector(Round(5 * TSelectableObject(Data^).IntersectionPoint.X) / 5, Round(5 * TSelectableObject(Data^).IntersectionPoint.Z) / 5);
  fSelectionObject := PSelectableObject(Data);
end;

procedure TGameTerrainEdit.CreateNewMark(Event: String; Data, Result: Pointer);
var
  Row: TRow;
begin
  if ModuleManager.ModInputHandler.MouseButtons[MOUSE_LEFT] then
    begin
    Row := TRow.Create;
    Row.Insert(0, Round(5 * fSelectionObject^.IntersectionPoint.X));
    Row.Insert(1, Round(5 * fSelectionObject^.IntersectionPoint.Z));
    if Park.pTerrain.Marks.HasRow(Row) <> -1 then
      Park.pTerrain.Marks.InsertRow(Park.pTerrain.Marks.Height, Row);
    Row.Free;
    end;
end;

procedure TGameTerrainEdit.UpdateTerrainSelectionMap(Event: String; Data, Result: Pointer);
var
  fTmpCameraOffset: TVector3D;
  i, j: Integer;
begin
  fTmpCameraOffset := VecRound(ModuleManager.ModCamera.ActiveCamera.Position * 5) / 5;
  if fTmpCameraOffset = fCameraOffset then
    exit;
  for j := 0 to SELECTION_SIZE do
    for i := 0 to SELECTION_SIZE do
      begin
      fSelectionMap.pVertices[SELECTION_SIZE * j + i]^.Position := fSelectionMap.Vertices[SELECTION_SIZE * j + i].Position - fCameraOffset + fTmpCameraOffset;
      fSelectionMap.pVertices[SELECTION_SIZE * j + i]^.Position.Y := Park.pTerrain.HeightMap[fSelectionMap.Vertices[SELECTION_SIZE * j + i].Position.X, fSelectionMap.Vertices[SELECTION_SIZE * j + i].Position.Z];
      end;

  fCameraOffset := fTmpCameraOffset;
end;

procedure TGameTerrainEdit.MarksChange(Event: String; Data, Result: Pointer);
begin
  if Pointer(MarkMode) = Data then
    Data := nil;
  if MarkMode <> nil then
    MarkMode.Left := 678;
  Park.pTerrain.CurrMark := Vector(-1, -1);
  EventManager.RemoveCallback(@UpdateTerrainSelectionMap);
  EventManager.RemoveCallback(@CreateNewMark);
  if Data = Pointer(fWindow.GetChildByName('terrain_edit.add_marks')) then
    begin
    Park.SelectionEngine := fTerrainSelectionEngine;
    EventManager.AddCallback('TPark.Render', @UpdateTerrainSelectionMap);
    EventManager.AddCallback('BasicComponent.OnClick', @CreateNewMark);
    MarkMode := TIconifiedButton(Data);
    MarkMode.Left := 678 + 16;
    end
  else if Data = Pointer(fWindow.GetChildByName('terrain_edit.delete_marks')) then
    begin
    EventManager.AddCallback('TPark.Render', @UpdateMarkSelection);
    EventManager.AddCallback('BasicComponent.OnClick', @DeleteMark);
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

procedure TGameTerrainEdit.OnClose(Event: String; Data, Result: Pointer);
begin
  Park.pTerrain.Marks.Resize(2, 0);
  MarksChange('', nil, nil);
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
  EventManager.AddCallback('GUIActions.terrain_edit.close', @OnClose);
  EventManager.AddCallback('GUIActions.terrain_edit.marks.move', @MoveMark);

  fCameraOffset := Vector(0, 0, 0);
  fSelectionMap := TMesh.Create;
  for j := 0 to SELECTION_SIZE do
    for i := 0 to SELECTION_SIZE do
      begin
      fSelectionMap.Vertices[(SELECTION_SIZE + 1) * j + i] := MakeMeshVertex(Vector(i - 0.5 * SELECTION_SIZE, 0, j - 0.5 * SELECTION_SIZE) * 0.2, Vector(0.0, 1.0, 0.0), Vector(0.0, 0.0));
      if (i < SELECTION_SIZE) and (j < SELECTION_SIZE) then
        begin
        fSelectionMap.Triangles[2 * (SELECTION_SIZE * j + i) + 0] := MakeTriangleVertexArray((SELECTION_SIZE + 1) * j + i, (SELECTION_SIZE + 1) * (j + 1) + i, (SELECTION_SIZE + 1) * (j + 1) + (i + 1));
        fSelectionMap.Triangles[2 * (SELECTION_SIZE * j + i) + 1] := MakeTriangleVertexArray((SELECTION_SIZE + 1) * (j + 1) + i, (SELECTION_SIZE + 1) * (j + 1) + (i + 1), (SELECTION_SIZE + 1) * j + i + 1 );
        end;
      end;
  fFlagSelectionEngine := TSelectionEngine.Create;
  fTerrainSelectionEngine := TSelectionEngine.Create;
  fSelectionObject := fTerrainSelectionEngine.Add(fSelectionMap, 'GUIActions.terrain_edit.marks.move');
end;

destructor TGameTerrainEdit.Free;
begin
  fFlagSelectionEngine.Free;
  fTerrainSelectionEngine.Free;
  fSelectionMap.Free;
  EventManager.RemoveCallback(@changeTab);
  EventManager.RemoveCallback(@OnClose);
  EventManager.RemoveCallback(@MarksChange);
  inherited Free;
end;

end.