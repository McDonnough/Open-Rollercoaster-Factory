unit m_gui_iconifiedbutton_class;

interface

uses
  Classes, SysUtils, m_gui_class, m_module, DGLOpenGL;

type
  TIconifiedButton = class(TGUIComponent)
    protected
      fIcon: String;
      procedure SetIcon(Icon: String);
    public
      fHoverFactor, fClickFactor: GLFloat;
      Caption: String;
      property Icon: String read fIcon write SetIcon;
      constructor Create(mParent: TGUIComponent);
      procedure Render;
    end;

  TModuleGUIIconifiedButtonClass = class(TBasicModule)
    public
      (**
        * Render a button with icon
        *@param button bar to render
        *)
      procedure Render(Button: TIconifiedButton); virtual abstract;

      (**
        * Set the icon for an iconified button
        *@param The button to apply this to
        *@param The icon texture file name
        *)
      procedure SetIcon(Button: TIconifiedButton; Icon: String); virtual abstract;
    end;

implementation

uses
  m_varlist;

constructor TIconifiedButton.Create(mParent: TGUIComponent);
begin
  inherited Create(mParent, CIconifiedButton);
  Caption := '';
  fHoverFactor := 0;
  fClickFactor := 0;
  fIcon := '';
end;

procedure TIconifiedButton.Render;
begin
  ModuleManager.ModGUIIconifiedButton.Render(Self);
end;

procedure TIconifiedButton.SetIcon(Icon: String);
begin
  fIcon := Icon;
  ModuleManager.ModGUIIconifiedButton.SetIcon(Self, Icon);
end;

end.