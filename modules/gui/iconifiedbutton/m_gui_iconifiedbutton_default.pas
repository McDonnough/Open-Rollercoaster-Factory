unit m_gui_iconifiedbutton_default;

interface

uses
  Classes, SysUtils, m_gui_iconifiedbutton_class, m_texmng_class, DGLOpenGL, math;

type
  TModuleGUIIconifiedButtonDefault = class(TModuleGUIIconifiedButtonClass)
    protected
      fIcons: array of TTexture;
      fIconNames: array of String;
      fTexture: TTexture;
      function FindIconByName(s: String): TTexture;
    public
      procedure Render(Button: TIconifiedButton);
      procedure SetIcon(Button: TIconifiedButton; Icon: String);
      constructor Create;
      destructor Free;
      procedure CheckModConf;
    end;

implementation

uses
  m_varlist;

function TModuleGUIIconifiedButtonDefault.FindIconByName(s: String): TTexture;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to high(fIconNames) do
    if fIconNames[i] = s then
      exit(fIcons[i]);
end;

procedure TModuleGUIIconifiedButtonDefault.Render(Button: TIconifiedButton);
var
  Tex: TTexture;

  procedure RenderButton(ofX, ofY: GLFloat);
  begin
    glTexCoord2f(0 + ofX,   0 + ofY);   glVertex3f(Round(Button.Left),                Round(Button.Top),                 0);
    glTexCoord2f(0.5 + ofX, 0 + ofY);   glVertex3f(Round(Button.Left + Button.Width), Round(Button.Top),                 0);
    glTexCoord2f(0.5 + ofX, 0.5 + ofY); glVertex3f(Round(Button.Left + Button.Width), Round(Button.Top + Button.Height), 0);
    glTexCoord2f(0 + ofX,   0.5 + ofY); glVertex3f(Round(Button.Left),                Round(Button.Top + Button.Height), 0);
  end;
begin
  if ModuleManager.ModGUI.HoverComponent = Button then
    begin
    Button.fHoverFactor := Button.fHoverFactor + (1 - Button.fHoverFactor) / 10;
    if ModuleManager.ModGUI.Clicking then
      Button.fClickFactor := Button.fClickFactor + (1 - Button.fClickFactor) / 10
    else
      Button.fClickFactor := Button.fClickFactor - Button.fClickFactor / 10;
    end
  else
    begin
    Button.fHoverFactor := Button.fHoverFactor - Button.fHoverFactor / 10;
    Button.fClickFactor := Button.fClickFactor - Button.fClickFactor / 10;
    end;

  fTexture.Bind;

  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  glBegin(GL_QUADS);
    glColor4f(1, 1, 1, 1);
    RenderButton(0, 0);
    glColor4f(1, 1, 1, Button.fHoverFactor);
    RenderButton(0.5, 0);
    glColor4f(1, 1, 1, Button.fClickFactor);
    RenderButton(0, 0.5);
  glEnd;

  fTexture.Unbind;

  Tex := FindIconByName(Button.Icon);
  if Tex <> nil then
    begin
    Tex.Bind;
    glBegin(GL_QUADS);
      glColor4f(1, 1, 1, 1);
      glTexCoord2f(0, 0); glVertex3f(Button.Left + 0.125 * Button.Width, Button.Top + 0.125 * Button.Height, 0);
      glTexCoord2f(1, 0); glVertex3f(Button.Left + 0.875 * Button.Width, Button.Top + 0.125 * Button.Height, 0);
      glTexCoord2f(1, 1); glVertex3f(Button.Left + 0.875 * Button.Width, Button.Top + 0.875 * Button.Height, 0);
      glTexCoord2f(0, 1); glVertex3f(Button.Left + 0.125 * Button.Width, Button.Top + 0.875 * Button.Height, 0);
    glEnd;
    Tex.UnBind;
    end;
  glDisable(GL_BLEND);
end;

procedure TModuleGUIIconifiedButtonDefault.SetIcon(Button: TIconifiedButton; Icon: String);
begin
  if FindIconByName(Icon) = nil then
    begin
    setLength(fIcons, length(fIcons) + 1);
    fIcons[high(fIcons)] := TTexture.Create;
    fIcons[high(fIcons)].FromFile('guiicons/' + Icon);
    setLength(fIconNames, length(fIcons));
    fIconNames[high(fIconNames)] := Icon;
    end;
end;

constructor TModuleGUIIconifiedButtonDefault.Create;
begin
  fModName := 'GUIIconifiedButtonDefault';
  fModType := 'GUIIconifiedButton';

  CheckModConf;

  fTexture := TTexture.Create;
  fTexture.FromFile(GetConfVal('background'));
end;

destructor TModuleGUIIconifiedButtonDefault.Free;
var
  i: Integer;
begin
  fTexture.Free;
  for i := 0 to high(fIcons) do
    fIcons[i].Free;
end;

procedure TModuleGUIIconifiedButtonDefault.CheckModConf;
begin
  if GetConfVal('used') = '' then
    begin
    SetConfVal('used', '1');
    SetConfVal('background', 'guiiconifiedbuttondefault/bg.tga');
    end;
end;

end.