unit g_leave;

interface

uses
  SysUtils, Classes, g_parkui;

type
  TGameLeave = class(TParkUIWindow)
    public
      procedure doQuit(Event: String; Data, Result: Pointer);
      constructor Create(Resource: String; ParkUI: TParkUI);
      destructor Free;
    end;

implementation

uses
  u_events, main;

procedure TGameLeave.doQuit(Event: String; Data, Result: Pointer);
begin
  changeRenderState(rsMainMenu);
end;

constructor TGameLeave.Create(Resource: String; ParkUI: TParkUI);
begin
  inherited Create(Resource, ParkUI);
  EventManager.AddCallback('GUIActions.doQuit', @doQuit);
end;

destructor TGameLeave.Free;
begin
  EventManager.RemoveCallback(@doQuit);
  inherited Free;
end;

end.