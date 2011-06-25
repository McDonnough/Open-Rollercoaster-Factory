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
      procedure UpdateMaterial(Event: String; Data, Result: Pointer);
      procedure OnClose(Event: String; Data, Result: Pointer);
      procedure OnShow(Event: String; Data, Result: Pointer);
      procedure SnapToGrid(Event: String; Data, Result: Pointer);
      procedure BuildObject(Resource: TObjectResource);
      constructor Create(Resource: String; ParkUI: TXMLUIManager);
      destructor Free;
    end;

implementation

uses
  g_object_selector, g_terrain_edit, g_objects, u_math;

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
    fIP := Park.SelectionEngine.SelectionCoord;
    if TCheckBox(fWindow.GetChildByName('object_builder.lock.x')).Checked then fIP.X := TSlider(fWindow.GetChildByName('object_builder.offset.x')).Value;
    if TCheckBox(fWindow.GetChildByName('object_builder.lock.y')).Checked then fIP.Y := TSlider(fWindow.GetChildByName('object_builder.offset.y')).Value;
    if TCheckBox(fWindow.GetChildByName('object_builder.lock.z')).Checked then fIP.Z := TSlider(fWindow.GetChildByName('object_builder.offset.z')).Value;
    if GridEnabled then
      begin
      Mat := Matrix3D(RotationMatrix(GridRotation, Vector(0, -1, 0)));
      InvMat := Matrix3D(RotationMatrix(GridRotation, Vector(0, 1, 0)));
      fIP := fIP * Mat;
      fIP := Vector(Round((fIP.X + GridOffset.X) / GridSize) * GridSize - GridOffset.X, fIP.Y, Round((fIP.Z + GridOffset.Y) / GridSize) * GridSize - GridOffset.Y);
      fIP := fIP * InvMat;
      end;
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
  if fBuilding <> nil then
    begin
    O := TRealObject.Create(fBuildingResource);
    O.GeoObject.Matrix := fBuilding.Matrix;
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
  EventManager.RemoveCallback(@UpdateGrid);
  EventManager.RemoveCallback(@SnapToGrid);
  EventManager.RemoveCallback(@OnShow);
  EventManager.RemoveCallback(@OnClose);
  EventManager.RemoveCallback(@UpdateBOPos);
  EventManager.RemoveCallback(@AddObject);
  inherited Free;
end;

end.