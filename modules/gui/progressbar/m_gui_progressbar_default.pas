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
      procedure CheckModConf; override;
      procedure Render(pb: TProgressBar); override;
    end;

implementation

uses
  m_varlist, u_math;

constructor TModuleGUIProgressBarDefault.Create;
begin
  fModName := 'GUIProgressBarDefault';
  fModType := 'GUIProgressBar';

  CheckModConf;

  fTexture := TTexture.Create;
  fTexture.FromFile(GetConfVal('background'));
  fTexture.SetFilter(GL_LINEAR, GL_LINEAR);
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
  BulletSize, Bullets: Integer;
  FullyFilledBullets: Integer;
  MiddleBulletPercentage: GLFloat;
begin
  BulletSize := Round(pb.Height + 1);
  repeat
    dec(BulletSize);
    Bullets := Ceil(pb.Width / BulletSize);
  until
    BulletSize * Bullets <= pb.Width;
  FullyFilledBullets := Floor(Bullets * pb.Progress / 100);
  MiddleBulletPercentage := FPart(Bullets * pb.Progress / 100);

  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  glEnable(GL_ALPHA_TEST);
  glAlphaFunc(GL_GREATER, 0.0);
  fTexture.Bind;
  glBegin(GL_QUADS);
    if FullyFilledBullets < Bullets then
      begin
      glColor4f(1, 1, 1, 1);
      glTexCoord2f(FullyFilledBullets + 1, 0.5); glVertex2f(pb.Left + BulletSize * (FullyFilledBullets + 1), pb.Top);
      glTexCoord2f(Bullets, 0.5); glVertex2f(pb.Left + BulletSize * Bullets, pb.Top);
      glTexCoord2f(Bullets, 1); glVertex2f(pb.Left + BulletSize * Bullets, pb.Top + BulletSize);
      glTexCoord2f(FullyFilledBullets + 1, 1); glVertex2f(pb.Left + BulletSize * (FullyFilledBullets + 1), pb.Top + BulletSize);

      glColor4f(1, 1, 1, 1 - MiddleBulletPercentage);
      glTexCoord2f(0, 0.5); glVertex2f(pb.Left + BulletSize * FullyFilledBullets, pb.Top);
      glTexCoord2f(1, 0.5); glVertex2f(pb.Left + BulletSize * (1 + FullyFilledBullets), pb.Top);
      glTexCoord2f(1, 1); glVertex2f(pb.Left + BulletSize * (1 + FullyFilledBullets), pb.Top + BulletSize);
      glTexCoord2f(0, 1); glVertex2f(pb.Left + BulletSize * FullyFilledBullets, pb.Top + BulletSize);

      glColor4f(1, 1, 1, MiddleBulletPercentage);
      glTexCoord2f(0, 0); glVertex2f(pb.Left + BulletSize * FullyFilledBullets, pb.Top);
      glTexCoord2f(1, 0); glVertex2f(pb.Left + BulletSize * (1 + FullyFilledBullets), pb.Top);
      glTexCoord2f(1, 0.5); glVertex2f(pb.Left + BulletSize * (1 + FullyFilledBullets), pb.Top + BulletSize);
      glTexCoord2f(0, 0.5); glVertex2f(pb.Left + BulletSize * FullyFilledBullets, pb.Top + BulletSize);
      end;

    glColor4f(1, 1, 1, 1);
    glTexCoord2f(FullyFilledBullets, 0); glVertex2f(pb.Left + BulletSize * FullyFilledBullets, pb.Top);
    glTexCoord2f(0, 0); glVertex2f(pb.Left, pb.Top);
    glTexCoord2f(0, 0.5); glVertex2f(pb.Left, pb.Top + BulletSize);
    glTexCoord2f(FullyFilledBullets, 0.5); glVertex2f(pb.Left + BulletSize * FullyFilledBullets, pb.Top + BulletSize);
  glEnd;

  fTexture.Unbind;
end;

destructor TModuleGUIProgressBarDefault.Free;
begin
  fTexture.Free;
end;

end.