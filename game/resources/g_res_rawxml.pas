unit g_res_rawxml;

interface

uses
  SysUtils, Classes, u_dom, u_xml, g_resources, g_loader_ocf, dglOpenGL;

type
  TRawXMLResource = class(TAbstractResource)
    protected
      fDoc: TDOMDocument;
    public
      property Document: TDOMDocument read fDoc;
      class function Get(ResourceName: String): TRawXMLResource;
      constructor Create(ResourceName: String);
      procedure FileLoaded(Data: TOCFFile);
      procedure Free;
    end;

implementation

uses
  u_graphics, u_events;

class function TRawXMLResource.Get(ResourceName: String): TRawXMLResource;
begin
  Result := TRawXMLResource(ResourceManager.Resources[ResourceName]);
  if Result = nil then
    Result := TRawXMLResource.Create(ResourceName)
  else
    ResourceManager.AddFinishedResource(Result);
end;

constructor TRawXMLResource.Create(ResourceName: String);
begin
  fDoc := nil;
  inherited Create(ResourceName, @FileLoaded);
end;

procedure TRawXMLResource.FileLoaded(Data: TOCFFile);
var
  A: TTexImage;
  CompressedTexFormat, TexFormat: GLEnum;
  S: String;
  i: Integer;
begin
  with Data.ResourceByName(SubResourceName) do
    begin
    setLength(S, length(Data.Bin[Section].Stream.Data));
    for i := 0 to high(Data.Bin[Section].Stream.Data) do
      S[i + 1] := char(Data.Bin[Section].Stream.Data[i]);
    fDoc := DOMFromXML(S);
    end;
  FinishedLoading := True;
end;

procedure TRawXMLResource.Free;
begin
  if fDoc <> nil then
    fDoc.Free;
  inherited Free;
end;

end.