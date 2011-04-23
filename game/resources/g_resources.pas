unit g_resources;

interface

uses
  SysUtils, Classes, u_linkedlists, g_loader_ocf;

type
  TResourceLoadedProcedure = procedure(Data: TOCFFile) of object;

  TAbstractResource = class(TLinkedListItem)
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
      constructor Create(ResourceName: String; fFileLoaded, fDepsLoaded: TResourceLoadedProcedure);
      procedure Free;
    end;

  TResourceManager = class(TLinkedList)
    protected
      function getResourceByName(Name: String): TAbstractResource;
    public
      property Resources[Name: String]: TAbstractResource read getResourceByName;
      procedure FileLoaded(Event: String; Data, Result: Pointer);
      procedure DepsLoaded(Event: String; Data, Result: Pointer);
      constructor Create;
      procedure Free;
    end;

var
  ResourceManager: TResourceManager = nil;

implementation

uses
  m_varlist, u_files, u_functions, u_events, g_park;

function TAbstractResource.getFullName: String;
begin
  Result := fFileName + '/' + fSubResourceName;
end;

constructor TAbstractResource.Create(ResourceName: String; fFileLoaded, fDepsLoaded: TResourceLoadedProcedure);
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
    EventManager.AddCallback('TAbstractResource.FileLoaded.' + ResourceName, @ResourceManager.FileLoaded);
    ModuleManager.ModOCFManager.RequestOCFFile(fFileName, 'TAbstractResource.FileLoaded.' + ResourceName, self);
    end;

  DepsLoaded := fDepsLoaded;
  FileLoaded := fFileLoaded;
end;

procedure TAbstractResource.Free;
begin
  fDependencies.Free;
  inherited Free;
end;



procedure TResourceManager.FileLoaded(Event: String; Data, Result: Pointer);
begin
  EventManager.RemoveCallback(Event);
  if TAbstractResource(Result).FileLoaded <> nil then
    TAbstractResource(Result).FileLoaded(TOCFFile(Data));
end;

procedure TResourceManager.DepsLoaded(Event: String; Data, Result: Pointer);
begin
  EventManager.RemoveCallback(Event);
  if TAbstractResource(Result).DepsLoaded <> nil then
    TAbstractResource(Result).DepsLoaded(TOCFFile(Data));
end;

function TResourceManager.getResourceByName(Name: String): TAbstractResource;
var
  CurrResource: TAbstractResource;
begin
  CurrResource := TAbstractResource(First);
  Result := nil;
  while CurrResource <> nil do
    begin
    if CurrResource.Name = Name then
      exit(CurrResource);
    CurrResource := TAbstractResource(CurrResource.Next);
    end;
end;

constructor TResourceManager.Create;
begin
  inherited Create;
end;

procedure TResourceManager.Free;
begin
  while First <> nil do
    TAbstractResource(First).Free;
  inherited Free;
end;

end.