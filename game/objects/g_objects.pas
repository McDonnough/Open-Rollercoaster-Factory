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
    public
      constructor Create;
      procedure AddTestObject(Event: String; Data, Result: Pointer);
      procedure Test;
      procedure Advance;
      procedure Free;
    end;

implementation

uses
  u_events, main;

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

      if CurrentObject.GeoObject.GetBoneByName('arm', 'moep') <> nil then
        CurrentObject.GeoObject.GetBoneByName('arm', 'moep').PathConstraint.Progress += 0.002;

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
  EventManager.AddCallback('TResource.FinishedLoading:scenery/test/moep.ocf/object', @AddTestObject);
  TObjectResource.Get('scenery/test.ocf/object');
  TObjectResource.Get('scenery/test2.ocf/object');
  TObjectResource.Get('scenery/test/moep.ocf/object');
end;

constructor TObjectManager.Create;
begin
  inherited Create;
end;

procedure TObjectManager.Free;
begin
  while First <> nil do
    TRealObject(First).Free;
  inherited Free;
end;

end.