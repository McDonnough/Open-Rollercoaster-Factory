unit m_loadscreen_default;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_loadscreen_class, m_texmng_class, DGLOpenGL, m_gui_window_class, m_gui_label_class, m_gui_progressbar_class, m_gui_button_class;

type
  TModuleLoadScreenDefault = class(TModuleLoadScreenClass)
    protected
      W, H: Integer;
      fTexture: TTexture;
      fWindow: TWindow;
      fHLabel, fTLabel: TLabel;
      fPB: TProgressBar;
      fVisible: Boolean;
    public
      constructor Create;
      destructor Free;
      procedure CheckModConf;
      procedure Render;
      procedure SetVisibility(Visible: Boolean);
    end;

implementation

uses
  m_varlist, m_gui_class;

constructor TModuleLoadScreenDefault.Create;
begin
  fModName := 'LoadScreenDefault';
  fModType := 'LoadScreen';

  CheckModConf;

  fTexture := TTexture.Create;
  fTexture.FromFile(GetConfVal('background'));
  fTexture.SetFilter(GL_NEAREST, GL_NEAREST);
  fTexture.SetClamp(GL_MIRRORED_REPEAT, GL_MIRRORED_REPEAT);

  ModuleManager.ModGLContext.GetResolution(W, H);

  fWindow := TWindow.Create(nil);
  fWindow.Left := (W - 450) div 2;
  fWindow.Top := -200;
  fWindow.Height := 120;
  fWindow.Width := 450;

  fHLabel := TLabel.Create(fWindow);
  fHLabel.Size := 16;
  fHLabel.Left := 16;
  fHLabel.Top := 16;
  fHLabel.Width := 418;
  fHLabel.Height := 16;

  fTLabel := TLabel.Create(fWindow);
  fTLabel.Size := 12;
  fTLabel.Left := 32;
  fTLabel.Top := 48;
  fTLabel.Width := 386;
  fTLabel.Height := 12;

  fPB := TProgressBar.Create(fWindow);
  fPB.Left := 32;
  fPB.Top := 56;
  fPB.Width := 386;
  fPB.Height := 64;

  SetVisibility(false);
  fWindow.Render;
end;

procedure TModuleLoadScreenDefault.CheckModConf;
begin
  if GetConfVal('used') = '' then
    begin
    SetConfVal('used', '1');
    SetConfVal('background', ModuleManager.ModPathes.DataPath + 'loadscreendefault/default.tga');
    end;
end;

procedure TModuleLoadScreenDefault.Render;
begin
  fPB.Progress := Progress;
  fHLabel.Caption := Headline;
  fTLabel.Caption := Text;

  glMatrixMode(GL_PROJECTION);
  ModuleManager.ModGLMng.SetUp2DMatrix;
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;

  fTexture.Bind;
  glColor4f(1, 1, 1, 1);
  glBegin(GL_QUADS);
    glTexCoord2f(0, 0); glVertex3f(0,    0,    -255);
    glTexCoord2f(0, 2); glVertex3f(0,    2048, -255);
    glTexCoord2f(2, 2); glVertex3f(4096, 2048, -255);
    glTexCoord2f(2, 0); glVertex3f(4096, 0,    -255);
  glEnd;
  fTexture.Unbind;
end;


procedure TModuleLoadScreenDefault.SetVisibility(Visible: Boolean);
begin
  fVisible := Visible;
  if Visible then
    begin
    fWindow.Top := (H - 120) div 2;
    fWindow.Alpha := 1;
    end
  else
    begin
    fWindow.Top := -200;
    fWindow.Alpha := 0;
    end;
end;

destructor TModuleLoadScreenDefault.Free;
begin
  fWindow.Free;
  fTexture.Free;
end;

end.

