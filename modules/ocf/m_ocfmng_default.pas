unit m_ocfmng_default;

interface

uses
  SysUtils, Classes, m_ocfmng_class, u_dom, u_xml, g_loader_ocf;

type
  TOCFManagerWorkingThread = class(TThread)
    protected
      fCanWork, fWorking: Boolean;
    public
      property Working: Boolean read fWorking;
      property CanWork: Boolean write fCanWork;
      procedure Execute; override;
      procedure Sync;
    end;

  TModuleOCFManagerDefault = class(TModuleOCFManagerClass)
    protected
      fSignalCounter: Integer;
      fThread: TOCFManagerWorkingThread;
      function AlreadyLoaded(FileName: String): Integer;
    public
      fFileNames: Array of String;
      fOCFFiles: Array of TOCFFile;
      fEvents: Array of String;
      fLoaded: Array of Boolean;
      fAdditionalData: Array of Pointer;
      function FileCount: Integer;
      function LoadedFiles: Integer;
      procedure RequestOCFFile(FileName, Event: String; AdditionalData: Pointer);
      procedure ReloadOCFFile(FileName, Event: String; AdditionalData: Pointer);
      procedure CheckLoaded;
      procedure CheckModConf;
      constructor Create;
      destructor Free;
    end;

implementation

uses
  m_varlist, u_events, u_files;

procedure TOCFManagerWorkingThread.Execute;
var
  i: Integer;
begin
  i := 0;
  fWorking := false;
  fCanWork := false;
  while not Terminated do
    begin
    while (i <= high(ModuleManager.ModOCFManager.fFileNames)) and (fCanWork) do
      begin
      fWorking := true;
      ModuleManager.ModOCFManager.fOCFFiles[i] := TOCFFile.Create(ModuleManager.ModOCFManager.fFileNames[i]);
      ModuleManager.ModOCFManager.fLoaded[i] := true;
      inc(i);
      end;
    fWorking := false;
    sleep(100);
    end;
  writeln('Hint: Terminated OCF loader thread');
end;

procedure TOCFManagerWorkingThread.Sync;
begin
  fCanWork := false;
  while fWorking do
    sleep(10);
end;

function TModuleOCFManagerDefault.FileCount: Integer;
begin
  Result := length(fLoaded);
end;

function TModuleOCFManagerDefault.LoadedFiles: Integer;
begin
  Result := fSignalCounter;
end;

function TModuleOCFManagerDefault.AlreadyLoaded(FileName: String): Integer;
begin
  for Result := 0 to high(fFileNames) do
    if fFileNames[Result] = FileName then
      if fLoaded[Result] then
        exit
      else
        break;
  Result := -1;
end;

procedure TModuleOCFManagerDefault.RequestOCFFile(FileName, Event: String; AdditionalData: Pointer);
var
  i: Integer;
begin
  FileName := GetFirstExistingFileName(FileName);
  i := AlreadyLoaded(FileName);
  if i > -1 then
    EventManager.CallEvent(Event, fOCFFiles[i], AdditionalData)
  else
    begin
    fThread.Sync;
    SetLength(fFileNames, Length(fFileNames) + 1);
    SetLength(fOCFFiles, Length(fOCFFiles) + 1);
    SetLength(fEvents, Length(fEvents) + 1);
    SetLength(fLoaded, Length(fLoaded) + 1);
    SetLength(fAdditionalData, Length(fAdditionalData) + 1);
    fFileNames[high(fFileNames)] := FileName;
    fEvents[high(fEvents)] := Event;
    fAdditionalData[high(fAdditionalData)] := AdditionalData;
    fOCFFiles[high(fOCFFiles)] := nil;
    fLoaded[high(fLoaded)] := false;
    end;
end;

procedure TModuleOCFManager.ReloadOCFFile(FileName, Event: String; AdditionalData: Pointer);
var
  i: Integer;
begin
  FileName := GetFirstExistingFileName(FileName);
  i := AlreadyLoaded(FileName);
  if i > -1 then
    begin
    fFileNames[i] := '';
    fLoaded[i] := false;
    fEvents[i] := '';
    fOCFFiles[i].Free;
    fOCFFiles[i] := nil;
    fAdditionalData[i] := nil;
    end;
  RequestOCFFile(FileName, Event, AdditionalData);
end;

procedure TModuleOCFManagerDefault.CheckLoaded;
begin
  if fSignalCounter <= high(fLoaded) then
    while fLoaded[fSignalCounter] do
      begin
      EventManager.CallEvent(fEvents[fSignalCounter], fOCFFiles[fSignalCounter], fAdditionalData[fSignalCounter]);
      inc(fSignalCounter);
      if fSignalCounter > high(fLoaded) then
        break;
      end;
  fThread.CanWork := True;
end;

constructor TModuleOCFManagerDefault.Create;
begin
  fModName := 'OCFManagerDefault';
  fModType := 'OCFManager';

  fThread := TOCFManagerWorkingThread.Create(true);

  fSignalCounter := 0;
end;

procedure TModuleOCFManagerDefault.CheckModConf;
begin
  fThread.Resume;
end;

destructor TModuleOCFManagerDefault.Free;
var
  i: Integer;
begin
  fThread.Sync;
  for i := 0 to high(fOCFFiles) do
    if fOCFFiles[i] <> nil then
      fOCFFiles[i].Free;
  fThread.Free;
end;

end.