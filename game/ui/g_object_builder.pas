unit g_object_builder;

interface

uses
  SysUtils, Classes, u_events, g_park, g_parkui,
  m_gui_label_class, m_gui_edit_class, m_gui_tabbar_class, m_gui_button_class, m_gui_iconifiedbutton_class,
  m_gui_scrollbox_class, m_gui_class, m_gui_image_class, m_gui_slider_class, g_sets, g_res_objects,
  u_scene, u_selection, u_vectors;

type
  TGameObjectBuilder = class(TXMLUIWindow)
    protected
//       fColorDialog: TColorDialog;
      fIP: TVector3D;
      fBuilding: TGeoObject;
      fBuildingResource: TObjectResource;
    public
      procedure UpdateBOPos(Event: String; Data, Result: Pointer);
      procedure AddObject(Event: String; Data, Result: Pointer);
      procedure SelectMaterial(Event: String; Data, Result: Pointer);
      procedure UpdateGrid(Event: String; Data, Result: Pointer);
      procedure UpdateMatrix(Event: String; Data, Result: Pointer);
      procedure UpdateMaterial(Event: String; Data, Result: Pointer);
      procedure OnClose(Event: String; Data, Result: Pointer);
      procedure OnShow(Event: String; Data, Result: Pointer);
      procedure BuildObject(Resource: TObjectResource);
      constructor Create(Resource: String; ParkUI: TXMLUIManager);
      destructor Free;
    end;

implementation

uses
  g_object_selector, g_terrain_edit, g_objects;

procedure TGameObjectBuilder.UpdateBOPos(Event: String; Data, Result: Pointer);
begin
  if fBuilding <> nil then
    begin
    fIP := TSelectableObject(Data^).IntersectionPoint;
    fBuilding.Matrix := TranslationMatrix(TSelectableObject(Data^).IntersectionPoint);
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
    end;
end;

procedure TGameObjectBuilder.SelectMaterial(Event: String; Data, Result: Pointer);
begin
end;

procedure TGameObjectBuilder.UpdateGrid(Event: String; Data, Result: Pointer);
begin
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
  EventManager.RemoveCallback('TPark.Render', @TGameTerrainEdit(ParkUI.GetWindowByName('terrain_edit')).UpdateTerrainSelectionMap);
end;

procedure TGameObjectBuilder.OnShow(Event: String; Data, Result: Pointer);
begin
  writeln(Event);
  TSlider(fWindow.GetChildByName('object_builder.offset.x')).Max := 0.2 * Park.pTerrain.SizeX;
  TSlider(fWindow.GetChildByName('object_builder.offset.z')).Max := 0.2 * Park.pTerrain.SizeY;
end;

procedure TGameObjectBuilder.BuildObject(Resource: TObjectResource);
begin
  EventManager.AddCallback('BasicComponent.OnClick', @AddObject);
  Park.SelectionEngine := TGameTerrainEdit(ParkUI.GetWindowByName('terrain_edit')).TerrainSelectionEngine;
  EventManager.AddCallback('GUIActions.terrain_edit.marks.move', @UpdateBOPos);
  EventManager.AddCallback('TPark.Render', @TGameTerrainEdit(ParkUI.GetWindowByName('terrain_edit')).UpdateTerrainSelectionMap);

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
  fIP := Vector(0, 0, 0);
end;

destructor TGameObjectBuilder.Free;
begin
  EventManager.RemoveCallback(@OnShow);
  EventManager.RemoveCallback(@OnClose);
  EventManager.RemoveCallback(@UpdateBOPos);
  EventManager.RemoveCallback(@AddObject);
  EventManager.RemoveCallback('TPark.Render', @TGameTerrainEdit(ParkUI.GetWindowByName('terrain_edit')).UpdateTerrainSelectionMap);
  inherited Free;
end;

end.