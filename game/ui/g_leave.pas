unit g_leave;

interface

uses
  SysUtils, Classes, g_parkui, u_dialogs;

type
  TGameLeave = class(TXMLUIWindow)
    protected
      fFD: TFileDialog;
    public
      procedure doQuit(Event: String; Data, Result: Pointer);
      procedure SaveGame(Event: String; Data, Result: Pointer);
      procedure FinalSaveGame(Event: String; Data, Result: Pointer);
      constructor Create(Resource: String; ParkUI: TXMLUIManager);
      destructor Free;
    end;

implementation

uses
  u_events, main, g_park;

procedure TGameLeave.doQuit(Event: String; Data, Result: Pointer);
begin
  changeRenderState(rsMainMenu);
end;

procedure TGameLeave.SaveGame(Event: String; Data, Result: Pointer);
begin
  fFD := TFileDialog.Create(false, 'saved', 'Save game');
  EventManager.AddCallback('TFileDialog.Selected', @FinalSaveGame);
  EventManager.AddCallback('TFileDialog.Aborted', @FinalSaveGame);
end;

procedure TGameLeave.FinalSaveGame(Event: String; Data, Result: Pointer);
begin
  if Event = 'TFileDialog.Selected' then
    Park.SaveTo(String(Data^));
  EventManager.RemoveCallback(@FinalSaveGame);
  fFD.Free;
  fFD := nil;
  if Event = 'TFileDialog.Selected' then
    doQuit(Event, nil, nil);
end;

constructor TGameLeave.Create(Resource: String; ParkUI: TXMLUIManager);
begin
  inherited Create(Resource, ParkUI);
  fFD := nil;
  EventManager.AddCallback('GUIActions.leave.doQuit', @doQuit);
  EventManager.AddCallback('GUIActions.leave.saveGame', @saveGame);
end;

destructor TGameLeave.Free;
begin
  if fFD <> nil then
    fFD.Free;
  EventManager.RemoveCallback(@doQuit);
  EventManager.RemoveCallback(@saveGame);
  EventManager.RemoveCallback(@FinalSaveGame);
  inherited Free;
end;

end.