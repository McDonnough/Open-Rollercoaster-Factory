unit m_gui_button_default;

interface

uses
  SysUtils, Classes, DGLOpenGL, m_gui_button_class, m_texmng_class, Math;

type
  TModuleGUIButtonDefault = class(TModuleGUIButtonClass)
    protected
      fTexture: TTexture;
    public
      constructor Create;
      destructor Free;
      procedure CheckModConf;
      procedure Render(Button: TButton);
    end;

implementation

uses
  m_varlist;

constructor TModuleGUIButtonDefault.Create;
begin
  fModName := 'GUIButtonDefault';
  fModType := 'GUIButton';

  CheckModConf;

  fTexture := TTexture.Create;
  fTexture.FromFile(GetConfVal('background'));
end;

destructor TModuleGUIButtonDefault.Free;
begin
  fTexture.Free;
end;

procedure TModuleGUIButtonDefault.CheckModConf;
begin
  if GetConfVal('used') = '' then
    begin
    SetConfVal('used', '1');
    SetConfVal('background', 'guibuttondefault/bg.tga');
    end;
end;

procedure TModuleGUIButtonDefault.Render(Button: TButton);
  procedure RenderButton(oX, oY: GLFloat);
  begin
    glTexCoord2f(oX + 0,                   oY + 0);         glVertex3f(Button.Left,      Button.Top, 0);
    glTexCoord2f(oX + 8 / fTexture.Width, oY + 0);         glVertex3f(Button.Left + 8, Button.Top, 0);
    glTexCoord2f(oX + 8 / fTexture.Width, oY + 0.5);       glVertex3f(Button.Left + 8, Button.Top + Button.Height, 0);
    glTexCoord2f(oX + 0,                   oY + 0.5);       glVertex3f(Button.Left,      Button.Top + Button.Height, 0);

    glTexCoord2f(oX + 8 / fTexture.Width,       oY + 0);   glVertex3f(Button.Left + 8,            Button.Top, 0);
    glTexCoord2f(oX + 0.5 - 8 / fTexture.Width, oY + 0);   glVertex3f(Button.Left + Button.Width - 8, Button.Top, 0);
    glTexCoord2f(oX + 0.5 - 8 / fTexture.Width, oY + 0.5); glVertex3f(Button.Left + Button.Width - 8, Button.Top + Button.Height, 0);
    glTexCoord2f(oX + 8 / fTexture.Width,       oY + 0.5); glVertex3f(Button.Left + 8,            Button.Top + Button.Height, 0);

    glTexCoord2f(oX + 0.5 - 8 / fTexture.Width, oY + 0);   glVertex3f(Button.Left + Button.Width - 8, Button.Top, 0);
    glTexCoord2f(oX + 0.5,                       oY + 0);   glVertex3f(Button.Left + Button.Width,      Button.Top, 0);
    glTexCoord2f(oX + 0.5,                       oY + 0.5); glVertex3f(Button.Left + Button.Width,      Button.Top + Button.Height, 0);
    glTexCoord2f(oX + 0.5 - 8 / fTexture.Width, oY + 0.5); glVertex3f(Button.Left + Button.Width - 8, Button.Top + Button.Height, 0);
  end;
begin
  if ModuleManager.ModGUI.HoverComponent = Button then
    begin
    Button.fHoverFactor := Button.fHoverFactor + (1 - Button.fHoverFactor) / 3;
    if ModuleManager.ModGUI.Clicking then
      Button.fClickFactor := Button.fClickFactor + (1 - Button.fClickFactor) / 3
    else
      Button.fClickFactor := Button.fClickFactor - Button.fClickFactor / 3;
    end
  else
    begin
    Button.fHoverFactor := Button.fHoverFactor - Button.fHoverFactor / 3;
    Button.fClickFactor := Button.fClickFactor - Button.fClickFactor / 3;
    end;
  fTexture.Bind;
  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  glBegin(GL_QUADS);
    glColor4f(1, 1, 1, Button.Alpha);
    RenderButton(0, 0);
    glColor4f(1, 1, 1, Button.Alpha * Button.fHoverFactor);
    RenderButton(0.5, 0);
    glColor4f(1, 1, 1, Button.Alpha * Button.fClickFactor);
    RenderButton(0, 0.5);
  glEnd;
  glDisable(GL_BLEND);
  fTexture.Unbind;
  ModuleManager.ModFont.Write(Button.Caption, Button.Height - 16, Button.Left + Round(Button.Width - ModuleManager.ModFont.CalculateTextWidth(Button.Caption, Round(Button.Height - 16))) div 2, Button.Top + 8, 0, 0, 0, Button.Alpha, 0);
end;

end.