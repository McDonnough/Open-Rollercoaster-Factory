unit g_park_settings;

interface

uses
  SysUtils, Classes, u_events, g_park, g_parkui;

type
  TGameParkSettings = class(TXMLUIWindow)
    protected
    public
      procedure ChangeTab(Event: String; Data, Result: Pointer);
      procedure ChangeParkData(Event: String; Data, Result: Pointer);
      constructor Create(Resource: String; ParkUI: TXMLUIManager);
      destructor Free;
    end;

implementation

uses
  m_gui_label_class, m_gui_edit_class, m_gui_tabbar_class, m_gui_button_class, m_gui_iconifiedbutton_class;

procedure TGameParkSettings.ChangeTab(Event: String; Data, Result: Pointer);
begin
  TLabel(fWindow.GetChildByName('park_settings.tab.container')).Left := -384 * TTabBar(fWindow.GetChildByName('park_settings.tabbar')).SelectedTab;
end;

procedure TGameParkSettings.ChangeParkData(Event: String; Data, Result: Pointer);
begin
  Park.fName := TEdit(fWindow.GetChildByName('park_settings.name')).Text;
  Park.fDescription := TEdit(fWindow.GetChildByName('park_settings.description')).Text;
  Park.fAuthor := TEdit(fWindow.GetChildByName('park_settings.author')).Text;
end;

constructor TGameParkSettings.Create(Resource: String; ParkUI: TXMLUIManager);
begin
  inherited Create(Resource, ParkUI);
  TEdit(fWindow.GetChildByName('park_settings.name')).Text := Park.fName;
  TEdit(fWindow.GetChildByName('park_settings.description')).Text := Park.fDescription;
  TEdit(fWindow.GetChildByName('park_settings.author')).Text := Park.fAuthor;
  EventManager.AddCallback('GUIActions.park_settings.changeTab', @ChangeTab);
  EventManager.AddCallback('GUIActions.park_settings.change_name', @ChangeParkData);
  EventManager.AddCallback('GUIActions.park_settings.change_description', @ChangeParkData);
  EventManager.AddCallback('GUIActions.park_settings.change_author', @ChangeParkData);
end;

destructor TGameParkSettings.Free;
begin
  EventManager.RemoveCallback(@ChangeParkData);
  EventManager.RemoveCallback(@ChangeTab);
  inherited Free;
end;

end.