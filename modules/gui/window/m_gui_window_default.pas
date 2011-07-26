unit m_gui_window_default;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_gui_window_class, m_texmng_class, m_shdmng_class, DGLOpenGL, m_renderer_owe_classes;

type
  TModuleGUIWindowDefault = class(TModuleGUIWindowClass)
    protected
      fTexture, fBGTexture: TTexture;
      fShader, fDrawShader: TShader;
      fShadowFBO: TFBO;
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

  fShadowFBO := TFBO.Create(X, Y, false);
  fShadowFBO.AddTexture(GL_RGBA, GL_NEAREST, GL_NEAREST);
  fShadowFBO.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);
  fShadowFBO.Textures[0].Unbind;
  fShadowFBO.Unbind;

  fBGTexture := TTexture.Create;
  fBGTexture.CreateNew(X, Y, GL_RGBA);
  fBGTexture.SetClamp(GL_CLAMP, GL_CLAMP);

  fTexture := TTexture.Create;
  fTexture.FromFile(GetConfVal('background'));
  fTexture.SetFilter(GL_NEAREST, GL_NEAREST);
  fTexture.SetClamp(GL_CLAMP, GL_CLAMP);

  fShader := TShader.Create('guiwindowdefault/blur.vs', 'guiwindowdefault/blur.fs');
  fShader.Bind;
  fShader.UniformI('BackTex', 1);
  fShader.UniformI('WinTex', 0);
  fShader.UniformF('Screen', X, Y);
  fShader.Unbind;

  fDrawShader := TShader.Create('guiwindowdefault/draw.vs', 'guiwindowdefault/draw.fs');
  fDrawShader.Bind;
  fDrawShader.UniformI('Mask', 0);
  fDrawShader.Unbind;
end;

destructor TModuleGUIWindowDefault.Free;
begin
  fShadowFBO.Free;
  fDrawShader.Free;
  fShader.Free;
  fTexture.Free;
end;

procedure TModuleGUIWindowDefault.CheckModConf;
begin
  if GetConfVal('used') = '' then
    begin
    SetConfVal('used', '1');
    SetConfVal('background', 'guiwindowdefault/bg.tga');
    end;
end;

procedure TModuleGUIWindowDefault.Render(Window: TWindow);
const
  B = 8; // Edge offset
  A = B / 32;

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
  if not Window.HasBackground then
    exit;

  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  glEnable(GL_ALPHA_TEST);
  glAlphaFunc(GL_GREATER, 0.0);

  glColor4f(1, 1, 1, Window.Alpha);

  fTexture.Bind(0);
  fBGTexture.Bind(1);

  glCopyTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 0, 0, X, Y, 0);

  fShader.Bind;
  fShader.UniformI('UseWinTex', 1);
  fShader.UniformF('BlurAmount', Window.Alpha, 0.0);
  RenderWindow;
  glCopyTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 0, 0, X, Y, 0);

  fShader.UniformF('BlurAmount', 0.0, Window.Alpha);
  RenderWindow;
  glCopyTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 0, 0, X, Y, 0);

  fShader.Unbind;
  fDrawShader.Bind;
  fDrawShader.UniformF('LeftOffset', Window.Left / 2);
  fTexture.Bind(0);

  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  glColor4f(212 / 255, 236 / 255, 236 / 255, 0.2 * Window.Alpha);
  RenderWindow;

  glDisable(GL_BLEND);

  fShadowFBO.Bind;
  glClearColor(0, 0, 0, 0);
  glClear(GL_COLOR_BUFFER_BIT);
  glColor4f(0, 0, 0, 1);
  fDrawShader.Bind;
  fTexture.Bind(0);
  RenderWindow;

  fBGTexture.Bind(1);
  glCopyTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 0, 0, X, Y, 0);

  fShader.Bind;
  fShader.UniformI('UseWinTex', 0);
  fShader.UniformF('BlurAmount', Window.Alpha, 0.0);
  glBegin(GL_QUADS);
    glTexCoord2f(0, 0); glVertex2f(0, 0);
    glTexCoord2f(1, 0); glVertex2f(X, 0);
    glTexCoord2f(1, 1); glVertex2f(X, Y);
    glTexCoord2f(0, 1); glVertex2f(0, Y);
  glEnd;

  glCopyTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 0, 0, X, Y, 0);

  fShader.UniformF('BlurAmount', 0.0, Window.Alpha);
  glBegin(GL_QUADS);
    glTexCoord2f(0, 0); glVertex2f(0, 0);
    glTexCoord2f(1, 0); glVertex2f(X, 0);
    glTexCoord2f(1, 1); glVertex2f(X, Y);
    glTexCoord2f(0, 1); glVertex2f(0, Y);
  glEnd;

  fDrawShader.Bind;
  fTexture.Bind(0);
  glColor4f(0, 0, 0, 1 / 255);
  RenderWindow;

  fShadowFBO.Unbind;

  fBGTexture.Unbind;
  fTexture.Unbind;
  fDrawShader.Unbind;

  glEnable(GL_BLEND);

  fShadowFBO.Textures[0].Bind(0);
  glColor4f(1, 1, 1, Window.Alpha);
  glBegin(GL_QUADS);
    glTexCoord2f(0, 1); glVertex2f(0, 0);
    glTexCoord2f(1, 1); glVertex2f(X, 0);
    glTexCoord2f(1, 0); glVertex2f(X, Y);
    glTexCoord2f(0, 0); glVertex2f(0, Y);
  glEnd;
  fShadowFBO.Textures[0].Unbind;

  if (Window.Left + Window.Width - Window.OfsX2 > Window.Left + Window.OfsX1) and (Window.Top + Window.Height - Window.OfsY2 > Window.Top + Window.OfsY1) then
    begin
    glColor4f(1, 1, 1, Window.Alpha);
    glBegin(GL_QUADS);
      glVertex2f(Round(Window.Left + 7 + Window.OfsX1), Round(Window.Top + 8 + Window.OfsY1));
      glVertex2f(Round(Window.Left + Window.Width - 8 - Window.OfsX2), Round(Window.Top + 8 + Window.OfsY1));
      glVertex2f(Round(Window.Left + Window.Width - 8 - Window.OfsX2), Round(Window.Top + Window.Height - 7 - Window.OfsY2));
      glVertex2f(Round(Window.Left + 7 + Window.OfsX1), Round(Window.Top + Window.Height - 7 - Window.OfsY2));
    glEnd;

    glColor4f(0, 0, 0, Window.Alpha);
    glBegin(GL_LINE_LOOP);
      glVertex2f(Round(Window.Left + 7 + Window.OfsX1), Round(Window.Top + 7 + Window.OfsY1));
      glVertex2f(Round(Window.Left + Window.Width - 7 - Window.OfsX2), Round(Window.Top + 7 + Window.OfsY1));
      glVertex2f(Round(Window.Left + Window.Width - 7 - Window.OfsX2), Round(Window.Top + Window.Height - 7 - Window.OfsY2));
      glVertex2f(Round(Window.Left + 7 + Window.OfsX1), Round(Window.Top + Window.Height - 7 - Window.OfsY2));
    glEnd;
    end;

  glDisable(GL_BLEND);
end;

end.

