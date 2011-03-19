unit m_gui_checkbox_default;

interface

uses
  SysUtils, Classes, m_gui_checkbox_class, m_texmng_class, DGLOpenGL;

type
  TModuleGUICheckBoxDefault = class(TModuleGUICheckBoxClass)
    protected
      fTexture: TTexture;
    public
      constructor Create;
      destructor Free;
      procedure CheckModConf;
      procedure Render(CheckBox: TCheckBox);
    end;

implementation

uses
  m_varlist, math;

constructor TModuleGUICheckBoxDefault.Create;
begin
  fModName := 'GUICheckBoxDefault';
  fModType := 'GUICheckBox';

  CheckModConf;

  fTexture := TTexture.Create;
  fTexture.FromFile(GetConfVal('background'));
end;

procedure TModuleGUICheckBoxDefault.CheckModConf;
begin
  if GetConfVal('used') = '' then
    begin
    SetConfVal('used', '1');
    SetConfVal('background', 'guicheckboxdefault/bg.tga');
    end;
end;

procedure TModuleGUICheckBoxDefault.Render(CheckBox: TCheckBox);
  procedure RenderCheckBox(oX, oY: GLFloat);
  begin
    glTexCoord2f(oX + 0,                   oY + 0);   glVertex3f(CheckBox.Left,                  CheckBox.Top, 0);
    glTexCoord2f(oX + 0.5,                 oY + 0);   glVertex3f(CheckBox.Left + CheckBox.Width, CheckBox.Top, 0);
    glTexCoord2f(oX + 0.5,                 oY + 0.5); glVertex3f(CheckBox.Left + CheckBox.Width, CheckBox.Top + CheckBox.Height, 0);
    glTexCoord2f(oX + 0,                   oY + 0.5); glVertex3f(CheckBox.Left,                  CheckBox.Top + CheckBox.Height, 0);
  end;
begin
  if CheckBox.Checked then
    CheckBox.fClickFactor := CheckBox.fClickFactor + (1 - CheckBox.fClickFactor) / 3
  else
    CheckBox.fClickFactor := CheckBox.fClickFactor - CheckBox.fClickFactor / 3;
  if ModuleManager.ModGUI.HoverComponent = CheckBox then
    CheckBox.fHoverFactor := CheckBox.fHoverFactor + (1 - CheckBox.fHoverFactor) / 3
  else
    CheckBox.fHoverFactor := CheckBox.fHoverFactor - CheckBox.fHoverFactor / 3;

  CheckBox.fHoverFactor := Min(CheckBox.fHoverFactor, 1 - CheckBox.fClickFactor);

  fTexture.Bind(0);
  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  glBegin(GL_QUADS);
    glColor4f(1, 1, 1, CheckBox.Alpha);
    RenderCheckBox(0, 0);
    glColor4f(1, 1, 1, CheckBox.Alpha * CheckBox.fHoverFactor);
    RenderCheckBox(0.5, 0);
    glColor4f(1, 1, 1, CheckBox.Alpha * CheckBox.fClickFactor);
    RenderCheckBox(0, 0.5);
  glEnd;
  glDisable(GL_BLEND);
  fTexture.Unbind;
end;

destructor TModuleGUICheckBoxDefault.Free;
begin
  fTexture.Free;
end;

end.