unit m_gui_checkbox_class;

interface

uses
  SysUtils, Classes, m_module, m_gui_class, DGLOpenGL;

type
  TCheckBox = class(TGUIComponent)
    public
      fHoverFactor, fClickFactor: GLFloat;
      Checked: Boolean;
      OnChange: TCallbackProcedure;
      procedure Clicked(Sender: TGUIComponent);
      constructor Create(mParent: TGUIComponent);
      procedure Render; override;
    end;

  TModuleGUICheckBoxClass = class(TBasicModule)
    public
      (**
        * Render a button
        *@param checkbox to render
        *)
      procedure Render(Checkbox: TCheckBox); virtual abstract;
    end;

implementation

uses
  m_varlist;

constructor TCheckbox.Create(mParent: TGUIComponent);
begin
  inherited Create(mParent, CCheckBox);
  Checked := false;
  fHoverFactor := 0;
  fClickFactor := 0;
  OnClick := @Clicked;
  OnChange := nil;
end;

procedure TCheckbox.Clicked(Sender: TGUIComponent);
begin
  Checked := not Checked;
  if OnChange <> nil then
    OnChange(Sender);
end;

procedure TCheckbox.Render;
begin
  ModuleManager.ModGUICheckBox.Render(self);
end;

end.