unit m_gui_timer_default;

interface

uses
  SysUtils, Classes, m_gui_timer_class;

type
  TModuleGUITimerDefault = class(TModuleGUITimerClass)
    public
      function GetTime: UInt64;
      function GetTimeDifference(Time: UInt64): UInt64;
      procedure CheckModConf;
      constructor Create;
    end;

implementation

uses
  {$IFDEF WINDOWS}Windows{$ELSE}Unix{$ENDIF};

function TModuleGUITimerDefault.GetTime: UInt64;
begin
  {$IFDEF WINDOWS}
    Result := GetTickCount * 10; /// TODO: Find better solution
  {$ELSE}
    Result := DWord(Trunc(Now * 24 * 60 * 60 * 10000));
  {$ENDIF}
end;

function TModuleGUITimerDefault.GetTimeDifference(Time: UInt64): UInt64;
begin
  Result := GetTime - Time;
end;

procedure TModuleGUITimerDefault.CheckModConf;
begin
end;

constructor TModuleGUITimerDefault.Create;
begin
  fModName := 'GUITimerDefault';
  fModType := 'GUITimer';
end;


end.