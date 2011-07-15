unit g_selection_mode;

interface

uses
  SysUtils, Classes, g_parkui;

type
  TGameSelectionModeWindow = class(TXMLUIWindow)
    public
      procedure OnShow(Event: String; Data, Result: Pointer);
      procedure OnClose(Event: String; Data, Result: Pointer);
      procedure OnChange(Event: String; Data, Result: Pointer);
      procedure KeyDown(Event: String; Data, Result: Pointer);
      constructor Create(Resource: String; ParkUI: TXMLUIManager);
      destructor Free;
    end;

implementation

uses
  u_events, main, m_gui_label_class, m_gui_iconifiedbutton_class, g_park, m_gui_class, m_inputhandler_class;

procedure TGameSelectionModeWindow.KeyDown(Event: String; Data, Result: Pointer);
begin
  case Integer(Result^) of
    K_1: OnChange('', fWindow.GetChildByName('selection_mode.normalselection'), nil);
    K_2: OnChange('', fWindow.GetChildByName('selection_mode.noselection'), nil);
    K_3: OnChange('', fWindow.GetChildByName('selection_mode.deleteselection'), nil);
    end;
end;

procedure TGameSelectionModeWindow.OnChange(Event: String; Data, Result: Pointer);
begin
  Button.fClickFactor := 1;
  if TGUIComponent(Data) = fWindow.GetChildByName('selection_mode.normalselection') then Park.SelectionMode := S_DEFAULT_SELECTION;
  if TGUIComponent(Data) = fWindow.GetChildByName('selection_mode.noselection') then Park.SelectionMode := S_NO_SELECTION;
  if TGUIComponent(Data) = fWindow.GetChildByName('selection_mode.deleteselection') then Park.SelectionMode := S_REMOVE_SELECTION;
  if Park.SelectionMode = S_NO_SELECTION then
    Park.SelectionEngine := nil
  else
    Park.SelectionEngine := Park.NormalSelectionEngine;
  case Park.SelectionMode of
    S_NO_SELECTION:      Button.Icon := TIconifiedButton(fWindow.GetChildByName('selection_mode.noselection')).Icon;
    S_DEFAULT_SELECTION: Button.Icon := TIconifiedButton(fWindow.GetChildByName('selection_mode.normalselection')).Icon;
    S_REMOVE_SELECTION:  Button.Icon := TIconifiedButton(fWindow.GetChildByName('selection_mode.deleteselection')).Icon;
    end;
  Hide(TGUIComponent(Data));
end;

procedure TGameSelectionModeWindow.OnShow(Event: String; Data, Result: Pointer);
begin
  TIconifiedButton(fWindow.GetChildByName('selection_mode.normalselection')).Top := 0;
  TIconifiedButton(fWindow.GetChildByName('selection_mode.normalselection')).Left := 0;
  TIconifiedButton(fWindow.GetChildByName('selection_mode.normalselection')).Alpha := 1;
  TIconifiedButton(fWindow.GetChildByName('selection_mode.noselection')).Top := 52;
  TIconifiedButton(fWindow.GetChildByName('selection_mode.noselection')).Alpha := 1;
  TIconifiedButton(fWindow.GetChildByName('selection_mode.deleteselection')).Top := 104;
  TIconifiedButton(fWindow.GetChildByName('selection_mode.deleteselection')).Left := 0;
  TIconifiedButton(fWindow.GetChildByName('selection_mode.deleteselection')).Alpha := 1;
end;

procedure TGameSelectionModeWindow.OnClose(Event: String; Data, Result: Pointer);
begin
  TIconifiedButton(fWindow.GetChildByName('selection_mode.normalselection')).Top := 0;
  TIconifiedButton(fWindow.GetChildByName('selection_mode.normalselection')).Left := 8;
  TIconifiedButton(fWindow.GetChildByName('selection_mode.normalselection')).Alpha := 0;
  TIconifiedButton(fWindow.GetChildByName('selection_mode.noselection')).Alpha := 0;
  TIconifiedButton(fWindow.GetChildByName('selection_mode.noselection')).Top := 0;
  TIconifiedButton(fWindow.GetChildByName('selection_mode.deleteselection')).Top := 0;
  TIconifiedButton(fWindow.GetChildByName('selection_mode.deleteselection')).Left := 8;
  TIconifiedButton(fWindow.GetChildByName('selection_mode.deleteselection')).Alpha := 0;
end;

constructor TGameSelectionModeWindow.Create(Resource: String; ParkUI: TXMLUIManager);
begin
  inherited Create(Resource, ParkUI);
  EventManager.AddCallback('GUIActions.selection_mode.open', @OnShow);
  EventManager.AddCallback('GUIActions.selection_mode.close', @OnClose);
  EventManager.AddCallback('GUIActions.selection_mode.changed', @OnChange);
  EventManager.AddCallback('BasicComponent.OnKeyDown', @KeyDown);
end;

destructor TGameSelectionModeWindow.Free;
begin
  EventManager.RemoveCallback(@KeyDown);
  EventManager.RemoveCallback(@OnShow);
  EventManager.RemoveCallback(@OnClose);
  EventManager.RemoveCallback(@OnChange);
  inherited Free;
end;

end.