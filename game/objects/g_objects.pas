unit g_objects;

interface

uses
  SysUtils, Classes, u_linkedlists, g_resources, u_scene, g_loader_ocf, g_res_textures, g_res_materials, u_xml, u_dom, u_vectors,
  g_res_lights, g_res_particles, g_res_objects, u_pathes;

type
  TRealObject = class(TLinkedListItem)
    protected
      fResource: TObjectResource;
      fGeoObject: TGeoObject;
    public
      property Resource: TObjectResource read fResource;
      property GeoObject: TGeoObject read fGeoObject;
      constructor Create(TheResource: TObjectResource);
      procedure Free;
    end;

  TObjectManager = class(TLinkedList)
    protected
      fTestPath: TPath;
      fProgress: Single;
    public
      constructor Create;
      procedure AddTestObject(Event: String; Data, Result: Pointer);
      procedure Test;
      procedure Advance;
      procedure Free;
    end;

implementation

uses
  u_events;

constructor TRealObject.Create(TheResource: TObjectResource);
begin
  inherited Create;
  fResource := TheResource;
  fGeoObject := Resource.GeoObject.Duplicate;
  fGeoObject.Register;
  fGeoObject.Matrix := TranslationMatrix(Vector(160, 64.5, 160));
end;

procedure TRealObject.Free;
begin
  GeoObject.Free;
  inherited Free;
end;

procedure TObjectManager.Advance;
var
  CurrentObject: TRealObject;
begin
  CurrentObject := TRealObject(First);
  while CurrentObject <> nil do
    begin
    with CurrentObject.GeoObject do
      begin
      SetUnchanged;

      fProgress := fProgress + 0.01;

      if GetBoneByName('arm', 'moep') <> nil then
        GetBoneByName('arm', 'moep').Matrix := TranslationMatrix(fTestPath.DataAtDistance(fProgress).Position);
      
      UpdateMatrix;
      UpdateArmatures;
      UpdateVertexPositions;
      RecalcFaceNormals;
      RecalcVertexNormals;
      end;
    CurrentObject := TRealObject(CurrentObject.Next);
    end;
end;

procedure TObjectManager.AddTestObject(Event: String; Data, Result: Pointer);
begin
  Append(TRealObject.Create(TObjectResource(ResourceManager.Resources[TAbstractResource(Data).Name])));
end;

procedure TObjectManager.Test;
begin
  EventManager.AddCallback('TResource.FinishedLoading:scenery/test.ocf/object', @AddTestObject);
  EventManager.AddCallback('TResource.FinishedLoading:scenery/test2.ocf/object', @AddTestObject);
  TObjectResource.Get('scenery/test.ocf/object');
  TObjectResource.Get('scenery/test2.ocf/object');
end;

constructor TObjectManager.Create;
begin
  inherited Create;
  fTestPath := TPath.Create;
  with fTestPath.AddPoint do
    begin
    Position := Vector(160, 65, 160);
    CP1 := Vector(160, 65, 159);
    CP2 := Vector(160, 65, 161);
    end;
  with fTestPath.AddPoint do
    begin
    Position := Vector(161, 65, 162);
    CP1 := Vector(161, 65, 161);
    CP2 := Vector(161, 65, 163);
    end;
  with fTestPath.AddPoint do
    begin
    Position := Vector(159, 65, 164);
    CP1 := Vector(159, 65, 163);
    CP2 := Vector(159, 65, 165);
    end;
  with fTestPath.AddPoint do
    begin
    Position := Vector(159, 65, 166);
    CP1 := Vector(160, 65, 165);
    CP2 := Vector(160, 65, 167);
    end;
  fTestPath.BuildLookupTable;
  fProgress := 0;
end;

procedure TObjectManager.Free;
begin
  while First <> nil do
    TRealObject(First).Free;
  fTestPath.Free;
  inherited Free;
end;

end.