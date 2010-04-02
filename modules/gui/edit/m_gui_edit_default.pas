unit m_gui_edit_default;

interface

uses
  SysUtils, Classes, m_gui_edit_class, m_texmng_class, DGLOpenGL, Math;

type
  TModuleGUIEditDefault = class(TModuleGUIEditClass)
    protected
      fTexture: TTexture;
    public
      procedure CheckModConf;
      procedure Render(Edit: TEdit);
      procedure HandleKeypress(Edit: TEdit; Key: Integer);
      constructor Create;
      destructor Free;
    end;

implementation

uses
  m_varlist, u_functions, m_inputhandler_class;

procedure TModuleGUIEditDefault.CheckModConf;
begin
  if GetConfVal('used') = '' then
    begin
    SetConfVal('used', '1');
    SetConfVal('background', 'guieditdefault/bg.tga');
    end;
end;

procedure TModuleGUIEditDefault.Render(Edit: TEdit);
var
  i: integer;
  procedure RenderEdit(oX, oY: GLFloat);
  begin
    glTexCoord2f(oX + 0,                   oY + 0);         glVertex3f(Edit.Left,      Edit.Top, 0);
    glTexCoord2f(oX + 8 / fTexture.Width, oY + 0);         glVertex3f(Edit.Left + 8, Edit.Top, 0);
    glTexCoord2f(oX + 8 / fTexture.Width, oY + 0.5);       glVertex3f(Edit.Left + 8, Edit.Top + Edit.Height, 0);
    glTexCoord2f(oX + 0,                   oY + 0.5);       glVertex3f(Edit.Left,      Edit.Top + Edit.Height, 0);

    glTexCoord2f(oX + 8 / fTexture.Width,       oY + 0);   glVertex3f(Edit.Left + 8,            Edit.Top, 0);
    glTexCoord2f(oX + 0.5 - 8 / fTexture.Width, oY + 0);   glVertex3f(Edit.Left + Edit.Width - 8, Edit.Top, 0);
    glTexCoord2f(oX + 0.5 - 8 / fTexture.Width, oY + 0.5); glVertex3f(Edit.Left + Edit.Width - 8, Edit.Top + Edit.Height, 0);
    glTexCoord2f(oX + 8 / fTexture.Width,       oY + 0.5); glVertex3f(Edit.Left + 8,            Edit.Top + Edit.Height, 0);

    glTexCoord2f(oX + 0.5 - 8 / fTexture.Width, oY + 0);   glVertex3f(Edit.Left + Edit.Width - 8, Edit.Top, 0);
    glTexCoord2f(oX + 0.5,                       oY + 0);   glVertex3f(Edit.Left + Edit.Width,      Edit.Top, 0);
    glTexCoord2f(oX + 0.5,                       oY + 0.5); glVertex3f(Edit.Left + Edit.Width,      Edit.Top + Edit.Height, 0);
    glTexCoord2f(oX + 0.5 - 8 / fTexture.Width, oY + 0.5); glVertex3f(Edit.Left + Edit.Width - 8, Edit.Top + Edit.Height, 0);
  end;
begin
  glDisable(GL_DEPTH_TEST);
  glClear(GL_DEPTH_BUFFER_BIT);
  if ModuleManager.ModGUI.HoverComponent = Edit then
    Edit.fHoverFactor := Edit.fHoverFactor + (1 - Edit.fHoverFactor) / 10
  else
    Edit.fHoverFactor := Edit.fHoverFactor - Edit.fHoverFactor / 10;
  if ModuleManager.ModGUI.FocusComponent = Edit then
    Edit.fClickFactor := Edit.fClickFactor + (1 - Edit.fClickFactor) / 10
  else
    Edit.fClickFactor := Edit.fClickFactor - Edit.fClickFactor / 10;
  fTexture.Bind;
  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  glBegin(GL_QUADS);
    glColor4f(1, 1, 1, 1);
    RenderEdit(0, 0);
    glColor4f(1, 1, 1, Edit.fHoverFactor);
    RenderEdit(0.5, 0);
    glColor4f(1, 1, 1, Edit.fClickFactor);
    RenderEdit(0, 0.5);
  glEnd;
  fTexture.Unbind;
  i := 0;
  if ModuleManager.ModFont.CalculateTextWidth(SubString(Edit.Text, Edit.MovedChars + 1, Length(Edit.Text) - Edit.MovedChars), round(Edit.Height - 16)) > Edit.Width - 16 then
    begin
    while ModuleManager.ModFont.CalculateTextWidth(SubString(Edit.Text, Edit.MovedChars + 1, i), round(Edit.Height - 16)) < Edit.Width - 16 do
      i := i + 1;
    i := i - 1;
    end
  else
    i := Length(Edit.Text) - Edit.MovedChars;
  ModuleManager.ModFont.Write(SubString(Edit.Text, Edit.MovedChars + 1, i), Edit.Height - 16, Edit.Left + 8, Edit.Top + 8, 0, 0, 0, 1, 0);
  glBegin(GL_LINES);
    glColor4f(1 - Edit.fClickFactor, 1 - Edit.fClickFactor, 1 - Edit.fClickFactor, Edit.fClickFactor);
    glVertex2f(Edit.Left + ModuleManager.ModFont.CalculateTextWidth(SubString(Edit.Text, Edit.MovedChars + 1, Edit.CursorPos - Edit.MovedChars), round(Edit.Height - 16)) + 8, Edit.Top + 8);
    glVertex2f(Edit.Left + ModuleManager.ModFont.CalculateTextWidth(SubString(Edit.Text, Edit.MovedChars + 1, Edit.CursorPos - Edit.MovedChars), round(Edit.Height - 16)) + 8, Edit.Top + Edit.Height - 8);
  glEnd;
  glDisable(GL_BLEND);
end;

procedure TModuleGUIEditDefault.HandleKeypress(Edit: TEdit; Key: Integer);
var
  CursorPosBefore: Integer;
begin
  CursorPosBefore := Edit.CursorPos;
  case Key of
    32..255:
      begin
      if (ModuleManager.ModInputHandler.Key[K_SHIFT]) and (ModuleManager.ModInputHandler.Key[K_ALT]) then
        case Char(Key) of
          'a': ;
          end
      else if ModuleManager.ModInputHandler.Key[K_SHIFT] then
        case Char(Key) of
          'a'..'z', #224..#255: Key := Key - 32;
          '1'..'6', '8'..'9': Key := Key - 16;
          '7': Key := Ord('/');
          '0': Key := Ord('=');
          #223: Key := Ord('?');
          '-': Key := Ord('_');
          '+': Key := Ord('*');
          '#': Key := Ord('''');
          '.': Key := Ord(':');
          ',': Key := Ord(';');
          '<': Key := Ord('>');
          '^': Key := 176;
          end
      else if ModuleManager.ModInputHandler.Key[K_ALT] then
        case Char(Key) of
          '0': Key := Ord('}');
          '1': Key := 185;
          '2': Key := 178;
          '3': Key := 179;
          '4': Key := 188;
          '5': Key := 189;
          '6': Key := 172;
          '7': Key := Ord('{');
          '8': Key := Ord('[');
          '9': Key := Ord(']');
          #223: Key := Ord('\');
          '-': Key := 151;
          '+': Key := 126;
          '#': Key := 93;
          '.': Key := 133;
          ',': Key := 183;
          '<': Key := 166;
          end;
      Edit.Text := SubString(Edit.Text, 1, Edit.CursorPos) + Char(Key) + SubString(Edit.Text, Edit.CursorPos + 1, Length(Edit.Text) - Edit.CursorPos);
      Edit.CursorPos := Edit.CursorPos + 1;
      end;
    K_BACKSPACE:
      begin
      if Edit.CursorPos <> 0 then
        begin
        if Edit.MovedChars = Edit.CursorPos then
        while (ModuleManager.ModFont.CalculateTextWidth(SubString(Edit.Text, Edit.MovedChars + 1, Edit.CursorPos - Edit.MovedChars), round(Edit.Height - 16)) < round((Edit.Width - 16) / 2)) and (Edit.MovedChars <> 0) do
          Edit.MovedChars := Edit.MovedChars - 1;
        Edit.Text := SubString(Edit.Text, 1, Edit.CursorPos - 1) + SubString(Edit.Text, Edit.CursorPos + 1, Length(Edit.Text) - (Edit.CursorPos - 1));
        if Edit.CursorPos = CursorPosBefore then
          Edit.CursorPos := Edit.CursorPos - 1;
        end;
      end;
    K_LEFT:
      if Edit.CursorPos > 0 then
        Edit.CursorPos := Edit.CursorPos - 1;
    K_RIGHT:
      if Edit.CursorPos < Length(Edit.Text) then
        Edit.CursorPos := Edit.CursorPos + 1;
    end;
  if Edit.CursorPos - Edit.MovedChars < 0 then
    Edit.MovedChars := Edit.MovedChars - 1
  else if ModuleManager.ModFont.CalculateTextWidth(SubString(Edit.Text, Edit.MovedChars + 1, Edit.CursorPos - Edit.MovedChars), round(Edit.Height - 16)) > Edit.Width - 16 then
    while ModuleManager.ModFont.CalculateTextWidth(SubString(Edit.Text, Edit.MovedChars + 1, Edit.CursorPos - Edit.MovedChars), round(Edit.Height - 16)) > Edit.Width - 16 do
      Edit.MovedChars := Edit.MovedChars + 1;
end;

constructor TModuleGUIEditDefault.Create;
begin
  fModName := 'GUIEditDefault';
  fModType := 'GUIEdit';

  CheckModConf;

  fTexture := TTexture.Create;
  fTexture.FromFile(GetConfVal('background'));
end;

destructor TModuleGUIEditDefault.Free;
begin
  fTexture.Free;
end;

end.
