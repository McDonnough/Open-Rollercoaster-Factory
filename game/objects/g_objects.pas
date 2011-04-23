unit g_objects;

interface

uses
  SysUtils, Classes, u_linkedlists, g_resources, u_scene, g_loader_ocf;

type
  TObjectResource = class(TAbstractResource)
    protected
      fGeoObject: TGeoObject;
      fDepCount, fLoaded: Integer;
    public
      property GeoObject: TGeoObject read fGeoObject;
      constructor Create(ResourceName: String);
      procedure FinalCreation;
      procedure FileLoaded(Data: TOCFFile);
      procedure DepsLoaded(Data: TOCFFile);
      procedure Free;
    end;

  TRealObject = class(TLinkedListItem)
    protected
      fResource: TObjectResource;
      fGeoObject: TGeoObject;
    public
      property Resource: TObjectResource read fResource;
      property GeoObject: TGeoObject read fGeoObject;
      constructor Create(TheResource: TObjectResource);
      destructor Free;
    end;

  TObjectManager = class(TLinkedList)
    protected
    public
      constructor Create;
      procedure Free;
    end;

implementation

constructor TObjectResource.Create(ResourceName: String);
begin
  fLoaded := 0;
  fDepCount := 0;
  inherited Create(ResourceName, @FileLoaded, @DepsLoaded);
  fGeoObject := nil;
end;

procedure TObjectResource.FinalCreation;
begin
  fGeoObject := TGeoObject.Create;
end;

procedure TObjectResource.FileLoaded(Data: TOCFFile);
begin
  
end;

procedure TObjectResource.DepsLoaded(Data: TOCFFile);
begin
  inc(fLoaded);
end;

procedure TObjectResource.Free;
begin
  if fGeoObject <> nil then
    fGeoObject.Free;
  inherited Free;
end;

constructor TRealObject.Create(TheResource: TObjectResource);
begin
  inherited Create;
  fResource := TheResource;
  fGeoObject := Resource.GeoObject.Duplicate;
end;

destructor TRealObject.Free;
begin
  GeoObject.Free;
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