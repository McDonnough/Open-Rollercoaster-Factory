unit g_info;

interface

uses
  SysUtils, Classes, m_gui_class;

type
  TGameInfo = class(TXMLUIWindow)
    public
      procedure changeTab(Event: String; Data, Result: Pointer);
      constructor Create(Resource: String; ParkUI: TXMLUI);
      destructor Free;
    end;

implementation

uses
  u_events, main, m_gui_label_class, m_gui_tabbar_class;

procedure TGameInfo.changeTab(Event: String; Data, Result: Pointer);
begin
  TLabel(fWindow.GetChildByName('info.tab.container')).Left := -600 * TTabBar(fWindow.GetChildByName('info.tabbar')).SelectedTab;
end;

constructor TGameInfo.Create(Resource: String; ParkUI: TXMLUI);
begin
  inherited Create(Resource, ParkUI);
  EventManager.AddCallback('GUIActions.info.changeTab', @changeTab);
end;

destructor TGameInfo.Free;
begin
  EventManager.RemoveCallback(@changeTab);
  inherited Free;
end;

end.