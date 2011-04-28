unit g_res_pathes;

interface

uses
  SysUtils, Classes, u_pathes, g_resources, g_loader_ocf;

type
  TPathResource = class(TAbstractResource)
    protected
      fPath: TPath;
    public
      property Path: TPath read fPath;
      class function Get(ResourceName: String): TPathResource;
      constructor Create(ResourceName: String);
      procedure FileLoaded(Data: TOCFFile);
      procedure Free;
    end;

implementation

uses
  u_events, u_vectors, u_dom, u_xml, u_functions;

class function TPathResource.Get(ResourceName: String): TPathResource;
begin
  Result := TPathResource(ResourceManager.Resources[ResourceName]);
  if Result = nil then
    Result := TPathResource.Create(ResourceName)
  else
    ResourceManager.AddFinishedResource(Result);
end;

constructor TPathResource.Create(ResourceName: String);
begin
  fPath := TPath.Create;
  inherited Create(ResourceName, @FileLoaded);
end;

procedure TPathResource.FileLoaded(Data: TOCFFile);
  procedure AddPoint(Element: TDOMElement);
  var
    CurrElement: TDOMElement;
    Point: TBezierPoint;
  begin
    Point := fPath.AddPoint;

    CurrElement := TDOMElement(Element.FirstChild);

    while CurrElement <> nil do
      begin
      if CurrElement.TagName = 'cp1' then
        Point.CP1 := Vector(StrToFloatWD(CurrElement.GetAttribute('x'), 0), StrToFloatWD(CurrElement.GetAttribute('y'), 0), StrToFloatWD(CurrElement.GetAttribute('z'), 0))
      else if CurrElement.TagName = 'cp2' then
        Point.CP2 := Vector(StrToFloatWD(CurrElement.GetAttribute('x'), 0), StrToFloatWD(CurrElement.GetAttribute('y'), 0), StrToFloatWD(CurrElement.GetAttribute('z'), 0))
      else if CurrElement.TagName = 'pos' then
        Point.Position := Vector(StrToFloatWD(CurrElement.GetAttribute('x'), 0), StrToFloatWD(CurrElement.GetAttribute('y'), 0), StrToFloatWD(CurrElement.GetAttribute('z'), 0))
      else if CurrElement.TagName = 'banking' then
        begin
        Point.IgnoreBankingAfter := CurrElement.GetAttribute('ignoreafter') = 'true';
        Point.Banking := StrToFloatWD(CurrElement.FirstChild.NodeValue, 0);
        end;
      CurrElement := TDOMElement(CurrElement.NextSibling);
      end;
  end;

var
  Doc: TDOMDocument;
  CurrElement: TDOMElement;
  S: String;
  i: Integer;
begin
  with Data.ResourceByName(SubResourceName) do
    begin
    setLength(S, length(Data.Bin[Section].Stream.Data));
    for i := 0 to high(Data.Bin[Section].Stream.Data) do
      S[i + 1] := char(Data.Bin[Section].Stream.Data[i]);
    Doc := DOMFromXML(S);
    CurrElement := TDOMElement(Doc.GetElementsByTagName('path')[0]);
    fPath.Closed := CurrElement.GetAttribute('closed') = 'true';
    CurrElement := TDOMElement(CurrElement.FirstChild);
    while CurrElement <> nil do
      begin
      if CurrElement.TagName = 'name' then
        fPath.Name := CurrElement.FirstChild.NodeValue
      else if CurrElement.TagName = 'point' then
        AddPoint(CurrElement);
        
      CurrElement := TDOMElement(CurrElement.NextSibling);
      end;
    Doc.Free;
    end;
  fPath.BuildLookupTable;

  FinishedLoading := True;
end;

procedure TPathResource.Free;
begin
  fPath.Free;
  inherited Free;
end;

end.