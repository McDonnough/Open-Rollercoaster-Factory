unit g_resources;

interface

uses
  SysUtils, Classes, u_linkedlists, g_loader_ocf;

type
  TResourceLoadedProcedure = procedure(Data: TOCFFile) of object;

  TAbstractResource = class(TLinkedListItem)
    private
      fOCFFile: TOCFFile;
    protected
      fFileName: String;
      fSubResourceName: String;
      fDependencies: TStringList;
      fFinishedLoading: Boolean;
      function getFullName: String;
      procedure setFinishedLoading(B: Boolean);
    public
      FileLoaded: TResourceLoadedProcedure;
      property OCFFile: TOCFFile read fOCFFile;
      property FileName: String read fFileName;
      property SubResourceName: String read fSubResourceName;
      property Name: String read getFullName;
      property FinishedLoading: Boolean read fFinishedLoading write setFinishedLoading;
      constructor Create(ResourceName: String; fFileLoaded: TResourceLoadedProcedure);
      procedure Free;
    end;

  TResourceManager = class(TLinkedList)
    protected
      fNotificationsRemaining: Array of TAbstractResource;
      function getResourceByName(Name: String): TAbstractResource;
    public
      property Resources[Name: String]: TAbstractResource read getResourceByName;
      procedure AddFinishedResource(Resource: TAbstractResource);
      procedure Notify;
      procedure FileLoaded(Event: String; Data, Result: Pointer);
      constructor Create;
      procedure Free;
    end;

var
  ResourceManager: TResourceManager = nil;

implementation

uses
  m_varlist, u_files, u_functions, u_events;

procedure TAbstractResource.setFinishedLoading(B: Boolean);
begin
  if not fFinishedLoading then
    begin
    fFinishedLoading := B;
    if fFinishedLoading then
      ResourceManager.AddFinishedResource(Self);
    end;
end;

function TAbstractResource.getFullName: String;
begin
  Result := fFileName + '/' + fSubResourceName;
end;

constructor TAbstractResource.Create(ResourceName: String; fFileLoaded: TResourceLoadedProcedure);
var
  A: AString;
  i: Integer;
begin
  inherited Create;
  writeln('Hint: Loading resource ' + ResourceName);
  fFinishedLoading := False;
  fDependencies := TStringList.Create;
  fFileName := '';
  fSubResourceName := '';
  fOCFFile := nil;

  A := Explode('/', ResourceName);

  i := 0;
  for i := 0 to high(A) do
    if (getFirstExistingFileName(fFileName) = '') or (directoryExists(getFirstExistingFileName(fFileName))) then
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
  FileLoaded := fFileLoaded;
  if getFirstExistingFileName(fFileName) <> '' then
    begin
    EventManager.AddCallback('TAbstractResource.FileLoaded.' + ResourceName, @ResourceManager.FileLoaded);
    ModuleManager.ModOCFManager.RequestOCFFile(fFileName, 'TAbstractResource.FileLoaded.' + ResourceName, self);
    end;

  ResourceManager.Append(Self);
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
    try
      TAbstractResource(Result).fOCFFile := TOCFFile(Data);
      TAbstractResource(Result).FileLoaded(TOCFFile(Data));
    except
      ModuleManager.ModLog.AddError('Loading resource ' + TAbstractResource(Result).Name + ' failed');
    end;
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

procedure TResourceManager.AddFinishedResource(Resource: TAbstractResource);
var
  I: Integer;
begin
  setLength(fNotificationsRemaining, length(fNotificationsRemaining) + 1);
  fNotificationsRemaining[high(fNotificationsRemaining)] := Resource;
end;

procedure TResourceManager.Notify;
var
  i, j: Integer;
begin
  i := 0;
  while i <= high(fNotificationsRemaining) do
    begin
    EventManager.CallEvent('TResource.FinishedLoading:' + fNotificationsRemaining[i].Name, fNotificationsRemaining[i], nil);
    EventManager.RemoveCallback('TResource.FinishedLoading:' + fNotificationsRemaining[i].Name);
    inc(i);
    end;
  setLength(fNotificationsRemaining, 0);
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