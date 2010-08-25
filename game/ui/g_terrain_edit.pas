unit g_terrain_edit;

interface

uses
  SysUtils, Classes, g_parkui, m_gui_iconifiedbutton_class, u_selection, u_geometry, u_math, u_vectors, u_arrays;

type
  TGameTerrainEdit = class(TXMLUIWindow)
    protected
      MarkMode: TIconifiedButton;
      MarksFixed: Boolean;
      fSelectionMap: TMesh;
      fSelectionObject: PSelectableObject;
      fTerrainSelectionEngine: TSelectionEngine;
      fCameraOffset: TVector3D;
    public
      procedure SetWater(Event: String; Data, Result: Pointer);
      procedure Modify(Event: String; Data, Result: Pointer);
      procedure FixMarks(Event: String; Data, Result: Pointer);
      procedure MoveMark(Event: String; Data, Result: Pointer);
      procedure CreateNewMark(Event: String; Data, Result: Pointer);
      procedure UpdateTerrainSelectionMap(Event: String; Data, Result: Pointer);
      procedure MarksChange(Event: String; Data, Result: Pointer);
      procedure ChangeTab(Event: String; Data, Result: Pointer);
      procedure OnClose(Event: String; Data, Result: Pointer);
      constructor Create(Resource: String; ParkUI: TXMLUIManager);
      destructor Free;
    end;

implementation

uses
  u_events, g_park, main, m_gui_label_class, m_gui_tabbar_class, m_varlist, m_inputhandler_class, m_gui_edit_class;

const
  SELECTION_SIZE = 100;

procedure TGameTerrainEdit.SetWater(Event: String; Data, Result: Pointer);
begin
  Park.pTerrain.FillWithWater(fSelectionObject^.IntersectionPoint.X, fSelectionObject^.IntersectionPoint.Z, fSelectionObject^.IntersectionPoint.Y + 0.1);
end;

procedure TGameTerrainEdit.Modify(Event: String; Data, Result: Pointer);
begin
  MarksChange('', nil, nil);
  try
    if Data = Pointer(fWindow.GetChildByName('terrain_edit.modify_setfix')) then
      Park.pTerrain.SetTo(StrToFloat(TEdit(fWindow.GetChildByName('terrain_edit.selected_height')).Text))
    else if Data = Pointer(fWindow.GetChildByName('terrain_edit.modify_minimum')) then
      Park.pTerrain.SetToMin(StrToFloat(TEdit(fWindow.GetChildByName('terrain_edit.selected_height')).Text))
    else if Data = Pointer(fWindow.GetChildByName('terrain_edit.modify_maximum')) then
      Park.pTerrain.SetToMax(StrToFloat(TEdit(fWindow.GetChildByName('terrain_edit.selected_height')).Text))
    else if Data = Pointer(fWindow.GetChildByName('terrain_edit.modify_raise')) then
      Park.pTerrain.RaiseTo(StrToFloat(TEdit(fWindow.GetChildByName('terrain_edit.selected_height')).Text))
    else if Data = Pointer(fWindow.GetChildByName('terrain_edit.modify_lower')) then
      Park.pTerrain.LowerTo(StrToFloat(TEdit(fWindow.GetChildByName('terrain_edit.selected_height')).Text));
  except
    ModuleManager.ModLog.AddError('Modifying terrain failed (' + TIconifiedButton(Data).Name + ')');
  end;
  UpdateTerrainSelectionMap('', nil, nil);
end;

procedure TGameTerrainEdit.FixMarks(Event: String; Data, Result: Pointer);
begin
  MarksFixed := not MarksFixed;
  if MarksFixed then
    TIconifiedButton(Data).Left := 678 + 48
  else
    TIconifiedButton(Data).Left := 678;
end;

procedure TGameTerrainEdit.MoveMark(Event: String; Data, Result: Pointer);
begin
  if MarkMode = TIconifiedButton(fWindow.GetChildByName('terrain_edit.add_marks')) then
    begin
    Park.pTerrain.MarkMode := 0;
    Park.pTerrain.CurrMark := Vector(Round(5 * TSelectableObject(Data^).IntersectionPoint.X) / 5, Round(5 * TSelectableObject(Data^).IntersectionPoint.Z) / 5);
    end
  else
    begin
    Park.pTerrain.MarkMode := 1;
    Park.pTerrain.CurrMark := Vector(5 * TSelectableObject(Data^).IntersectionPoint.X / 5, 5 * TSelectableObject(Data^).IntersectionPoint.Z / 5);
    end;
  if (Park.pTerrain.Marks.Height > 0) and (MarksFixed) then
    begin
    if abs(Park.pTerrain.Marks.Value[0, Park.pTerrain.Marks.Height - 1] - 5 * Park.pTerrain.CurrMark.X) < abs(Park.pTerrain.Marks.Value[1, Park.pTerrain.Marks.Height - 1] - 5 * Park.pTerrain.CurrMark.Y) then
      Park.pTerrain.CurrMark.X := Park.pTerrain.Marks.Value[0, Park.pTerrain.Marks.Height - 1] / 5
    else
      Park.pTerrain.CurrMark.Y := Park.pTerrain.Marks.Value[1, Park.pTerrain.Marks.Height - 1] / 5;
    end;
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
    if Park.pTerrain.Marks.HasRow(Row) = -1 then
      begin
      Row.Resize(0);
      Row.Insert(0, Round(5 * Park.pTerrain.CurrMark.X));
      Row.Insert(1, Round(5 * Park.pTerrain.CurrMark.Y));
      if Park.pTerrain.Marks.HasRow(Row) = -1 then
        Park.pTerrain.Marks.InsertRow(Park.pTerrain.Marks.Height, Row)
      end
    else
      while Park.pTerrain.Marks.HasRow(Row) <> Park.pTerrain.Marks.Height - 1 do
        begin
        Park.pTerrain.Marks.InsertRow(Park.pTerrain.Marks.Height, Park.pTerrain.Marks.GetRow(0));
        Park.pTerrain.Marks.DeleteRow(0);
        end;
    Row.Free;
    end
  else if ModuleManager.ModInputHandler.MouseButtons[MOUSE_RIGHT] then
    begin
    Row := TRow.Create;
    Row.Insert(0, Round(5 * fSelectionObject^.IntersectionPoint.X));
    Row.Insert(1, Round(5 * fSelectionObject^.IntersectionPoint.Z));
    Park.pTerrain.Marks.DeleteRow(Park.pTerrain.Marks.HasRow(Row));
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
      fSelectionMap.pVertices[(SELECTION_SIZE + 1) * j + i]^.Position := fSelectionMap.Vertices[(SELECTION_SIZE + 1) * j + i].Position - fCameraOffset + fTmpCameraOffset;
      fSelectionMap.pVertices[(SELECTION_SIZE + 1) * j + i]^.Position.Y := Park.pTerrain.HeightMap[fSelectionMap.Vertices[(SELECTION_SIZE + 1) * j + i].Position.X, fSelectionMap.Vertices[(SELECTION_SIZE + 1) * j + i].Position.Z];
      end;
  fCameraOffset := fTmpCameraOffset;
end;

procedure TGameTerrainEdit.MarksChange(Event: String; Data, Result: Pointer);
begin
  Park.pTerrain.MarkMode := 0;
  if Pointer(MarkMode) = Data then
    Data := nil;
  if MarkMode = TIconifiedButton(fWindow.GetChildByName('terrain_edit.add_marks')) then
    MarkMode.Left := 678;
  Park.pTerrain.CurrMark := Vector(-1, -1);
  EventManager.RemoveCallback(@UpdateTerrainSelectionMap);
  EventManager.RemoveCallback(@CreateNewMark);
  EventManager.RemoveCallback(@SetWater);
  if Data = Pointer(fWindow.GetChildByName('terrain_edit.add_marks')) then
    begin
    Park.SelectionEngine := fTerrainSelectionEngine;
    EventManager.AddCallback('TPark.Render', @UpdateTerrainSelectionMap);
    EventManager.AddCallback('BasicComponent.OnClick', @CreateNewMark);
    MarkMode := TIconifiedButton(Data);
    MarkMode.Left := 678 + 16;
    end
  else if Data = Pointer(fWindow.GetChildByName('terrain_edit.water_set')) then
    begin
    OnClose('', nil, nil);
    Park.SelectionEngine := fTerrainSelectionEngine;
    EventManager.AddCallback('TPark.Render', @UpdateTerrainSelectionMap);
    EventManager.AddCallback('BasicComponent.OnClick', @SetWater);
    MarkMode := TIconifiedButton(Data);
    end
  else
    begin
    Park.SelectionEngine := Park.NormalSelectionEngine;
    Park.pTerrain.CreateMarkMap;
    MarkMode := TIconifiedButton(Data);
    end;
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

constructor TGameTerrainEdit.Create(Resource: String; ParkUI: TXMLUIManager);
var
  i, j: Integer;
begin
  inherited Create(Resource, ParkUI);
  MarkMode := nil;
  MarksFixed := false;
  EventManager.AddCallback('GUIActions.terrain_edit.changeTab', @changeTab);
  EventManager.AddCallback('GUIActions.terrain_edit.marks.add', @MarksChange);
  EventManager.AddCallback('GUIActions.terrain_edit.marks.delete', @OnClose);
  EventManager.AddCallback('GUIActions.terrain_edit.marks.fix', @FixMarks);
  EventManager.AddCallback('GUIActions.terrain_edit.marks.move', @MoveMark);
  EventManager.AddCallback('GUIActions.terrain_edit.final.marks.add', @CreateNewMark);
  EventManager.AddCallback('GUIActions.terrain_edit.close', @OnClose);
  EventManager.AddCallback('GUIActions.terrain_edit.modify.minimum', @Modify);
  EventManager.AddCallback('GUIActions.terrain_edit.modify.maximum', @Modify);
  EventManager.AddCallback('GUIActions.terrain_edit.modify.setfix', @Modify);
  EventManager.AddCallback('GUIActions.terrain_edit.modify.raise', @Modify);
  EventManager.AddCallback('GUIActions.terrain_edit.modify.lower', @Modify);

  fCameraOffset := Vector(0, 0, 0);
  fSelectionMap := TMesh.Create;
  for j := 0 to SELECTION_SIZE do
    for i := 0 to SELECTION_SIZE do
      fSelectionMap.Vertices[(SELECTION_SIZE + 1) * j + i] := MakeMeshVertex(Vector(i - 0.5 * SELECTION_SIZE, 0, j - 0.5 * SELECTION_SIZE) * 0.8, Vector(0.0, 1.0, 0.0), Vector(0.0, 0.0));
  for j := 0 to SELECTION_SIZE - 1 do
    for i := 0 to SELECTION_SIZE - 1 do
      begin
      fSelectionMap.Triangles[fSelectionMap.TriangleCount] := MakeTriangleVertexArray((SELECTION_SIZE + 1) * j + i, (SELECTION_SIZE + 1) * j + i + 1, (SELECTION_SIZE + 1) * (j + 1) + i);
      fSelectionMap.Triangles[fSelectionMap.TriangleCount] := MakeTriangleVertexArray((SELECTION_SIZE + 1) * (j + 1) + (i + 1), (SELECTION_SIZE + 1) * j + i + 1, (SELECTION_SIZE + 1) * (j + 1) + i);
      end;
  fTerrainSelectionEngine := TSelectionEngine.Create;
  fSelectionObject := fTerrainSelectionEngine.Add(fSelectionMap, 'GUIActions.terrain_edit.marks.move');
end;

destructor TGameTerrainEdit.Free;
begin
  fTerrainSelectionEngine.Free;
  fSelectionMap.Free;
  EventManager.RemoveCallback(@FixMarks);
  EventManager.RemoveCallback(@MoveMark);
  EventManager.RemoveCallback(@CreateNewMark);
  EventManager.RemoveCallback(@Modify);
  EventManager.RemoveCallback(@changeTab);
  EventManager.RemoveCallback(@OnClose);
  EventManager.RemoveCallback(@MarksChange);
  inherited Free;
end;

end.