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
  fPos: TVector3D;
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
    Position := Vector(0, 0, 0);
    CP1 := Vector(0, 0, -1);
    CP2 := Vector(0, 0, 1);
    end;
  with fTestPath.AddPoint do
    begin
    Position := Vector(1, -0.1, 2);
    CP1 := Vector(1, -0.1, 1);
    CP2 := Vector(1, -0.1, 3);
    end;
  with fTestPath.AddPoint do
    begin
    Position := Vector(-1, 0.1, 4);
    CP1 := Vector(-1, 0.1, 3);
    CP2 := Vector(-1, 0.1, 5);
    end;
  with fTestPath.AddPoint do
    begin
    Position := Vector(-1, 0, 6);
    CP1 := Vector(0, 0, 5);
    CP2 := Vector(0, 0, 7);
    end;
  fTestPath.Closed := True;
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