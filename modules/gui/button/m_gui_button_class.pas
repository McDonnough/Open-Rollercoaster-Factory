unit m_gui_button_class;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_module, m_gui_class, DGLOpenGL;

type
  TButton = class(TGUIComponent)
    public
      fHoverFactor, fClickFactor: GLFloat;
      Caption: String;
      constructor Create(mParent: TGUIComponent);
      procedure Render;
    end;

  TModuleGUIButtonClass = class(TBasicModule)
    public
      (**
        * Render a button
        *@param button bar to render
        *)
      procedure Render(Button: TButton); virtual abstract;
    end;

implementation

uses
  m_varlist;

constructor TButton.Create(mParent: TGUIComponent);
begin
  inherited Create(mParent, CButton);
  Caption := '';
  fHoverFactor := 0;
  fClickFactor := 0;
end;

procedure TButton.Render;
begin
  ModuleManager.ModGUIButton.Render(Self);
end;

end.