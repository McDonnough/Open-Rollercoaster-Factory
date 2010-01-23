unit m_gui_window_default;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_gui_window_class, m_texmng_class, m_shdmng_class, DGLOpenGL;

type
  TModuleGUIWindowDefault = class(TModuleGUIWindowClass)
    protected
      fTexture, fBGTexture: TTexture;
      fShader: TShader;
      X, Y: Integer;
    public
      constructor Create;
      destructor Free;
      procedure CheckModConf;
      procedure Render(Window: TWindow);
    end;

implementation

uses
  m_varlist;

constructor TModuleGUIWindowDefault.Create;
begin
  fModName := 'GUIWindowDefault';
  fModType := 'GUIWindow';

  CheckModConf;

  ModuleManager.ModGLContext.GetResolution(X, Y);

  fBGTexture := TTexture.Create;
  fBGTexture.CreateNew(X, Y, GL_RGB);
  fBGTexture.SetClamp(GL_CLAMP, GL_CLAMP);

  fTexture := TTexture.Create;
  fTexture.FromFile(GetConfVal('background'));

  fShader := TShader.Create(ModuleManager.ModPathes.DataPath + 'guiwindowdefault/blur.vs', ModuleManager.ModPathes.DataPath + 'guiwindowdefault/blur.fs');
  fShader.Bind;
  fShader.UniformI('BackTex', 1);
  fShader.UniformI('WinTex', 0);
  fShader.UniformF('Screen', X, Y);
  fShader.Unbind;
end;

destructor TModuleGUIWindowDefault.Free;
begin
  fShader.Free;
  fTexture.Free;
end;

procedure TModuleGUIWindowDefault.CheckModConf;
begin
  if GetConfVal('used') = '' then
    begin
    SetConfVal('used', '1');
    SetConfVal('background', ModuleManager.ModPathes.DataPath + 'guiwindowdefault/bg.tga');
    end;
end;

procedure TModuleGUIWindowDefault.Render(Window: TWindow);
const
  B = 16; // Edge offset
  A = B / 256;

  procedure RenderWindow;
  begin
    glBegin(GL_QUADS);
      glTexCoord2f(0,     0);     glVertex3f(Window.Left,                    Window.Top,                     0);
      glTexCoord2f(A,     0);     glVertex3f(Window.Left + B,                Window.Top,                     0);
      glTexCoord2f(A,     A);     glVertex3f(Window.Left + B,                Window.Top + B,                 0);
      glTexCoord2f(0,     A);     glVertex3f(Window.Left,                    Window.Top + B,                 0);

      glTexCoord2f(A,     0);     glVertex3f(Window.Left + B,                Window.Top,                     0);
      glTexCoord2f(1 - A, 0);     glVertex3f(Window.Left + Window.Width - B, Window.Top,                     0);
      glTexCoord2f(1 - A, A);     glVertex3f(Window.Left + Window.Width - B, Window.Top + B,                 0);
      glTexCoord2f(A,     A);     glVertex3f(Window.Left + B,                Window.Top + B,                 0);

      glTexCoord2f(1,     0);     glVertex3f(Window.Left + Window.Width,     Window.Top,                     0);
      glTexCoord2f(1 - A, 0);     glVertex3f(Window.Left + Window.Width - B, Window.Top,                     0);
      glTexCoord2f(1 - A, A);     glVertex3f(Window.Left + Window.Width - B, Window.Top + B,                 0);
      glTexCoord2f(1,     A);     glVertex3f(Window.Left + Window.Width,     Window.Top + B,                 0);


      glTexCoord2f(0,     A);     glVertex3f(Window.Left,                    Window.Top + B,                 0);
      glTexCoord2f(A,     A);     glVertex3f(Window.Left + B,                Window.Top + B,                 0);
      glTexCoord2f(A,     1 - A); glVertex3f(Window.Left + B,                Window.Top + Window.Height - B, 0);
      glTexCoord2f(0,     1 - A); glVertex3f(Window.Left,                    Window.Top + Window.Height - B, 0);

      glTexCoord2f(A,     A);     glVertex3f(Window.Left + B,                Window.Top + B,                 0);
      glTexCoord2f(1 - A, A);     glVertex3f(Window.Left + Window.Width - B, Window.Top + B,                 0);
      glTexCoord2f(1 - A, 1 - A); glVertex3f(Window.Left + Window.Width - B, Window.Top + Window.Height - B, 0);
      glTexCoord2f(A,     1 - A); glVertex3f(Window.Left + B,                Window.Top + Window.Height - B, 0);

      glTexCoord2f(1,     A);     glVertex3f(Window.Left + Window.Width,     Window.Top + B,                 0);
      glTexCoord2f(1 - A, A);     glVertex3f(Window.Left + Window.Width - B, Window.Top + B,                 0);
      glTexCoord2f(1 - A, 1 - A); glVertex3f(Window.Left + Window.Width - B, Window.Top + Window.Height - B, 0);
      glTexCoord2f(1,     1 - A); glVertex3f(Window.Left + Window.Width,     Window.Top + Window.Height - B, 0);


      glTexCoord2f(0,     1);     glVertex3f(Window.Left,                    Window.Top + Window.Height,     0);
      glTexCoord2f(A,     1);     glVertex3f(Window.Left + B,                Window.Top + Window.Height,     0);
      glTexCoord2f(A,     1 - A); glVertex3f(Window.Left + B,                Window.Top + Window.Height - B, 0);
      glTexCoord2f(0,     1 - A); glVertex3f(Window.Left,                    Window.Top + Window.Height - B, 0);

      glTexCoord2f(A,     1);     glVertex3f(Window.Left + B,                Window.Top + Window.Height,     0);
      glTexCoord2f(1 - A, 1);     glVertex3f(Window.Left + Window.Width - B, Window.Top + Window.Height,     0);
      glTexCoord2f(1 - A, 1 - A); glVertex3f(Window.Left + Window.Width - B, Window.Top + Window.Height - B, 0);
      glTexCoord2f(A,     1 - A); glVertex3f(Window.Left + B,                Window.Top + Window.Height - B, 0);

      glTexCoord2f(1,     1);     glVertex3f(Window.Left + Window.Width,     Window.Top + Window.Height,     0);
      glTexCoord2f(1 - A, 1);     glVertex3f(Window.Left + Window.Width - B, Window.Top + Window.Height,     0);
      glTexCoord2f(1 - A, 1 - A); glVertex3f(Window.Left + Window.Width - B, Window.Top + Window.Height - B, 0);
      glTexCoord2f(1,     1 - A); glVertex3f(Window.Left + Window.Width,     Window.Top + Window.Height - B, 0);
    glEnd;
  end;

begin
  glColor4f(1, 1, 1, Window.Alpha);

  fTexture.Bind(0);
  fBGTexture.Bind(1);

  glCopyTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, 0, 0, X, Y, 0);

  fShader.Bind;
  fShader.UniformF('BlurAmount', Window.Alpha, 0.0);
  glBegin(GL_QUADS);
    RenderWindow;
  glEnd;
  glCopyTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, 0, 0, X, Y, 0);

  fShader.UniformF('BlurAmount', 0.0, Window.Alpha);
  glBegin(GL_QUADS);
    RenderWindow;
  glEnd;
  glCopyTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, 0, 0, X, Y, 0);

  fShader.Unbind;

  fTexture.Bind(0);

  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    RenderWindow;
  glDisable(GL_BLEND);

  fBGTexture.Unbind;
  fTexture.Unbind;
end;

end.

