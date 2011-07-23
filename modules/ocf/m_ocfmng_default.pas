unit m_ocfmng_default;

interface

uses
  SysUtils, Classes, m_ocfmng_class, u_dom, u_xml, g_loader_ocf;

type
  TOCFManagerWorkingThread = class(TThread)
    protected
      fCanWork, fWorking: Boolean;
    private
      fIDs: Array of Integer;
      i: Integer;
    public
      property Working: Boolean read fWorking;
      property CanWork: Boolean write fCanWork;
      procedure Execute; override;
      procedure Sync;
    end;

  TModuleOCFManagerDefault = class(TModuleOCFManagerClass)
    protected
      fSignalCounter: Integer;
      fThreads: Array of TOCFManagerWorkingThread;
      function AlreadyLoaded(FileName: String): Integer;
    private
      fAdditionalData: Array of Pointer;
      fFileNames: Array of String;
      fOCFFiles: Array of TOCFFile;
      fEvents: Array of String;
      fLoaded: Array of Boolean;
    public
      function FileCount: Integer;
      function LoadedFiles: Integer;
      procedure RequestOCFFile(FileName, Event: String; AdditionalData: Pointer);
      procedure ReloadOCFFile(FileName, Event: String; AdditionalData: Pointer);
      procedure CheckLoaded;
      procedure CheckModConf;
      function FileAlreadyLoaded(FileName: String): Boolean;
      procedure __Loaded(Event: String; Data, Result: Pointer);
      constructor Create;
      destructor Free;
    end;

implementation

uses
  m_varlist, u_events, u_files;

procedure TOCFManagerWorkingThread.Execute;
begin
  i := 0;
  fWorking := false;
  fCanWork := false;
  while not Terminated do
    begin
    while (i <= high(fIDs)) and (fCanWork) do
      begin
      fWorking := true;
      ModuleManager.ModOCFManager.fOCFFiles[fIDs[i]] := TOCFFile.Create(ModuleManager.ModOCFManager.fFileNames[fIDs[i]]);
      ModuleManager.ModOCFManager.fLoaded[fIDs[i]] := true;
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
  FoundThread: TOCFManagerWorkingThread;
  MinIDsToGo: Integer;
begin
  FileName := GetFirstExistingFileName(FileName);
  i := AlreadyLoaded(FileName);
  if i > -1 then
    EventManager.CallEvent(Event, fOCFFiles[i], AdditionalData)
  else
    begin
    FoundThread := nil;
    for I := 0 to high(fThreads) do
      if not fThreads[i].Working then
        begin
        FoundThread := fThreads[i];
        break;
        end;
    if FoundThread = nil then
      begin
      if length(fThreads) < 4 then
        begin
        FoundThread := TOCFManagerWorkingThread.Create(false);
        SetLength(fThreads, length(fThreads) + 1);
        fThreads[high(fThreads)] := FoundThread;
        end
      else
        begin
        FoundThread := fThreads[0];
        MinIDsToGo := high(fThreads[0].fIDs) - fThreads[0].i;
        for I := 1 to high(fThreads) do
          if high(fThreads[i].fIDs) - fThreads[i].i < MinIDsToGo then
            begin
            MinIDsToGo := high(fThreads[i].fIDs) - fThreads[i].i;
            FoundThread := fThreads[i];
            end;
        end;
      end;
    FoundThread.CanWork := False;
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
    SetLength(FoundThread.fIDs, length(FoundThread.fIDs) + 1);
    FoundThread.fIDs[high(FoundThread.fIDs)] := high(fLoaded);
    FoundThread.CanWork := True;
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
var
  I: Integer;
begin
  if fSignalCounter <= high(fLoaded) then
    if fLoaded[fSignalCounter] then
      begin
      EventManager.CallEvent(fEvents[fSignalCounter], fOCFFiles[fSignalCounter], fAdditionalData[fSignalCounter]);
      inc(fSignalCounter);
//       if fSignalCounter > high(fLoaded) then
//         break;
      end;
  for I := 0 to high(fThreads) do 
    fThreads[i].CanWork := True;
end;

function TModuleOCFManagerDefault.FileAlreadyLoaded(FileName: String): Boolean;
begin
  FileName := GetFirstExistingFileName(FileName);
  Result := AlreadyLoaded(FileName) > -1;
end;

constructor TModuleOCFManagerDefault.Create;
begin
  fModName := 'OCFManagerDefault';
  fModType := 'OCFManager';

  EventManager.AddCallback('TOCFManager.Loaded', @__Loaded);

  setLength(fThreads, 1);
  fThreads[0] := TOCFManagerWorkingThread.Create(true);

  fSignalCounter := 0;
end;

procedure TModuleOCFManagerDefault.CheckModConf;
begin
  fThreads[0].Resume;
end;

procedure TModuleOCFManagerDefault.__Loaded(Event: String; Data, Result: Pointer);
begin
  TOCFFile(Result^) := TOCFFile(Data);
end;

destructor TModuleOCFManagerDefault.Free;
var
  i: Integer;
begin
  for i := 0 to high(fThreads) do
    fThreads[i].Sync;
  for i := 0 to high(fOCFFiles) do
    if fOCFFiles[i] <> nil then
      fOCFFiles[i].Free;
  for i := 0 to high(fThreads) do
    fThreads[i].Free;
  EventManager.RemoveCallback(@__Loaded);
end;

end.