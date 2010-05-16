unit m_gui_progressbar_default;

interface

uses
  SysUtils, Classes, m_gui_progressbar_class, m_texmng_class, DGLOpenGL, math;

type
  TModuleGUIProgressBarDefault = class(TModuleGUIProgressBarClass)
    protected
      fTexture: TTexture;
    public
      constructor Create;
      destructor Free;
      procedure CheckModConf;
      procedure Render(pb: TProgressBar);
    end;

implementation

uses
  m_varlist;

constructor TModuleGUIProgressBarDefault.Create;
begin
  fModName := 'GUIProgressBarDefault';
  fModType := 'GUIProgressBar';

  CheckModConf;

  fTexture := TTexture.Create;
  fTexture.FromFile(GetConfVal('background'));
end;

procedure TModuleGUIProgressBarDefault.CheckModConf;
begin
  if GetConfVal('used') = '' then
    begin
    SetConfVal('used', '1');
    SetConfVal('background', 'guiprogressbardefault/bg.tga');
    end;
end;

procedure TModuleGUIProgressBarDefault.Render(pb: TProgressBar);
var
  fPercentage: GLFloat;
begin
  fPercentage := min(max(0.0, pb.Progress * 0.01), 1.0);

  glColor4f(1, 1, 1, 1);
  fTexture.Bind;
  glBegin(GL_QUADS);
    glTexCoord2f(0,                   0);       glVertex3f(pb.Left,      pb.Top, 0);
    glTexCoord2f(16 / fTexture.Width, 0);       glVertex3f(pb.Left + 16, pb.Top, 0);
    glTexCoord2f(16 / fTexture.Width, 0.5);     glVertex3f(pb.Left + 16, pb.Top + pb.Height, 0);
    glTexCoord2f(0,                   0.5);     glVertex3f(pb.Left,      pb.Top + pb.Height, 0);

    glTexCoord2f(16 / fTexture.Width,     0);   glVertex3f(pb.Left + 16,            pb.Top, 0);
    glTexCoord2f(1 - 16 / fTexture.Width, 0);   glVertex3f(pb.Left + pb.Width - 16, pb.Top, 0);
    glTexCoord2f(1 - 16 / fTexture.Width, 0.5); glVertex3f(pb.Left + pb.Width - 16, pb.Top + pb.Height, 0);
    glTexCoord2f(16 / fTexture.Width,     0.5); glVertex3f(pb.Left + 16,            pb.Top + pb.Height, 0);

    glTexCoord2f(1 - 16 / fTexture.Width, 0);   glVertex3f(pb.Left + pb.Width - 16, pb.Top, 0);
    glTexCoord2f(1,                       0);   glVertex3f(pb.Left + pb.Width,      pb.Top, 0);
    glTexCoord2f(1,                       0.5); glVertex3f(pb.Left + pb.Width,      pb.Top + pb.Height, 0);
    glTexCoord2f(1 - 16 / fTexture.Width, 0.5); glVertex3f(pb.Left + pb.Width - 16, pb.Top + pb.Height, 0);

    if fPercentage > 0 then
      begin
      glTexCoord2f(0,                   0.5);     glVertex3f(pb.Left,      pb.Top, 0);
      glTexCoord2f(16 / fTexture.Width, 0.5);     glVertex3f(pb.Left + 16, pb.Top, 0);
      glTexCoord2f(16 / fTexture.Width, 1);       glVertex3f(pb.Left + 16, pb.Top + pb.Height, 0);
      glTexCoord2f(0,                   1);       glVertex3f(pb.Left,      pb.Top + pb.Height, 0);

      glTexCoord2f(16 / fTexture.Width,     0.5); glVertex3f(pb.Left + 16,                                 pb.Top, 0);
      glTexCoord2f(1 - 16 / fTexture.Width, 0.5); glVertex3f(pb.Left + (pb.Width - 32) * fPercentage + 16, pb.Top, 0);
      glTexCoord2f(1 - 16 / fTexture.Width, 1);   glVertex3f(pb.Left + (pb.Width - 32) * fPercentage + 16, pb.Top + pb.Height, 0);
      glTexCoord2f(16 / fTexture.Width,     1);   glVertex3f(pb.Left + 16,                                 pb.Top + pb.Height, 0);
      end;
    if fPercentage = 1 then
      begin
      glTexCoord2f(1 - 16 / fTexture.Width, 0.5); glVertex3f(pb.Left + pb.Width - 16, pb.Top, 0);
      glTexCoord2f(1,                       0.5); glVertex3f(pb.Left + pb.Width,      pb.Top, 0);
      glTexCoord2f(1,                       1);   glVertex3f(pb.Left + pb.Width,      pb.Top + pb.Height, 0);
      glTexCoord2f(1 - 16 / fTexture.Width, 1);   glVertex3f(pb.Left + pb.Width - 16, pb.Top + pb.Height, 0);
      end;
  glEnd;
  fTexture.Unbind;
end;

destructor TModuleGUIProgressBarDefault.Free;
begin
  fTexture.Free;
end;

end.