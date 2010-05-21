unit g_leave;

interface

uses
  SysUtils, Classes;

type
  TGameLeaveActions = class
    public
    procedure doQuit(Event: String; Data, Result: Pointer);
    constructor Create;
    destructor Free;
    end;

implementation

uses
  u_events, main;

procedure TGameLeaveActions.doQuit(Event: String; Data, Result: Pointer);
begin
  changeRenderState(rsMainMenu);
end;

constructor TGameLeaveActions.Create;
begin
  EventManager.AddCallback('GUIActions.doQuit', @doQuit);
end;

destructor TGameLeaveActions.Free;
begin
  EventManager.RemoveCallback(@doQuit);
end;

end.