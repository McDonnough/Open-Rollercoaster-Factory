unit g_terrain_edit;

interface

uses
  SysUtils, Classes, g_parkui;

type
  TGameTerrainEdit = class(TParkUIWindow)
    public
      procedure changeTab(Event: String; Data, Result: Pointer);
      constructor Create(Resource: String; ParkUI: TParkUI);
      destructor Free;
    end;

implementation

uses
  u_events, main, m_gui_label_class, m_gui_tabbar_class;

procedure TGameTerrainEdit.changeTab(Event: String; Data, Result: Pointer);
begin
  TLabel(fWindow.GetChildByName('terrain_edit.tab.container')).Left := -750 * TTabBar(fWindow.GetChildByName('terrain_edit.tabbar')).SelectedTab;
end;

constructor TGameTerrainEdit.Create(Resource: String; ParkUI: TParkUI);
begin
  inherited Create(Resource, ParkUI);
  EventManager.AddCallback('GUIActions.terrain_edit.changeTab', @changeTab);
end;

destructor TGameTerrainEdit.Free;
begin
  EventManager.RemoveCallback(@changeTab);
  inherited Free;
end;

end.