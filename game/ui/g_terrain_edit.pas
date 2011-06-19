unit g_terrain_edit;

interface

uses
  SysUtils, Classes, g_parkui, m_gui_iconifiedbutton_class, u_selection, u_scene, u_math, u_vectors, u_arrays, u_functions, math,
  m_gui_button_class, u_dialogs;

type
  TGameTerrainEdit = class(TXMLUIWindow)
    protected
      MarkMode: TIconifiedButton;
      MarksFixed: Boolean;
      fSelectionObject: PSelectableObject;
      fTerrainSelectionEngine: TSelectionEngine;
      fAutoTexMode: TButton;
      fFileDialog: TFileDialog;
    public
      property TerrainSelectionEngine: TSelectionEngine read fTerrainSelectionEngine;
      procedure LoadTexture(Event: String; Data, Result: Pointer);
      procedure LoadTextureDialog(Event: String; Data, Result: Pointer);
      procedure SetAutotex(Event: String; Data, Result: Pointer);
      procedure ChangeAutotexMode(Event: String; Data, Result: Pointer);
      procedure ModifyHeight(Event: String; Data, Result: Pointer);
      procedure HeightLine(Event: String; Data, Result: Pointer);
      procedure SetSize(Event: String; Data, Result: Pointer);
      procedure Resized(Event: String; Data, Result: Pointer);
      procedure PickHeight(Event: String; Data, Result: Pointer);
      procedure CollectionChanged(Event: String; Data, Result: Pointer);
      procedure SetTexture(Event: String; Data, Result: Pointer);
      procedure SetWater(Event: String; Data, Result: Pointer);
      procedure DeleteWater(Event: String; Data, Result: Pointer);
      procedure Modify(Event: String; Data, Result: Pointer);
      procedure FixMarks(Event: String; Data, Result: Pointer);
      procedure MoveMark(Event: String; Data, Result: Pointer);
      procedure CreateNewMark(Event: String; Data, Result: Pointer);
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

procedure TGameTerrainEdit.LoadTexture(Event: String; Data, Result: Pointer);
begin
  if Event = 'TFileDialog.Selected' then
    Park.pTerrain.ChangeCollection(String(Data^));
  EventManager.RemoveCallback(@LoadTexture);
  fFileDialog.Free;
  fFileDialog := nil;
end;

procedure TGameTerrainEdit.LoadTextureDialog(Event: String; Data, Result: Pointer);
begin
  fFileDialog := TFileDialog.Create(true, '', 'Change terrain texture collection');
  EventManager.AddCallback('TFileDialog.Selected', @LoadTexture);
  EventManager.AddCallback('TFileDialog.Aborted', @LoadTexture);
end;

procedure TGameTerrainEdit.SetAutotex(Event: String; Data, Result: Pointer);
var
  Mode, i: Integer;
begin
  Mode := 0;
  if fAutoTexMode = TButton(fWindow.GetChildByName('terrain_edit.autotex.higher')) then Mode := 1
  else if fAutoTexMode = TButton(fWindow.GetChildByName('terrain_edit.autotex.steeper')) then Mode := 2;
  for i := 1 to 8 do
    if Data = Pointer(fWindow.GetChildByName('terrain_edit.small_texture_' + IntToStr(i))) then
      begin
      Park.pTerrain.AutoTexture(i - 1, mode, StrToFloatWD(TEdit(fWindow.GetChildByName('terrain_edit.autotex.value')).Text, -1));
      exit;
      end;
end;

procedure TGameTerrainEdit.ChangeAutotexMode(Event: String; Data, Result: Pointer);
begin
  if fAutoTexMode <> nil then
    fAutoTexMode.Alpha := 0.5;
  TButton(Data).Alpha := 1;
  fAutoTexMode := TButton(Data);
end;

procedure TGameTerrainEdit.ModifyHeight(Event: String; Data, Result: Pointer);
begin
  if Data = Pointer(fWindow.GetChildByName('terrain_edit.height.raise')) then
    TEdit(fWindow.GetChildByName('terrain_edit.selected_height')).Text := FloatToStr(0.1 * Round(10 * Min(StrToFloatWD(TEdit(fWindow.GetChildByName('terrain_edit.selected_height')).Text, 0) + 1, 255.0)))
  else if Data = Pointer(fWindow.GetChildByName('terrain_edit.height.lower')) then
    TEdit(fWindow.GetChildByName('terrain_edit.selected_height')).Text := FloatToStr(0.1 * Round(10 * Max(StrToFloatWD(TEdit(fWindow.GetChildByName('terrain_edit.selected_height')).Text, 0) - 1, 0.0)))
  else if Event = 'BasicComponent.OnClick' then
    TEdit(fWindow.GetChildByName('terrain_edit.selected_height')).Text := FloatToStr(0.1 * Round(10 * Park.SelectionEngine.SelectionCoord.Y));
  TEdit(fWindow.GetChildByName('terrain_edit.autotex.value')).Text := TEdit(fWindow.GetChildByName('terrain_edit.selected_height')).Text;
  HeightLine('GUIActions.terrain_edit.createheightline', nil, nil);
end;

procedure TGameTerrainEdit.HeightLine(Event: String; Data, Result: Pointer);
var
  fForcedHeightLine: Single;
begin
  if Event = 'GUIActions.terrain_edit.createheightline' then
    fForcedHeightLine := StrToFloatWD(TEdit(fWindow.GetChildByName('terrain_edit.selected_height')).Text, -1)
  else if Event = 'GUIActions.terrain_edit.autotex.createheightline' then
    fForcedHeightLine := StrToFloatWD(TEdit(fWindow.GetChildByName('terrain_edit.selected_height')).Text, -1)
  else
    fForcedHeightLine := -1;
  EventManager.CallEvent('TTerrain.ApplyForcedHeightLine', @fForcedHeightLine, nil);
end;

procedure TGameTerrainEdit.SetSize(Event: String; Data, Result: Pointer);
var
  DX, DY: Integer;
begin
  DX := Park.pTerrain.SizeX;
  DY := Park.pTerrain.SizeY;
  if Data = Pointer(fWindow.GetChildByName('terrain_edit.grow.x')) then
    inc(DX, 128)
  else if Data = Pointer(fWindow.GetChildByName('terrain_edit.grow.y')) then
    inc(DY, 128)
  else if Data = Pointer(fWindow.GetChildByName('terrain_edit.shrink.x')) then
    dec(DX, 128)
  else if Data = Pointer(fWindow.GetChildByName('terrain_edit.shrink.y')) then
    dec(DY, 128);
  if (DX > 0) and (DY > 0) and (DX <= 8192) and (DY <= 8192) then
    Park.pTerrain.Resize(DX, DY);
end;

procedure TGameTerrainEdit.Resized(Event: String; Data, Result: Pointer);
begin
  TLabel(fWindow.GetChildByName('terrain_edit.sizex')).Caption := IntToStr(Park.pTerrain.SizeX);
  TLabel(fWindow.GetChildByName('terrain_edit.sizey')).Caption := IntToStr(Park.pTerrain.SizeY);
end;

procedure TGameTerrainEdit.PickHeight(Event: String; Data, Result: Pointer);
begin
  if Park.pTerrain.Marks.Height > 0 then
    begin
    TEdit(fWindow.GetChildByName('terrain_edit.selected_height')).Text := FloatToStr(0.1 * Round(10 * Park.pTerrain.HeightMap[0.2 * Park.pTerrain.Marks.Value[0, Park.pTerrain.Marks.Height - 1], 0.2 * Park.pTerrain.Marks.Value[1, Park.pTerrain.Marks.Height - 1]]));
    TEdit(fWindow.GetChildByName('terrain_edit.autotex.value')).Text := TEdit(fWindow.GetChildByName('terrain_edit.selected_height')).Text;
    end;
end;

procedure TGameTerrainEdit.CollectionChanged(Event: String; Data, Result: Pointer);
  function CreateImage(OX, OY: Single): String;
  var
    i, j: Integer;
    X, Y: Integer;
    H: Integer;
    DX, DY: Integer;
    D: DWord;
  begin
    X := Round(Park.pTerrain.Collection.Texture.Width * OX);
    Y := Round(Park.pTerrain.Collection.Texture.Height * OY);
    H := Park.pTerrain.Collection.Texture.Height div 2;
    DX := 4;
    DY := 4;
    Result := 'RGBA:';
    Result := Result + IntToHex(48, 4);
    Result := Result + IntToHex(48, 4);
    Park.pTerrain.Collection.Texture.Bind(0);
    for j := 0 to 47 do
      for i := 0 to 47 do
        begin
        D := Park.pTerrain.Collection.Texture.Pixels[X + DX * i, Y + DY * j];
        Result := Result + IntToHex((D shr 16) and $FF, 2);
        Result := Result + IntToHex((D shr 8) and $FF, 2);
        Result := Result + IntToHex(D and $FF, 2);
        Result := Result + IntToHex(Round((D shr 24) and $FF * Clamp(6 - 0.25 * (VecLength(Vector(i, j) - 24)), 0, 1)), 2);
        end;
    Park.pTerrain.Collection.Texture.UnBind;
  end;
begin
  TIconifiedButton(fWindow.GetChildByName('terrain_edit.texture_1')).Icon := CreateImage(0, 0);
  TIconifiedButton(fWindow.GetChildByName('terrain_edit.texture_2')).Icon := CreateImage(0.25, 0);
  TIconifiedButton(fWindow.GetChildByName('terrain_edit.texture_3')).Icon := CreateImage(0.5, 0);
  TIconifiedButton(fWindow.GetChildByName('terrain_edit.texture_4')).Icon := CreateImage(0.75, 0);
  TIconifiedButton(fWindow.GetChildByName('terrain_edit.texture_5')).Icon := CreateImage(0, 0.25);
  TIconifiedButton(fWindow.GetChildByName('terrain_edit.texture_6')).Icon := CreateImage(0.25, 0.25);
  TIconifiedButton(fWindow.GetChildByName('terrain_edit.texture_7')).Icon := CreateImage(0.5, 0.25);
  TIconifiedButton(fWindow.GetChildByName('terrain_edit.texture_8')).Icon := CreateImage(0.75, 0.25);
  TIconifiedButton(fWindow.GetChildByName('terrain_edit.small_texture_1')).Icon := TIconifiedButton(fWindow.GetChildByName('terrain_edit.texture_1')).Icon;
  TIconifiedButton(fWindow.GetChildByName('terrain_edit.small_texture_2')).Icon := TIconifiedButton(fWindow.GetChildByName('terrain_edit.texture_2')).Icon;
  TIconifiedButton(fWindow.GetChildByName('terrain_edit.small_texture_3')).Icon := TIconifiedButton(fWindow.GetChildByName('terrain_edit.texture_3')).Icon;
  TIconifiedButton(fWindow.GetChildByName('terrain_edit.small_texture_4')).Icon := TIconifiedButton(fWindow.GetChildByName('terrain_edit.texture_4')).Icon;
  TIconifiedButton(fWindow.GetChildByName('terrain_edit.small_texture_5')).Icon := TIconifiedButton(fWindow.GetChildByName('terrain_edit.texture_5')).Icon;
  TIconifiedButton(fWindow.GetChildByName('terrain_edit.small_texture_6')).Icon := TIconifiedButton(fWindow.GetChildByName('terrain_edit.texture_6')).Icon;
  TIconifiedButton(fWindow.GetChildByName('terrain_edit.small_texture_7')).Icon := TIconifiedButton(fWindow.GetChildByName('terrain_edit.texture_7')).Icon;
  TIconifiedButton(fWindow.GetChildByName('terrain_edit.small_texture_8')).Icon := TIconifiedButton(fWindow.GetChildByName('terrain_edit.texture_8')).Icon;
end;

procedure TGameTerrainEdit.SetTexture(Event: String; Data, Result: Pointer);
var
  i: Integer;
begin
  MarksChange('', nil, nil);
  for i := 1 to 8 do
    if Data = Pointer(fWindow.GetChildByName('terrain_edit.texture_' + IntToStr(i))) then
      begin
      Park.pTerrain.SetTexture(i - 1);
      exit;
      end;
end;

procedure TGameTerrainEdit.SetWater(Event: String; Data, Result: Pointer);
begin
  Park.pTerrain.FillWithWater(Park.SelectionEngine.SelectionCoord.X, Park.SelectionEngine.SelectionCoord.Z, Ceil(10 * (Park.SelectionEngine.SelectionCoord.Y + 0.1)) / 10);
end;

procedure TGameTerrainEdit.DeleteWater(Event: String; Data, Result: Pointer);
begin
  Park.pTerrain.RemoveWater(Park.SelectionEngine.SelectionCoord.X, Park.SelectionEngine.SelectionCoord.Z);
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
      Park.pTerrain.LowerTo(StrToFloat(TEdit(fWindow.GetChildByName('terrain_edit.selected_height')).Text))
    else if Data = Pointer(fWindow.GetChildByName('terrain_edit.modify_smooth')) then
      Park.pTerrain.Smooth;
  except
    ModuleManager.ModLog.AddError('Modifying terrain failed (' + TIconifiedButton(Data).Name + ')');
  end;
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
    Park.pTerrain.CurrMark := Vector(Round(5 * Park.SelectionEngine.SelectionCoord.X) / 5, Round(5 * Park.SelectionEngine.SelectionCoord.Z) / 5);
    end
  else if MarkMode = TIconifiedButton(fWindow.GetChildByName('terrain_edit.select_height')) then
    EventManager.CallEvent('TTerrain.ApplyForcedHeightLine', @(Park.SelectionEngine.SelectionCoord.Y), nil)
  else
    begin
    Park.pTerrain.MarkMode := 1;
    Park.pTerrain.CurrMark := Vector(5 * Park.SelectionEngine.SelectionCoord.X / 5, 5 * Park.SelectionEngine.SelectionCoord.Z / 5);
    end;
  if (Park.pTerrain.Marks.Height > 0) and (MarksFixed) then
    begin
    if abs(Park.pTerrain.Marks.Value[0, Park.pTerrain.Marks.Height - 1] - 5 * Park.pTerrain.CurrMark.X) < abs(Park.pTerrain.Marks.Value[1, Park.pTerrain.Marks.Height - 1] - 5 * Park.pTerrain.CurrMark.Y) then
      Park.pTerrain.CurrMark.X := Park.pTerrain.Marks.Value[0, Park.pTerrain.Marks.Height - 1] / 5
    else
      Park.pTerrain.CurrMark.Y := Park.pTerrain.Marks.Value[1, Park.pTerrain.Marks.Height - 1] / 5;
    end;
  fSelectionObject := PSelectableObject(Data);
  Park.pTerrain.UpdateMarks;
end;

procedure TGameTerrainEdit.CreateNewMark(Event: String; Data, Result: Pointer);
var
  Row: TRow;
begin
  if ModuleManager.ModInputHandler.MouseButtons[MOUSE_LEFT] then
    begin
    Row := TRow.Create;
    Row.Insert(0, Round(5 * Park.SelectionEngine.SelectionCoord.X));
    Row.Insert(1, Round(5 * Park.SelectionEngine.SelectionCoord.Z));
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
    Row.Insert(0, Round(5 * Park.SelectionEngine.SelectionCoord.X));
    Row.Insert(1, Round(5 * Park.SelectionEngine.SelectionCoord.Z));
    Park.pTerrain.Marks.DeleteRow(Park.pTerrain.Marks.HasRow(Row));
    Row.Free;
    end;
  Park.pTerrain.UpdateMarks;
end;

procedure TGameTerrainEdit.MarksChange(Event: String; Data, Result: Pointer);
begin
  Park.pTerrain.MarkMode := 0;
  if Pointer(MarkMode) = Data then
    Data := nil;
  if MarkMode = TIconifiedButton(fWindow.GetChildByName('terrain_edit.add_marks')) then
    MarkMode.Left := 678
  else if MarkMode = TIconifiedButton(fWindow.GetChildByName('terrain_edit.water_set')) then
    MarkMode.Top := 8
  else if MarkMode = TIconifiedButton(fWindow.GetChildByName('terrain_edit.water_delete')) then
    MarkMode.Top := 8;
  HeightLine('', nil, nil);
  Park.pTerrain.CurrMark := Vector(-1, -1);
  EventManager.RemoveCallback(@CreateNewMark);
  EventManager.RemoveCallback(@SetWater);
  EventManager.RemoveCallback(@DeleteWater);
  EventManager.RemoveCallback('BasicComponent.OnClick', @ModifyHeight);
  if Data = Pointer(fWindow.GetChildByName('terrain_edit.add_marks')) then
    begin
    Park.SelectionEngine := fTerrainSelectionEngine;
    EventManager.AddCallback('BasicComponent.OnClick', @CreateNewMark);
    MarkMode := TIconifiedButton(Data);
    MarkMode.Left := 678 + 16;
    end
  else if Data = Pointer(fWindow.GetChildByName('terrain_edit.water_set')) then
    begin
    OnClose('', nil, nil);
    Park.SelectionEngine := fTerrainSelectionEngine;
    EventManager.AddCallback('BasicComponent.OnClick', @SetWater);
    MarkMode := TIconifiedButton(Data);
    MarkMode.Top := 0;
    end
  else if Data = Pointer(fWindow.GetChildByName('terrain_edit.water_delete')) then
    begin
    OnClose('', nil, nil);
    Park.SelectionEngine := fTerrainSelectionEngine;
    EventManager.AddCallback('BasicComponent.OnClick', @DeleteWater);
    MarkMode := TIconifiedButton(Data);
    MarkMode.Top := 0;
    end
  else if Data = Pointer(fWindow.GetChildByName('terrain_edit.select_height')) then
    begin
    OnClose('', nil, nil);
    Park.SelectionEngine := fTerrainSelectionEngine;
    EventManager.AddCallback('BasicComponent.OnClick', @ModifyHeight);
    MarkMode := TIconifiedButton(Data);
    end
  else
    begin
    Park.SelectionEngine := Park.NormalSelectionEngine;
    Park.pTerrain.CreateMarkMap;
    MarkMode := TIconifiedButton(Data);
    end;
  Park.pTerrain.UpdateMarks;
end;

procedure TGameTerrainEdit.changeTab(Event: String; Data, Result: Pointer);
begin
  TLabel(fWindow.GetChildByName('terrain_edit.tab.container')).Left := -750 * TTabBar(fWindow.GetChildByName('terrain_edit.tabbar')).SelectedTab;
end;

procedure TGameTerrainEdit.OnClose(Event: String; Data, Result: Pointer);
begin
  Park.pTerrain.Marks.Resize(2, 0);
  MarksChange('', nil, nil);
  Park.pTerrain.UpdateMarks;
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
  EventManager.AddCallback('GUIActions.terrain_edit.modify.smooth', @Modify);
  EventManager.AddCallback('GUIActions.terrain_edit.texture.set', @SetTexture);
  EventManager.AddCallback('GUIActions.terrain_edit.pick_height', @PickHeight);
  EventManager.AddCallback('GUIActions.terrain_edit.resize', @SetSize);
  EventManager.AddCallback('GUIActions.terrain_edit.createheightline', @HeightLine);
  EventManager.AddCallback('GUIActions.terrain_edit.removeheightline', @HeightLine);
  EventManager.AddCallback('GUIActions.terrain_edit.modifyheight', @ModifyHeight);
  EventManager.AddCallback('GUIActions.terrain_edit.autotex.createheightline', @HeightLine);
  EventManager.AddCallback('GUIActions.terrain_edit.autotex.changemode', @ChangeAutotexMode);
  EventManager.AddCallback('GUIActions.terrain_edit.autotex.set', @SetAutoTex);
  EventManager.AddCallback('GUIActions.terrain_edit.load_texture', @LoadTextureDialog);
  EventManager.AddCallback('TTerrain.ChangedCollection', @CollectionChanged);
  EventManager.AddCallback('TTerrain.Resize', @Resized);

  fTerrainSelectionEngine := TSelectionEngine.Create;
  fSelectionObject := fTerrainSelectionEngine.Add(nil, 'GUIActions.terrain_edit.marks.move');

  fAutoTexMode := nil;

  fFileDialog := nil;

  CollectionChanged('', nil, nil);
  Resized('', nil, nil);
  ChangeAutotexMode('', fWindow.GetChildByName('terrain_edit.autotex.lower'), nil);
end;

destructor TGameTerrainEdit.Free;
begin
  fTerrainSelectionEngine.Free;
  if fFileDialog <> nil then
    fFileDialog.Free;
  EventManager.RemoveCallback(@SetWater);
  EventManager.RemoveCallback(@DeleteWater);
  EventManager.RemoveCallback(@LoadTexture);
  EventManager.RemoveCallback(@LoadTextureDialog);
  EventManager.RemoveCallback(@SetAutoTex);
  EventManager.RemoveCallback(@ChangeAutotexMode);
  EventManager.RemoveCallback(@ModifyHeight);
  EventManager.RemoveCallback(@HeightLine);
  EventManager.RemoveCallback(@SetSize);
  EventManager.RemoveCallback(@Resized);
  EventManager.RemoveCallback(@PickHeight);
  EventManager.RemoveCallback(@SetTexture);
  EventManager.RemoveCallback(@CollectionChanged);
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