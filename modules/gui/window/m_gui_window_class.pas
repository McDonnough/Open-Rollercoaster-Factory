unit m_gui_window_class;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_module, m_gui_class;

type
  TWindow = class(TGUIComponent)
    public
      HasBackground: Boolean;
      OfsX1, OfsX2, OfsY1, OfsY2, ResX, ResY: Integer;
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
  m_varlist, math;

procedure TWindow.Render;
begin
  Rendered := False;
  if (Max(Width, 0) * Max(Height, 0) > 64) and not ((AbsY > ResY + 8) or (AbsY + Height < -8) or (AbsX > ResX + 8) or (AbsX + Width < -8)) then
    begin
    Rendered := True;
    ModuleManager.ModGUIWindow.Render(Self);
    end;
end;

constructor TWindow.Create(mParent: TGUIComponent);
begin
  inherited Create(mParent, CWindow);
  OfsX1 := 0;
  OfsX2 := 0;
  OfsY1 := 0;
  OfsY2 := 0;
  HasBackground := True;
  ModuleManager.ModGLContext.GetResolution(ResX, ResY);
end;

end.

