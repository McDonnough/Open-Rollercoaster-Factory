unit g_res_scripts;

interface

uses
  SysUtils, Classes, u_scripts, g_resources, g_loader_ocf, dglOpenGL;

type
  TScriptResource = class(TAbstractResource)
    protected
      fScriptCode: TScriptCode;
    public
      property ScriptCode: TScriptCode read fScriptCode;
      class function Get(ResourceName: String): TScriptResource;
      constructor Create(ResourceName: String);
      procedure FileLoaded(Data: TOCFFile);
      procedure Free;
    end;

implementation

uses
  u_graphics, u_events;

class function TScriptResource.Get(ResourceName: String): TScriptResource;
begin
  Result := TScriptResource(ResourceManager.Resources[ResourceName]);
  if Result = nil then
    Result := TScriptResource.Create(ResourceName)
  else
    ResourceManager.AddFinishedResource(Result);
end;

constructor TScriptResource.Create(ResourceName: String);
begin
  fScriptCode := nil;
  inherited Create(ResourceName, @FileLoaded);
end;

procedure TScriptResource.FileLoaded(Data: TOCFFile);
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

    fScriptCode := TScriptCode.Create(S);
    fScriptCode.Name := Name;
    end;
  FinishedLoading := True;
end;

procedure TScriptResource.Free;
begin
  fScriptCode.Free;
  inherited Free;
end;

end.