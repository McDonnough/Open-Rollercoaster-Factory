unit g_selection_mode;

interface

uses
  SysUtils, Classes, g_parkui;

type
  TGameSelectionModeWindow = class(TXMLUIWindow)
    public
      constructor Create(Resource: String; ParkUI: TXMLUIManager);
      destructor Free;
    end;

implementation

uses
  u_events, main, m_gui_label_class, m_gui_iconifiedbutton_class;

constructor TGameSelectionModeWindow.Create(Resource: String; ParkUI: TXMLUIManager);
begin
  inherited Create(Resource, ParkUI);
end;

destructor TGameSelectionModeWindow.Free;
begin
  inherited Free;
end;

end.