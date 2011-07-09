unit g_object_builder;

interface

uses
  SysUtils, Classes, u_events, g_park, g_parkui,
  m_gui_label_class, m_gui_edit_class, m_gui_tabbar_class, m_gui_button_class, m_gui_iconifiedbutton_class,
  m_gui_scrollbox_class, m_gui_class, m_gui_image_class, m_gui_slider_class, m_gui_checkbox_class, g_sets, g_res_objects,
  u_scene, u_selection, u_vectors;

type
  TGameObjectBuilder = class(TXMLUIWindow)
    protected
//       fColorDialog: TColorDialog;
      fIP: TVector3D;
      fBuilding: TGeoObject;
      fBuildingResource: TObjectResource;
      fSnapToGrid, fSnapToObjects: Boolean;
      fGridSize, fGridRotation: Single;
      fGridOffset: TVector2D;
      fOpen: Boolean;
      fStartRotation: Single;
    public
      SelectionEngine: TSelectionEngine;
      property Open: Boolean read fOpen;
      property GridEnabled: Boolean read fSnapToGrid;
      property GridSize: Single read fGridSize;
      property GridRotation: Single read fGridRotation;
      property GridOffset: TVector2D read fGridOffset;
      procedure UpdateBOPos(Event: String; Data, Result: Pointer);
      procedure AddObject(Event: String; Data, Result: Pointer);
      procedure SelectMaterial(Event: String; Data, Result: Pointer);
      procedure UpdateGrid(Event: String; Data, Result: Pointer);
      procedure UpdateMatrix(Event: String; Data, Result: Pointer);
      procedure UpdateMirror(Event: String; Data, Result: Pointer);
      procedure UpdateMaterial(Event: String; Data, Result: Pointer);
      procedure OnClose(Event: String; Data, Result: Pointer);
      procedure OnShow(Event: String; Data, Result: Pointer);
      procedure OnScroll(Event: String; Data, Result: Pointer);
      procedure SnapToGrid(Event: String; Data, Result: Pointer);
      procedure ChangeTab(Event: String; Data, Result: Pointer);
      procedure BuildObject(Resource: TObjectResource);
      constructor Create(Resource: String; ParkUI: TXMLUIManager);
      destructor Free;
    end;

implementation

uses
  g_object_selector, g_terrain_edit, g_objects, u_math, m_varlist, m_inputhandler_class;

procedure TGameObjectBuilder.SnapToGrid(Event: String; Data, Result: Pointer);
begin
  fSnapToGrid := not fSnapToGrid;
end;

procedure TGameObjectBuilder.UpdateBOPos(Event: String; Data, Result: Pointer);
var
  Mat, InvMat: TMatrix3D;
begin
  if fBuilding <> nil then
    begin
    if ModuleManager.ModInputHandler.Key[K_LCTRL] then
      begin
      if ModuleManager.ModInputHandler.MouseButtons[MOUSE_MIDDLE] then
        begin
        if not ModuleManager.ModInputHandler.Locked then
          begin
          ModuleManager.ModInputHandler.LockMouse;
          fStartRotation := TSlider(fWindow.GetChildByName('object_builder.rotation.y')).Value;
          end;
        TSlider(fWindow.GetChildByName('object_builder.rotation.y')).Value := fStartRotation + 5.0 * Round(0.2 * (ModuleManager.ModInputHandler.MouseX - ModuleManager.ModInputHandler.LockX));
        while TSlider(fWindow.GetChildByName('object_builder.rotation.y')).Value < -180 do
          TSlider(fWindow.GetChildByName('object_builder.rotation.y')).Value += 360.0;
        while TSlider(fWindow.GetChildByName('object_builder.rotation.y')).Value > 180 do
          TSlider(fWindow.GetChildByName('object_builder.rotation.y')).Value -= 360.0;
        end
      else if ModuleManager.ModInputHandler.MouseButtons[MOUSE_RIGHT] then
        begin
        if not ModuleManager.ModInputHandler.Locked then
          begin
          ModuleManager.ModInputHandler.LockMouse;
          fStartRotation := TSlider(fWindow.GetChildByName('object_builder.grid.rotation')).Value;
          end;
        TSlider(fWindow.GetChildByName('object_builder.grid.rotation')).Value := fStartRotation + 5.0 * Round(0.2 * (ModuleManager.ModInputHandler.MouseX - ModuleManager.ModInputHandler.LockX));
        while TSlider(fWindow.GetChildByName('object_builder.grid.rotation')).Value < -90 do
          TSlider(fWindow.GetChildByName('object_builder.grid.rotation')).Value += 180.0;
        while TSlider(fWindow.GetChildByName('object_builder.grid.rotation')).Value > 90 do
          TSlider(fWindow.GetChildByName('object_builder.grid.rotation')).Value -= 180.0;
        end
      else
        begin
        if ModuleManager.ModInputHandler.Locked then
          ModuleManager.ModInputHandler.UnlockMouse;
        fIP := Park.SelectionEngine.SelectionCoord;
        end;
      end
    else
      fIP := Park.SelectionEngine.SelectionCoord;
    if GridEnabled then
      begin
      Mat := Matrix3D(RotationMatrix(GridRotation, Vector(0, -1, 0)));
      InvMat := Matrix3D(RotationMatrix(GridRotation, Vector(0, 1, 0)));
      fIP := fIP * Mat;
      fIP := Vector(Round((fIP.X + GridOffset.X) / GridSize) * GridSize - GridOffset.X, fIP.Y, Round((fIP.Z + GridOffset.Y) / GridSize) * GridSize - GridOffset.Y);
      fIP := fIP * InvMat;
      end;
    if TCheckBox(fWindow.GetChildByName('object_builder.lock.x')).Checked then fIP.X := TSlider(fWindow.GetChildByName('object_builder.offset.x')).Value;
    if TCheckBox(fWindow.GetChildByName('object_builder.lock.y')).Checked then fIP.Y := TSlider(fWindow.GetChildByName('object_builder.offset.y')).Value;
    if TCheckBox(fWindow.GetChildByName('object_builder.lock.z')).Checked then fIP.Z := TSlider(fWindow.GetChildByName('object_builder.offset.z')).Value;
    fIP := Vector(
      Clamp(fIP.X, 0, 0.2 * Park.pTerrain.SizeX),
      Clamp(fIP.Y, 0, 256),
      Clamp(fIP.Z, 0, 0.2 * Park.pTerrain.SizeY));
    fBuilding.Matrix := TranslationMatrix(fIP);
    fBuilding.Matrix := fBuilding.Matrix * RotationMatrix(TSlider(fWindow.GetChildByName('object_builder.rotation.y')).Value, Vector(0, 1, 0));
    fBuilding.Matrix := fBuilding.Matrix * RotationMatrix(TSlider(fWindow.GetChildByName('object_builder.rotation.x')).Value, Vector(1, 0, 0));
    fBuilding.Matrix := fBuilding.Matrix * RotationMatrix(TSlider(fWindow.GetChildByName('object_builder.rotation.z')).Value, Vector(0, 0, 1));
    fBuilding.SetUnchanged;
    fBuilding.ExecuteScript;
    fBuilding.UpdateMatrix;
    fBuilding.UpdateArmatures;
    fBuilding.UpdateVertexPositions;
    fBuilding.RecalcFaceNormals;
    fBuilding.RecalcVertexNormals;
    TSlider(fWindow.GetChildByName('object_builder.offset.x')).Value := fIP.X;
    TSlider(fWindow.GetChildByName('object_builder.offset.y')).Value := fIP.Y;
    TSlider(fWindow.GetChildByName('object_builder.offset.z')).Value := fIP.Z;
    end;
end;

procedure TGameObjectBuilder.AddObject(Event: String; Data, Result: Pointer);
var
  O: TRealObject;
begin
  if (fBuilding <> nil) and (ModuleManager.ModInputHandler.MouseButtons[MOUSE_LEFT]) then
    begin
    O := TRealObject.Create(fBuildingResource);
    O.GeoObject.Matrix := fBuilding.Matrix;
    O.GeoObject.Mirror := fBuilding.Mirror;
    Park.pObjects.Append(O);
    SelectionEngine.Add(O.GeoObject, 'GUIActions.terrain_edit.marks.move');
    end;
end;

procedure TGameObjectBuilder.SelectMaterial(Event: String; Data, Result: Pointer);
begin
end;

procedure TGameObjectBuilder.UpdateGrid(Event: String; Data, Result: Pointer);
begin
  fGridOffset := Vector(TSlider(fWindow.GetChildByName('object_builder.grid.offset.x')).Value, TSlider(fWindow.GetChildByName('object_builder.grid.offset.z')).Value);
  fGridRotation := TSlider(fWindow.GetChildByName('object_builder.grid.rotation')).Value;
  fGridSize := TSlider(fWindow.GetChildByName('object_builder.grid.size')).Value;
end;

procedure TGameObjectBuilder.UpdateMatrix(Event: String; Data, Result: Pointer);
begin
end;

procedure TGameObjectBuilder.UpdateMirror(Event: String; Data, Result: Pointer);
var
  Value: Array[Boolean] of Single = (1.0, -1.0);
begin
  if fBuilding <> nil then
    begin
    fBuilding.Mirror.X := Value[TCheckBox(fWindow.GetChildByName('object_builder.mirror.x')).Checked];
    fBuilding.Mirror.Y := Value[TCheckBox(fWindow.GetChildByName('object_builder.mirror.y')).Checked];
    fBuilding.Mirror.Z := Value[TCheckBox(fWindow.GetChildByName('object_builder.mirror.z')).Checked];
    end;
end;

procedure TGameObjectBuilder.UpdateMaterial(Event: String; Data, Result: Pointer);
begin
end;

procedure TGameObjectBuilder.OnClose(Event: String; Data, Result: Pointer);
begin
  if fBuilding <> nil then
    begin
    fBuilding.Free;
    fBuilding := nil;
    end;
  ParkUI.GetWindowByName('object_selector').Show(fWindow);
  EventManager.RemoveCallback(@UpdateBOPos);
  EventManager.RemoveCallback(@AddObject);
  EventManager.RemoveCallback(@UpdateGrid);
  fOpen := False;
end;

procedure TGameObjectBuilder.OnShow(Event: String; Data, Result: Pointer);
begin
  TSlider(fWindow.GetChildByName('object_builder.offset.x')).Max := 0.2 * Park.pTerrain.SizeX;
  TSlider(fWindow.GetChildByName('object_builder.offset.z')).Max := 0.2 * Park.pTerrain.SizeY;
  EventManager.AddCallback('TPark.Render', @UpdateGrid);
  fOpen := True;
end;

procedure TGameObjectBuilder.OnScroll(Event: String; Data, Result: Pointer);
begin
  if ModuleManager.ModInputHandler.Key[K_LCTRL] then
    begin
    if ModuleManager.ModInputHandler.MouseButtons[MOUSE_WHEEL_UP] then
      begin
      TCheckBox(fWindow.GetChildByName('object_builder.lock.y')).Checked := True;
      TSlider(fWindow.GetChildByName('object_builder.offset.y')).Value := TSlider(fWindow.GetChildByName('object_builder.offset.y')).Value + 0.2;
      end
    else if ModuleManager.ModInputHandler.MouseButtons[MOUSE_WHEEL_DOWN] then
      begin
      TSlider(fWindow.GetChildByName('object_builder.offset.y')).Value := TSlider(fWindow.GetChildByName('object_builder.offset.y')).Value - 0.2;
      TCheckBox(fWindow.GetChildByName('object_builder.lock.y')).Checked := True;
      end
    end;
end;

procedure TGameObjectBuilder.ChangeTab(Event: String; Data, Result: Pointer);
begin
  TLabel(fWindow.GetChildByName('object_builder.tab.container')).Left := -TTabBar(fWindow.GetChildByName('object_builder.tabbar')).SelectedTab * 584;
end;

procedure TGameObjectBuilder.BuildObject(Resource: TObjectResource);
begin
  EventManager.AddCallback('BasicComponent.OnClick', @AddObject);
  Park.SelectionEngine := SelectionEngine;
  EventManager.AddCallback('GUIActions.terrain_edit.marks.move', @UpdateBOPos);

  fBuildingResource := Resource;
  fBuilding := fBuildingResource.GeoObject.Duplicate;
  fBuilding.Register;
  Show(fWindow);
end;

constructor TGameObjectBuilder.Create(Resource: String; ParkUI: TXMLUIManager);
begin
  inherited Create(Resource, ParkUI);

  EventManager.AddCallback('GUIActions.object_builder.open', @OnShow);
  EventManager.AddCallback('GUIActions.object_builder.close', @OnClose);
  EventManager.AddCallback('GUIActions.object_builder.snap.grid', @SnapToGrid);
  EventManager.AddCallback('GUIActions.object_builder.mirror', @UpdateMirror);
  EventManager.AddCallback('GUIActions.object_builder.changeTab', @ChangeTab);
  EventManager.AddCallback('BasicComponent.OnScroll', @OnScroll);
  SelectionEngine := TSelectionEngine.Create;
  SelectionEngine.Add(nil, 'GUIActions.terrain_edit.marks.move');
  fIP := Vector(0, 0, 0);
  fSnapToGrid := False;
  fSnapToObjects := True;
  fGridSize := 1;
  fGridRotation := 0;
  fGridOffset := Vector(0, 0);
  fOpen := False;
  UpdateGrid('', nil, nil);
end;

destructor TGameObjectBuilder.Free;
begin
  SelectionEngine.Free;
  EventManager.RemoveCallback(@ChangeTab);
  EventManager.RemoveCallback(@UpdateMirror);
  EventManager.RemoveCallback(@UpdateGrid);
  EventManager.RemoveCallback(@SnapToGrid);
  EventManager.RemoveCallback(@OnScroll);
  EventManager.RemoveCallback(@OnShow);
  EventManager.RemoveCallback(@OnClose);
  EventManager.RemoveCallback(@UpdateBOPos);
  EventManager.RemoveCallback(@AddObject);
  inherited Free;
end;

end.