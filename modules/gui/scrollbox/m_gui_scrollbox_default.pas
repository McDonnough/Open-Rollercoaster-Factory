unit m_gui_scrollbox_default;

interface

uses
  SysUtils, Classes, m_gui_scrollbox_class, m_texmng_class, DGLOpenGL;

type
  TModuleGUIScrollBoxDefault = class(TModuleGUIScrollBoxClass)
    protected
      fScrollBarLine, fScrollBarThrobber: TTexture;
    public
      constructor Create;
      destructor Free;
      procedure CheckModConf; override;
      procedure Render(sb: TScrollBox); override;
    end;

implementation

uses
  u_math, math;

constructor TModuleGUIScrollBoxDefault.Create;
begin
  fModName := 'GUIScrollBoxDefault';
  fModType := 'GUIScrollBox';

  CheckModConf;

  fScrollBarLine := TTexture.Create;
  fScrollBarLine.FromFile(GetConfVal('line'));

  fScrollBarThrobber := TTexture.Create;
  fScrollBarThrobber.FromFile(GetConfVal('throbber'));
end;

destructor TModuleGUIScrollBoxDefault.Free;
begin
  fScrollBarLine.Free;
  fScrollBarThrobber.Free;
end;

procedure TModuleGUIScrollBoxDefault.CheckModConf;
begin
  if GetConfVal('used') = '' then
    begin
    SetConfVal('used', '1');
    SetConfVal('line', 'guiscrollboxdefault/line.tga');
    SetConfVal('throbber', 'guiscrollboxdefault/throbber.tga');
    end;
end;

procedure TModuleGUIScrollBoxDefault.Render(sb: TScrollBox);
var
  ThrobberHeight, ThrobberWidth, VThrobberPosition, HThrobberPosition: Integer;
  HThrobberOffset, HThrobberOffset2, VThrobberOffset, VThrobberOffset2: Integer;
  HWidth, VHeight: Integer;
begin
  HThrobberOffset := 0;
  VThrobberOffset := 0;
  HThrobberOffset2 := 0;
  VThrobberOffset2 := 0;
  if sb.VScrollBar = sbmNormal then
    VThrobberOffset := Round(sb.Width - 15)
  else if sb.VScrollBar = sbmInverted then
    HThrobberOffset2 := 16;
  if sb.HScrollBar = sbmNormal then
    HThrobberOffset := Round(sb.Height - 15)
  else if sb.HScrollBar = sbmInverted then
    VThrobberOffset2 := 16;
  HWidth := Round(sb.Width);
  VHeight := Round(sb.Height);
  if sb.VScrollBar <> sbmInvisible then
    HWidth := HWidth - 16;
  if sb.HScrollBar <> sbmInvisible then
    VHeight := VHeight - 16;

  ThrobberHeight := Round(Clamp(sb.Height * sb.Height / Max(1.0, sb.ContentHeight), 18, sb.Height));
  VThrobberPosition := Round(sb.Height * sb.VScrollPosition / Max(1, sb.ContentHeight));

  glEnable(GL_BLEND);
  glColor4f(1, 1, 1, 1);
  fScrollBarLine.Bind(0);

  if sb.VScrollBar <> sbmInvisible then
    begin
    glBegin(GL_QUADS);
      glTexCoord2f(0, 0.0); glVertex2f(sb.Left + VThrobberOffset, sb.Top + VThrobberOffset2);
      glTexCoord2f(1, 0.0); glVertex2f(sb.Left + VThrobberOffset + 15, sb.Top + VThrobberOffset2);
      glTexCoord2f(1, 0.5); glVertex2f(sb.Left + VThrobberOffset + 15, sb.Top + VThrobberOffset2 + 9);
      glTexCoord2f(0, 0.5); glVertex2f(sb.Left + VThrobberOffset, sb.Top + VThrobberOffset2 + 9);

      glTexCoord2f(0, 0.5); glVertex2f(sb.Left + VThrobberOffset, sb.Top + VThrobberOffset2 + 9);
      glTexCoord2f(1, 0.5); glVertex2f(sb.Left + VThrobberOffset + 15, sb.Top + VThrobberOffset2 + 9);
      glTexCoord2f(1, 0.5); glVertex2f(sb.Left + VThrobberOffset + 15, sb.Top + VThrobberOffset2 + VHeight - 9);
      glTexCoord2f(0, 0.5); glVertex2f(sb.Left + VThrobberOffset, sb.Top + VThrobberOffset2 + VHeight - 9);

      glTexCoord2f(0, 0.5); glVertex2f(sb.Left + VThrobberOffset, sb.Top + VThrobberOffset2 + VHeight - 9);
      glTexCoord2f(1, 0.5); glVertex2f(sb.Left + VThrobberOffset + 15, sb.Top + VThrobberOffset2 + VHeight - 9);
      glTexCoord2f(1, 1.0); glVertex2f(sb.Left + VThrobberOffset + 15, sb.Top + VThrobberOffset2 + VHeight);
      glTexCoord2f(0, 1.0); glVertex2f(sb.Left + VThrobberOffset, sb.Top + VThrobberOffset2 + VHeight);
    glEnd;
    end;
  fScrollBarLine.Unbind;

  fScrollBarThrobber.Bind(0);
  if sb.VScrollBar <> sbmInvisible then
    begin
    glBegin(GL_QUADS);
      glTexCoord2f(0, 0.0); glVertex2f(sb.Left + VThrobberOffset, sb.Top + VThrobberOffset2 + VThrobberPosition);
      glTexCoord2f(1, 0.0); glVertex2f(sb.Left + VThrobberOffset + 15, sb.Top + VThrobberOffset2 + VThrobberPosition);
      glTexCoord2f(1, 0.5); glVertex2f(sb.Left + VThrobberOffset + 15, sb.Top + VThrobberOffset2 + VThrobberPosition + 9);
      glTexCoord2f(0, 0.5); glVertex2f(sb.Left + VThrobberOffset, sb.Top + VThrobberOffset2 + VThrobberPosition + 9);

      glTexCoord2f(0, 0.5); glVertex2f(sb.Left + VThrobberOffset, sb.Top + VThrobberOffset2 + VThrobberPosition + 9);
      glTexCoord2f(1, 0.5); glVertex2f(sb.Left + VThrobberOffset + 15, sb.Top + VThrobberOffset2 + VThrobberPosition + 9);
      glTexCoord2f(1, 0.5); glVertex2f(sb.Left + VThrobberOffset + 15, sb.Top + VThrobberOffset2 + ThrobberHeight + VThrobberPosition - 9);
      glTexCoord2f(0, 0.5); glVertex2f(sb.Left + VThrobberOffset, sb.Top + VThrobberOffset2 + ThrobberHeight + VThrobberPosition - 9);

      glTexCoord2f(0, 0.5); glVertex2f(sb.Left + VThrobberOffset, sb.Top + VThrobberOffset2 + ThrobberHeight + VThrobberPosition - 9);
      glTexCoord2f(1, 0.5); glVertex2f(sb.Left + VThrobberOffset + 15, sb.Top + VThrobberOffset2 + ThrobberHeight + VThrobberPosition - 9);
      glTexCoord2f(1, 1.0); glVertex2f(sb.Left + VThrobberOffset + 15, sb.Top + VThrobberOffset2 + ThrobberHeight + VThrobberPosition);
      glTexCoord2f(0, 1.0); glVertex2f(sb.Left + VThrobberOffset, sb.Top + VThrobberOffset2 + ThrobberHeight + VThrobberPosition);
    glEnd;
    end;
  fScrollBarThrobber.Unbind;
end;

end.