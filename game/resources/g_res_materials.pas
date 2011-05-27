unit g_res_materials;

interface

uses
  SysUtils, Classes, m_texmng_class, g_resources, g_loader_ocf, u_scene, g_res_textures;

type
  TMaterialResource = class(TAbstractResource)
    protected
      fTextureResource, fBumpmapResource: TTextureResource;
      fMaterial: TMaterial;
      fDepCount: Integer;
    public
      property Material: TMaterial read fMaterial;
      class function Get(ResourceName: String): TMaterialResource;
      constructor Create(ResourceName: String);
      procedure FileLoaded(Data: TOCFFile);
      procedure DepLoaded(Event: String; Data, Result: Pointer);
      procedure Free;
    end;

implementation

uses
  u_graphics, u_events, u_xml, u_dom, u_functions, u_vectors;

class function TMaterialResource.Get(ResourceName: String): TMaterialResource;
begin
  Result := TMaterialResource(ResourceManager.Resources[ResourceName]);
  if Result = nil then
    Result := TMaterialResource.Create(ResourceName)
  else
    ResourceManager.AddFinishedResource(Result);
end;

constructor TMaterialResource.Create(ResourceName: String);
begin
  fTextureResource := nil;
  fBumpmapResource := nil;
  fMaterial := TMaterial.Create;
  fDepCount := 0;
  inherited Create(ResourceName, @FileLoaded);
end;

procedure TMaterialResource.FileLoaded(Data: TOCFFile);
var
  Doc: TDOMDocument;
  CurrElement: TDOMElement;
  S: String;
  i: Integer;
  fTextureResourceName, fBumpmapResourceName: String;
begin
  fTextureResourceName := '';
  fBumpmapResourceName := '';
  with Data.ResourceByName(SubResourceName) do
    begin
    setLength(S, length(Data.Bin[Section].Stream.Data));
    for i := 0 to high(Data.Bin[Section].Stream.Data) do
      S[i + 1] := char(Data.Bin[Section].Stream.Data[i]);
    Doc := DOMFromXML(S);
    CurrElement := TDOMElement(Doc.GetElementsByTagName('material')[0].FirstChild);
    while CurrElement <> nil do
      begin
      if CurrElement.TagName = 'name' then
        fMaterial.Name := CurrElement.FirstChild.NodeValue
      else if CurrElement.TagName = 'texture' then
        begin
        inc(fDepCount);
        fTextureResourceName := CurrElement.GetAttribute('resource:name');
        EventManager.AddCallback('TResource.FinishedLoading:' + fTextureResourceName, @DepLoaded);
        end
      else if CurrElement.TagName = 'bumpmap' then
        begin
        inc(fDepCount);
        fBumpmapResourceName := CurrElement.GetAttribute('resource:name');
        EventManager.AddCallback('TResource.FinishedLoading:' + fBumpmapResourceName, @DepLoaded);
        end
      else if CurrElement.TagName = 'reflectivity' then
        begin
        fMaterial.Reflectivity := StrToFloatWD(CurrElement.FirstChild.NodeValue, 0);
        fMaterial.OnlyEnvironmentMaphint := CurrElement.GetAttribute('onlyenvironmentmap') = 'true';
        end
      else if CurrElement.TagName = 'specularity' then
        fMaterial.Specularity := StrToFloatWD(CurrElement.FirstChild.NodeValue, 1)
      else if CurrElement.TagName = 'hardness' then
        fMaterial.Hardness := StrToFloatWD(CurrElement.FirstChild.NodeValue, 20)
      else if CurrElement.TagName = 'refractiveindex' then
        fMaterial.RefractiveIndex := StrToFloatWD(CurrElement.FirstChild.NodeValue, 0)
      else if CurrElement.TagName = 'color' then
        fMaterial.Color := Vector(
          StrToFloatWD(CurrElement.GetAttribute('r'), 1),
          StrToFloatWD(CurrElement.GetAttribute('g'), 1),
          StrToFloatWD(CurrElement.GetAttribute('b'), 1),
          StrToFloatWD(CurrElement.GetAttribute('a'), 1))
      else if CurrElement.TagName = 'emission' then
        fMaterial.Emission := Vector(
          StrToFloatWD(CurrElement.GetAttribute('r'), 0),
          StrToFloatWD(CurrElement.GetAttribute('g'), 0),
          StrToFloatWD(CurrElement.GetAttribute('b'), 0),
          StrToFloatWD(CurrElement.GetAttribute('falloff'), 1));
      CurrElement := TDOMElement(CurrElement.NextSibling);
      end;
    Doc.Free;
    end;
  if fDepCount = 0 then
    DepLoaded('', nil, nil)
  else
    begin
    if fTextureResourceName <> '' then
      fTextureResource := TTextureResource.Get(fTextureResourceName);
    if fBumpmapResourceName <> '' then
      fBumpmapResource := TTextureResource.Get(fBumpmapResourceName);
    end;
end;

procedure TMaterialResource.DepLoaded(Event: String; Data, Result: Pointer);
begin
  dec(fDepCount);
  if fDepCount <= 0 then
    begin
    if fTextureResource <> nil then
      fMaterial.Texture := fTextureResource.Texture;
    if fBumpmapResource <> nil then
      fMaterial.Bumpmap := fBumpmapResource.Texture;
    FinishedLoading := True;
    end;
end;

procedure TMaterialResource.Free;
begin
  EventManager.RemoveCallback(@DepLoaded);
  fMaterial.Free;
  inherited Free;
end;

end.