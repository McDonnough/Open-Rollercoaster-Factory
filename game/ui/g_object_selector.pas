unit g_object_selector;

interface

uses
  SysUtils, Classes, u_events, g_park, g_parkui;

type
  TGameObjectSelector = class(TXMLUIWindow)
    protected
    public
      constructor Create(Resource: String; ParkUI: TXMLUIManager);
      destructor Free;
    end;

implementation

uses
  m_gui_label_class, m_gui_edit_class, m_gui_tabbar_class, m_gui_button_class, m_gui_iconifiedbutton_class;

constructor TGameObjectSelector.Create(Resource: String; ParkUI: TXMLUIManager);
begin
  inherited Create(Resource, ParkUI);
end;

destructor TGameObjectSelector.Free;
begin
  inherited Free;
end;

end.