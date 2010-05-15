unit m_gui_window_class;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_module, m_gui_class;

type
  TWindow = class(TGUIComponent)
    public
      OfsX1, OfsX2, OfsY1, OfsY2: Integer;
      procedure Render;
      constructor Create(mParent: TGUIComponent);
    end;

  TModuleGUIWindowClass = class(TBasicModule)
    public
      (**
        * Render it.
        *@param The window to render
        *)
      procedure Render(Window: TWindow); virtual abstract;
    end;

implementation

uses
  m_varlist;

procedure TWindow.Render;
begin
  inherited Render;
  ModuleManager.ModGUIWindow.Render(Self);
end;

constructor TWindow.Create(mParent: TGUIComponent);
begin
  inherited Create(mParent, CWindow);
  OfsX1 := 0;
  OfsX2 := 0;
  OfsY1 := 0;
  OfsY2 := 0;
end;

end.

