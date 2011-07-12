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
      fIP: TVector3D;
      fDefaultReflectivity: Single;
      fBuildingNew, fJustClosed: Boolean;
      fBuilding: TGeoObject;
      fBuildingResource: TObjectResource;
      fSnapToGrid, fSnapToObjects: Boolean;
      fGridSize, fGridRotation: Single;
      fGridOffset: TVector2D;
      fOpen: Boolean;
      fStartRotation: Single;
      fMaterialBox: TScrollBox;
      fMaterialButtons: Array of TButton;
      fSelectedMaterial: Integer;
      fAffectMaterials: Boolean;
    public
      SelectionEngine: TSelectionEngine;
      property Open: Boolean read fOpen;
      property GridEnabled: Boolean read fSnapToGrid;
      property GridSize: Single read fGridSize;
      property GridRotation: Single read fGridRotation;
      property GridOffset: TVector2D read fGridOffset;
      procedure SelectObject(Event: String; Data, Result: Pointer);
      procedure UpdateBOPos(Event: String; Data, Result: Pointer);
      procedure AddObject(Event: String; Data, Result: Pointer);
      procedure UpdateGrid(Event: String; Data, Result: Pointer);
      procedure UpdateMirror(Event: String; Data, Result: Pointer);
      procedure UpdateMaterial(Event: String; Data, Result: Pointer);
      procedure ResetReflectivity(Event: String; Data, Result: Pointer);
      procedure SelectMaterial(Sender: TGUIComponent);
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
  g_object_selector, g_terrain_edit, g_objects, u_math, m_varlist, m_inputhandler_class, math;

procedure TGameObjectBuilder.SnapToGrid(Event: String; Data, Result: Pointer);
begin
  fSnapToGrid := not fSnapToGrid;
end;

procedure TGameObjectBuilder.SelectObject(Event: String; Data, Result: Pointer);
var
  tmp: TMatrix4D;
  UpVector: TVector4D;
  Rotation: TVector3D;
  CosBeta: Single;
begin
  if (ModuleManager.ModInputHandler.MouseButtons[MOUSE_LEFT]) and not (fJustClosed) and (ModuleManager.ModGUI.ClickingBasicComponent) then
    begin
    fBuildingNew := False;
    fBuilding := TSelectableObject(Data^).O;
    TCheckBox(fWindow.GetChildByName('object_builder.lock.x')).Checked := True;
    TCheckBox(fWindow.GetChildByName('object_builder.lock.y')).Checked := True;
    TCheckBox(fWindow.GetChildByName('object_builder.lock.z')).Checked := True;
    TSlider(fWindow.GetChildByName('object_builder.offset.x')).Value := fBuilding.Matrix[0].W;
    TSlider(fWindow.GetChildByName('object_builder.offset.y')).Value := fBuilding.Matrix[1].W;
    TSlider(fWindow.GetChildByName('object_builder.offset.z')).Value := fBuilding.Matrix[2].W;
    TCheckBox(fWindow.GetChildByName('object_builder.mirror.x')).Checked := fBuilding.Mirror.X <> 1;
    TCheckBox(fWindow.GetChildByName('object_builder.mirror.y')).Checked := fBuilding.Mirror.Y <> 1;
    TCheckBox(fWindow.GetChildByName('object_builder.mirror.z')).Checked := fBuilding.Mirror.Z <> 1;
    tmp := fBuilding.Matrix;
    UpVector := Vector(0, 1, 0, 0) * tmp;
    Rotation := Vector(0, 0, 0);
    Rotation.X := ArcSin(-Tmp[1].Z);
    CosBeta := Cos(Rotation.X);
    if CosBeta > 0.01 then
      begin
      Rotation.Y := ArcCos(Tmp[2].Z / CosBeta) * Sign(Tmp[0].Z / CosBeta);
      Rotation.Z := ArcSin(Tmp[1].X / CosBeta);
      if Sign(Tmp[1].Y) < 0 then
        Rotation.Z := Sign(Rotation.Z) * 3.141593 - Rotation.Z;
      end
    else
      begin
      Rotation.Z := 0;
      Rotation.Y := (ArcCos(DotProduct(Normalize(Vector3D(UpVector)), Vector(0, 0, -1))) * -Sign(DotProduct(Normalize(Vector3D(UpVector)), Vector(1, 0, 0))));
      end;
    TSlider(fWindow.GetChildByName('object_builder.rotation.x')).Value := RadToDeg(Rotation.X);
    TSlider(fWindow.GetChildByName('object_builder.rotation.y')).Value := RadToDeg(Rotation.Y);
    TSlider(fWindow.GetChildByName('object_builder.rotation.z')).Value := RadToDeg(Rotation.Z);
    SelectionEngine.Delete(fBuilding);
    Show(fWindow);
    end;
  fJustClosed := False;
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
    if fBuildingNew then
      begin
      fBuilding.SetUnchanged;
      fBuilding.ExecuteScript;
      fBuilding.UpdateMatrix;
      fBuilding.UpdateArmatures;
      fBuilding.UpdateVertexPositions;
      fBuilding.RecalcFaceNormals;
      fBuilding.RecalcVertexNormals;
      end;
    TSlider(fWindow.GetChildByName('object_builder.offset.x')).Value := fIP.X;
    TSlider(fWindow.GetChildByName('object_builder.offset.y')).Value := fIP.Y;
    TSlider(fWindow.GetChildByName('object_builder.offset.z')).Value := fIP.Z;
    end;
end;

procedure TGameObjectBuilder.AddObject(Event: String; Data, Result: Pointer);
var
  O: TRealObject;
  I: Integer;
begin
  if (fBuilding <> nil) and (ModuleManager.ModInputHandler.MouseButtons[MOUSE_LEFT]) then
    begin
    if fBuildingNew then
      begin
      O := TRealObject.Create(fBuildingResource);
      for I := 0 to high(O.GeoObject.Materials) do
        begin
        O.GeoObject.Materials[I].Color := fBuilding.Materials[I].Color;
        O.GeoObject.Materials[I].Emission := fBuilding.Materials[I].Emission;
        O.GeoObject.Materials[I].Reflectivity := fBuilding.Materials[I].Reflectivity;
        end;
      O.GeoObject.Matrix := fBuilding.Matrix;
      O.GeoObject.Mirror := fBuilding.Mirror;
      Park.pObjects.Append(O);
      SelectionEngine.Add(O.GeoObject, 'GUIActions.terrain_edit.marks.move');
      Park.NormalSelectionEngine.Add(O.GeoObject, 'TPark.Objects.Selected');
      end
    else
      begin
      TCheckBox(fWindow.GetChildByName('object_builder.lock.x')).Checked := True;
      TCheckBox(fWindow.GetChildByName('object_builder.lock.y')).Checked := True;
      TCheckBox(fWindow.GetChildByName('object_builder.lock.z')).Checked := True;
      end;
    end;
end;

procedure TGameObjectBuilder.UpdateGrid(Event: String; Data, Result: Pointer);
begin
  fGridOffset := Vector(TSlider(fWindow.GetChildByName('object_builder.grid.offset.x')).Value, TSlider(fWindow.GetChildByName('object_builder.grid.offset.z')).Value);
  fGridRotation := TSlider(fWindow.GetChildByName('object_builder.grid.rotation')).Value;
  fGridSize := TSlider(fWindow.GetChildByName('object_builder.grid.size')).Value;
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
  if (fSelectedMaterial > -1) and (fBuilding <> nil) and (fAffectMaterials) then
    begin
    fBuilding.Materials[fSelectedMaterial].Color := Vector(TColorPicker(fWindow.GetChildByName('object_builder.material.color')).CurrentColor, fBuilding.Materials[fSelectedMaterial].Color.W);
    fBuilding.Materials[fSelectedMaterial].Emission := Vector(TColorPicker(fWindow.GetChildByName('object_builder.material.emission')).CurrentColor, fBuilding.Materials[fSelectedMaterial].Emission.W);
    fBuilding.Materials[fSelectedMaterial].Reflectivity := TSlider(fWindow.GetChildByName('object_builder.material.reflectivity')).Value;
    end;
end;

procedure TGameObjectBuilder.ResetReflectivity(Event: String; Data, Result: Pointer);
begin
  TSlider(fWindow.GetChildByName('object_builder.material.reflectivity')).Value := fDefaultReflectivity;
  UpdateMaterial('', nil, nil);
end;

procedure TGameObjectBuilder.SelectMaterial(Sender: TGUIComponent);
var
  I: Integer;
begin
  if Sender <> nil then
    begin
    fSelectedMaterial := -1;
    for I := 0 to high(fMaterialButtons) do
      if fMaterialButtons[I] = Sender then
        fMaterialButtons[I].Alpha := 1.0
      else
        fMaterialButtons[I].Alpha := 0.5;
    if fBuildingNew then
      begin
      TColorPicker(fWindow.GetChildByName('object_builder.material.color')).DefaultColor := Vector3D(fBuildingResource.GeoObject.Materials[Sender.Tag].Color);
      TColorPicker(fWindow.GetChildByName('object_builder.material.emission')).DefaultColor := Vector3D(fBuildingResource.GeoObject.Materials[Sender.Tag].Emission);
      fDefaultReflectivity := fBuildingResource.GeoObject.Materials[Sender.Tag].Reflectivity;
      end
    else
      begin
      TColorPicker(fWindow.GetChildByName('object_builder.material.color')).DefaultColor := Vector3D(fBuilding.Materials[Sender.Tag].Color);
      TColorPicker(fWindow.GetChildByName('object_builder.material.emission')).DefaultColor := Vector3D(fBuilding.Materials[Sender.Tag].Emission);
      fDefaultReflectivity := fBuilding.Materials[Sender.Tag].Reflectivity;
      end;
    TSlider(fWindow.GetChildByName('object_builder.material.reflectivity')).Value := fBuilding.Materials[Sender.Tag].Reflectivity;
    TColorPicker(fWindow.GetChildByName('object_builder.material.color')).CurrentColor := Vector3D(fBuilding.Materials[Sender.Tag].Color);
    TColorPicker(fWindow.GetChildByName('object_builder.material.emission')).CurrentColor := Vector3D(fBuilding.Materials[Sender.Tag].Emission);
    fSelectedMaterial := Sender.Tag;
    end;
end;

procedure TGameObjectBuilder.OnClose(Event: String; Data, Result: Pointer);
var
  I: Integer;
begin
  if fBuildingNew then
    begin
    if fBuilding <> nil then
      fBuilding.Free;
    ParkUI.GetWindowByName('object_selector').Show(fWindow);
    end
  else
    begin
    SelectionEngine.Add(fBuilding, 'GUIActions.terrain_edit.marks.move');
    TCheckBox(fWindow.GetChildByName('object_builder.lock.x')).Checked := False;
    TCheckBox(fWindow.GetChildByName('object_builder.lock.y')).Checked := False;
    TCheckBox(fWindow.GetChildByName('object_builder.lock.z')).Checked := False;
    TCheckBox(fWindow.GetChildByName('object_builder.mirror.x')).Checked := False;
    TCheckBox(fWindow.GetChildByName('object_builder.mirror.y')).Checked := False;
    TCheckBox(fWindow.GetChildByName('object_builder.mirror.z')).Checked := False;
    Park.pTerrain.CurrMark := Vector(-1, -1);
    Park.pTerrain.MarkMode := 0;
    Park.pTerrain.UpdateMarks;
    end;
  fBuilding := nil;
  EventManager.RemoveCallback(@UpdateBOPos);
  EventManager.RemoveCallback(@AddObject);
  EventManager.RemoveCallback(@UpdateGrid);
  fOpen := False;
  for I := 0 to high(fMaterialButtons) do
    fMaterialButtons[i].Free;
  setLength(fMaterialButtons, 0);
  fSelectedMaterial := -1;
  fJustClosed := True;
  Park.SelectionEngine := Park.NormalSelectionEngine;
end;

procedure TGameObjectBuilder.OnShow(Event: String; Data, Result: Pointer);
var
  I: Integer;
begin
  TSlider(fWindow.GetChildByName('object_builder.offset.x')).Max := 0.2 * Park.pTerrain.SizeX;
  TSlider(fWindow.GetChildByName('object_builder.offset.z')).Max := 0.2 * Park.pTerrain.SizeY;
  EventManager.AddCallback('TPark.Render', @UpdateGrid);
  fOpen := True;
  fSelectedMaterial := -1;

  fAffectMaterials := False;
  
  SetLength(fMaterialButtons, Length(fBuilding.Materials));
  for I := 0 to high(fBuilding.Materials) do
    begin
    fMaterialButtons[I] := TButton.Create(fMaterialBox);
    fMaterialButtons[I].Left := 0;
    fMaterialButtons[I].Top := 32 * I;
    fMaterialButtons[I].Width := 176;
    fMaterialButtons[I].Height := 32;
    fMaterialButtons[I].Caption := fBuilding.Materials[I].Name;
    fMaterialButtons[I].Tag := I;
    fMaterialButtons[I].Alpha := 0.5;
    fMaterialButtons[I].OnClick := @SelectMaterial;
    end;

  if Length(fBuilding.Materials) > 0 then
    SelectMaterial(fMaterialButtons[0]);

  ResetReflectivity('', nil, nil);
  TColorPicker(fWindow.GetChildByName('object_builder.material.color')).CurrentColor := TColorPicker(fWindow.GetChildByName('object_builder.material.color')).DefaultColor;
  TColorPicker(fWindow.GetChildByName('object_builder.material.emission')).CurrentColor := TColorPicker(fWindow.GetChildByName('object_builder.material.emission')).DefaultColor;

  fAffectMaterials := True;

  Park.SelectionEngine := SelectionEngine;
  EventManager.AddCallback('GUIActions.terrain_edit.marks.move', @UpdateBOPos);
  EventManager.AddCallback('BasicComponent.OnClick', @AddObject);
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
  fBuildingNew := True;

  fBuildingResource := Resource;
  fBuilding := fBuildingResource.GeoObject.Duplicate;
  fBuilding.Register;

  Show(fWindow);
end;

constructor TGameObjectBuilder.Create(Resource: String; ParkUI: TXMLUIManager);
var
  A: TRealObject;
begin
  inherited Create(Resource, ParkUI);

  fAffectMaterials := True;
  fSelectedMaterial := -1;
  fDefaultReflectivity := 0;
  fBuildingNew := False;
  fJustClosed := False;
  
  fMaterialBox := TScrollBox.Create(fWindow.GetChildByName('object_builder.tab.material'));
  fMaterialBox.Left := 0;
  fMaterialBox.Width := 192;
  fMaterialBox.Height := 192;
  fMaterialBox.Top := 0;
  fMaterialBox.HScrollBar := sbmInvisible;

  EventManager.AddCallback('GUIActions.object_builder.open', @OnShow);
  EventManager.AddCallback('GUIActions.object_builder.close', @OnClose);
  EventManager.AddCallback('GUIActions.object_builder.snap.grid', @SnapToGrid);
  EventManager.AddCallback('GUIActions.object_builder.mirror', @UpdateMirror);
  EventManager.AddCallback('GUIActions.object_builder.changeTab', @ChangeTab);
  EventManager.AddCallback('GUIActions.object_builder.material.update', @UpdateMaterial);
  EventManager.AddCallback('GUIActions.object_builder.material.reflectivity.reset', @ResetReflectivity);
  EventManager.AddCallback('TPark.Objects.Selected', @SelectObject);
  EventManager.AddCallback('BasicComponent.OnScroll', @OnScroll);
  SelectionEngine := TSelectionEngine.Create;
  SelectionEngine.Add(nil, 'GUIActions.terrain_edit.marks.move');

  A := TRealObject(Park.pObjects.First);
  while A <> nil do
    begin
    SelectionEngine.Add(A.GeoObject, 'GUIActions.terrain_edit.marks.move');
    A := TRealObject(A.Next);
    end;
  
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
  EventManager.RemoveCallback(@ResetReflectivity);
  EventManager.RemoveCallback(@SelectObject);
  EventManager.RemoveCallback(@ChangeTab);
  EventManager.RemoveCallback(@UpdateMaterial);
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