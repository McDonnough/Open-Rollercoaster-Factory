unit g_res_lights;

interface

uses
  SysUtils, Classes, m_texmng_class, g_resources, g_loader_ocf, dglOpenGL, u_scene;

type
  TLightResource = class(TAbstractResource)
    protected
      fLight: TLightSource;
    public
      property Light: TLightSource read fLight;
      class function Get(ResourceName: String): TLightResource;
      constructor Create(ResourceName: String);
      procedure FileLoaded(Data: TOCFFile);
      procedure Free;
    end;

implementation

uses
  u_graphics, u_events, u_vectors, u_functions, u_dom, u_xml;

class function TLightResource.Get(ResourceName: String): TLightResource;
begin
  Result := TLightResource(ResourceManager.Resources[ResourceName]);
  if Result = nil then
    Result := TLightResource.Create(ResourceName)
  else
    ResourceManager.AddFinishedResource(Result);
end;

constructor TLightResource.Create(ResourceName: String);
begin
  fLight := TLightSource.Create;
  inherited Create(ResourceName, @FileLoaded);
end;

procedure TLightResource.FileLoaded(Data: TOCFFile);
var
  S: String;
  Doc: TDOMDocument;
  CurrElement: TDOMElement;
  i: Integer;
begin
  with Data.ResourceByName(SubResourceName) do
    begin
    setLength(S, length(Data.Bin[Section].Stream.Data));
    for i := 0 to high(Data.Bin[Section].Stream.Data) do
      S[i + 1] := char(Data.Bin[Section].Stream.Data[i]);
    Doc := DOMFromXML(S);
    CurrElement := TDOMElement(Doc.GetElementsByTagName('light')[0].FirstChild);
    while CurrElement <> nil do
      begin
      if CurrElement.TagName = 'name' then
        fLight.Name := CurrElement.FirstChild.NodeValue
      else if CurrElement.TagName = 'position' then
        begin
        fLight.Position := Vector(StrToFloatWD(CurrElement.GetAttribute('x'), 0.0),
                                  StrToFloatWD(CurrElement.GetAttribute('y'), 0.0),
                                  StrToFloatWD(CurrElement.GetAttribute('z'), 0.0),
                                  1.0);
        fLight.OriginalPosition := fLight.Position;
        end
      else if CurrElement.TagName = 'color' then
        fLight.Color := Vector(StrToFloatWD(CurrElement.GetAttribute('r'), 0.0),
                                  StrToFloatWD(CurrElement.GetAttribute('g'), 0.0),
                                  StrToFloatWD(CurrElement.GetAttribute('b'), 0.0))
      else if CurrElement.TagName = 'factor' then
        fLight.DiffuseFactor := StrToFloatWD(CurrElement.FirstChild.NodeValue, 1.0)
      else if CurrElement.TagName = 'limit' then
        fLight.OnlyNight := CurrElement.GetAttribute('mode') = 'night'
      else if CurrElement.TagName = 'energy' then
        fLight.Energy := StrToFloatWD(CurrElement.FirstChild.NodeValue, 1.0)
      else if CurrElement.TagName = 'falloff' then
        fLight.FalloffDistance := StrToFloatWD(CurrElement.FirstChild.NodeValue, 1.0)
      else if CurrElement.TagName = 'castshadows' then
        fLight.CastShadows := CurrElement.FirstChild.NodeValue = 'true';
      CurrElement := TDOMElement(CurrElement.NextSibling);
      end;
    Doc.Free;
    end;
  FinishedLoading := True;
end;

procedure TLightResource.Free;
begin
  fLight.Free;
  inherited Free;
end;

end.