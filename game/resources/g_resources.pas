unit g_resources;

interface

uses
  SysUtils, Classes, u_linkedlists, g_loader_ocf;

type
  TResourceLoadedProcedure = procedure(Data: TOCFFile) of object;

  TOCFResource = class(TLinkedListItem)
    protected
      fOCFFile: TOCFFile;
      fFileName: String;
      fSubResourceName: String;
      fDependencies: TStringList;
      function getFullName: String;
    public
      FileLoaded, DepsLoaded: TResourceLoadedProcedure;
      property FileName: String read fFileName;
      property SubResourceName: String read fSubResourceName;
      property Name: String read getFullName;
      constructor Create(ResourceName: String);
      procedure Free;
    end;

  TResourceManager = class(TLinkedList)
    protected
      function getResourceByName(Name: String): TOCFResource;
    public
      property Resources[Name: String]: TOCFResource read getResourceByName;
      procedure FileLoaded(Event: String; Data, Result: Pointer);
      procedure DepsLoaded(Event: String; Data, Result: Pointer);
      constructor Create;
      procedure Free;
    end;

implementation

uses
  m_varlist, u_files, u_functions, u_events, g_park;

function TOCFResource.getFullName: String;
begin
  Result := fFileName + '/' + fSubResourceName;
end;

constructor TOCFResource.Create(ResourceName: String);
var
  A: AString;
  i: Integer;
begin
  inherited Create;
  fDependencies := TStringList.Create;
  fFileName := '';
  fSubResourceName := '';
  fOCFFile := nil;

  A := Explode('/', ResourceName);

  i := 0;
  for i := 0 to high(A) do
    if getFirstExistingFileName(fFileName) = '' then
      begin
      if fFileName <> '' then
        fFileName := fFileName + '/';
      fFileName := fFileName + A[i];
      end
    else
      begin
      if fSubResourceName <> '' then
        fSubResourceName := fSubResourceName + '/';
      fSubResourceName := fSubResourceName + A[i];
      end;
  if getFirstExistingFileName(fFileName) <> '' then
    begin
    EventManager.AddCallback('TOCFResource.FileLoaded.' + ResourceName, @Park.ResourceManager.FileLoaded);
    ModuleManager.ModOCFManager.RequestOCFFile(fFileName, 'TOCFResource.FileLoaded.' + ResourceName, self);
    end;

  DepsLoaded := nil;
  FileLoaded := nil;
end;

procedure TOCFResource.Free;
begin
  fDependencies.Free;
  inherited Free;
end;



procedure TResourceManager.FileLoaded(Event: String; Data, Result: Pointer);
begin
  EventManager.RemoveCallback(Event);
  if TOCFResource(Result).FileLoaded <> nil then
    TOCFResource(Result).FileLoaded(TOCFFile(Data));
end;

procedure TResourceManager.DepsLoaded(Event: String; Data, Result: Pointer);
begin
  EventManager.RemoveCallback(Event);
  if TOCFResource(Result).DepsLoaded <> nil then
    TOCFResource(Result).DepsLoaded(TOCFFile(Data));
end;

function TResourceManager.getResourceByName(Name: String): TOCFResource;
var
  CurrResource: TOCFResource;
begin
  CurrResource := TOCFResource(First);
  Result := nil;
  while CurrResource <> nil do
    begin
    if CurrResource.Name = Name then
      exit(CurrResource);
    CurrResource := TOCFResource(CurrResource.Next);
    end;
end;

constructor TResourceManager.Create;
begin
  inherited Create;
end;

procedure TResourceManager.Free;
var
  CurrResource, NextResource: TOCFResource;
begin
  CurrResource := TOCFResource(First);
  while CurrResource <> nil do
    begin
    NextResource := TOCFResource(CurrResource.Next);
    CurrResource.Free;
    CurrResource := NextResource;
    end;
  inherited Free;
end;

end.