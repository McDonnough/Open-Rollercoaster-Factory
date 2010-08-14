unit g_loader_park;

interface

uses
  Classes, SysUtils;

type
  TParkLoader = class
    protected
      fFiles: Array of String;
    public
      Visible: Boolean;
      function FileOnList(F: String): Boolean;
      procedure LoadFile(F: String);
      procedure AddFile(F: String);
      procedure Run;
      procedure InitDisplay;
    end;

implementation

uses
  m_varlist, main, g_terrain, g_camera, u_events, g_park;

function TParkLoader.FileOnList(F: String): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 0 to high(fFiles) do
    if fFiles[i] = F then
      Exit(True);
end;

procedure TParkLoader.LoadFile(F: String);
begin
  EventManager.CallEvent('TParkLoader.LoadFile.Start', @F, nil);
  EventManager.CallEvent('TParkLoader.LoadFile.Start.' + F, nil, nil);



  EventManager.CallEvent('TParkLoader.LoadFile.End', @F, nil);
  EventManager.CallEvent('TParkLoader.LoadFile.End.' + F, nil, nil);
end;

procedure TParkLoader.AddFile(F: String);
begin
  if not FileOnList(F) then
    begin
    setLength(fFiles, length(fFiles) + 1);
    fFiles[high(fFiles)] := F;
    end;
end;

procedure TParkLoader.Run;
var
  fTime: UInt64;
  i: Integer;
begin
  fTime := ModuleManager.ModGUITimer.GetTime;

  repeat
    if length(fFiles) > 0 then
      begin
      LoadFile(fFiles[0]);
      for i := 1 to high(fFiles) do
        fFiles[i - 1] := fFiles[i];
      SetLength(fFiles, length(fFiles) - 1);
      end
    else
      EventManager.CallEvent('TParkLoader.LoadFiles.NoFilesLeft', nil, nil);
  until
    ModuleManager.ModGUITimer.GetTime - fTime > 25;

  if not Park.CanRender then
    EventManager.CallEvent('TParkLoader.LoadFiles.RenderStep', nil, nil);

  if Visible then
    ModuleManager.ModLoadscreen.Render;
end;

procedure TParkLoader.InitDisplay;
begin
  Visible := True;
  ModuleManager.ModLoadscreen.Headline := 'Loading files';
  ModuleManager.ModLoadscreen.Progress := 0;
  ModuleManager.ModLoadscreen.SetVisibility(true);
end;

end.