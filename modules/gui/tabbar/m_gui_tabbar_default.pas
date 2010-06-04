unit m_gui_tabbar_default;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_gui_tabbar_class, DGLOpenGL, m_texmng_class;

type
  TModuleGUITabBarDefault = class(TModuleGUITabBarClass)
    protected
      fMask: TTexture;
    public
      constructor Create;
      destructor Free;
      procedure CheckModConf;
      function GetTabWidth(Lbl: TTabBar; I: Integer): Integer;
      procedure Render(Lbl: TTabBar);
    end;

implementation

uses
  m_varlist, math;

constructor TModuleGUITabBarDefault.Create;
begin
  fModName := 'GUITabBarDefault';
  fModType := 'GUITabBar';

  CheckModConf;

  fMask := TTexture.Create;
  fMask.FromFile(GetConfVal('background'));
  fMask.SetClamp(GL_CLAMP, GL_CLAMP);
  fMask.SetFilter(GL_NEAREST, GL_NEAREST);
end;

function TModuleGUITabBarDefault.GetTabWidth(Lbl: TTabBar; I: Integer): Integer;
begin
  Result := Max(Lbl.Tabs[i].MinWidth, ModuleManager.ModFont.CalculateTextWidth(ModuleManager.ModLanguage.Translate(Lbl.Tabs[i].Caption), Round(Lbl.Height) - 8) + 40) - 24;
end;

procedure TModuleGUITabBarDefault.CheckModConf;
begin
  if GetConfVal('used') = '' then
    begin
    SetConfVal('used', '1');
    SetConfVal('background', 'guitabbardefault/bg.tga');
    end;
end;

procedure TModuleGUITabBarDefault.Render(Lbl: TTabBar);
var
  i, Offset, SOffset, TotalWidth, TabWidth: Integer;

  procedure RenderTab;
  begin
    glTexCoord2f(0, 0); glVertex2f(Lbl.Left + Offset, Lbl.Top);
    glTexCoord2f(1, 0); glVertex2f(Lbl.Left + Offset + 16, Lbl.Top);
    glTexCoord2f(1, 1); glVertex2f(Lbl.Left + Offset + 16, Lbl.Top + Lbl.Height);
    glTexCoord2f(0, 1); glVertex2f(Lbl.Left + Offset, Lbl.Top + Lbl.Height);

    glTexCoord2f(1, 0); glVertex2f(Lbl.Left + Offset - 16 + TabWidth + 24, Lbl.Top);
    glTexCoord2f(1, 0); glVertex2f(Lbl.Left + Offset + 16, Lbl.Top);
    glTexCoord2f(1, 1); glVertex2f(Lbl.Left + Offset + 16, Lbl.Top + Lbl.Height);
    glTexCoord2f(1, 1); glVertex2f(Lbl.Left + Offset - 16 + TabWidth + 24, Lbl.Top + Lbl.Height);

    glTexCoord2f(0, 0); glVertex2f(Lbl.Left + Offset + TabWidth + 24, Lbl.Top);
    glTexCoord2f(1, 0); glVertex2f(Lbl.Left + Offset - 16 + TabWidth + 24, Lbl.Top);
    glTexCoord2f(1, 1); glVertex2f(Lbl.Left + Offset - 16 + TabWidth + 24, Lbl.Top + Lbl.Height);
    glTexCoord2f(0, 1); glVertex2f(Lbl.Left + Offset + TabWidth + 24, Lbl.Top + Lbl.Height);
  end;
begin
  Offset := 0;
  SOffset := 0;

  glEnable(GL_ALPHA_TEST);
  glEnable(GL_BLEND);

  fMask.Bind;
  glBegin(GL_QUADS);
  for i := 0 to high(Lbl.Tabs) do
    begin
    if i = Lbl.SelectedTab then
      SOffset := Offset;
    TabWidth := GetTabWidth(Lbl, i);
    Offset := Offset + TabWidth;
    end;
  for i := high(Lbl.Tabs) downto 0 do
    begin
    TabWidth := GetTabWidth(Lbl, i);
    Offset := Offset - TabWidth;
    glColor4f(0.8, 0.8, 0.8, Lbl.Alpha);
    if i <> Lbl.SelectedTab then
      RenderTab;
    end;
  glColor4f(1, 1, 1, Lbl.Alpha);
  i := Lbl.SelectedTab;
  TabWidth := GetTabWidth(Lbl, i);
  TotalWidth := Offset + 4;
  Offset := SOffset;
  RenderTab;
  glEnd;

  fMask.Unbind;

  Offset := 0;

  for i := 0 to high(Lbl.Tabs) do
    begin
    TabWidth := GetTabWidth(Lbl, i) + 24;
    ModuleManager.ModFont.Write(ModuleManager.ModLanguage.Translate(Lbl.Tabs[i].Caption), Lbl.Height - 8, Lbl.Left + Offset + (TabWidth - ModuleManager.ModFont.CalculateTextWidth(ModuleManager.ModLanguage.Translate(Lbl.Tabs[i].Caption), Round(Lbl.Height) - 8)) / 2, Lbl.Top + 8, 0, 0, 0, Lbl.Alpha, 0);
    Offset := Offset + TabWidth - 24;
    end;
end;

destructor TModuleGUITabBarDefault.Free;
begin
  fMask.Free;
end;

end.

