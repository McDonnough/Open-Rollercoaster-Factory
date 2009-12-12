unit m_mainmenu_screenshots;

interface

uses
  m_module, SysUtils, Classes, m_gui_class, m_gui_window_class, m_gui_button_class, m_mainmenu_class, m_texmng_class, m_gui_iconifiedbutton_class, DGLOpenGL;

type
  TModuleMainMenuScreenshots = class(TModuleMainMenuClass)
    protected
      fWindow: TWindow;
      fTime: Integer;
      fTexture: TTexture;
      fFiles: TStringList;
      fCurrentFile: Integer;
      procedure SetValue(Sender: TGUIComponent);
      procedure SetTexture;
    public
      procedure Render;
      procedure Setup;
      procedure Hide;
      procedure CheckModConf;
      constructor Create;
      destructor Free;
    end;

implementation

uses
  u_functions, m_varlist;

procedure TModuleMainMenuScreenshots.SetTexture;
begin
  if fTexture <> nil then
    begin
    fTexture.Free;
    fTexture := nil;
    end;
  fTexture := TTexture.Create;
  if fCurrentFile < fFiles.Count - 1 then
    inc(fCurrentFile)
  else
    fCurrentFile := 0;
  if fCurrentFile < fFiles.Count then
    fTexture.FromFile(fFiles.Strings[fCurrentFile])
end;

procedure TModuleMainMenuScreenshots.SetValue(Sender: TGUIComponent);
begin
  fValue := Sender.Tag;
end;

procedure TModuleMainMenuScreenshots.Setup;
begin
  fTime := 0;

  fValue := 0;
  fWindow.Left := -32;

  fCurrentFile := 0;

  GetFilesInDirectory(ModuleManager.ModPathes.DataPath + 'screenshots', '*.tga', fFiles, true, true);
  GetFilesInDirectory(ModuleManager.ModPathes.PersonalDataPath + 'screenshots', '*.tga', fFiles, true, false);

  SetTexture;
end;

procedure TModuleMainMenuScreenshots.Hide;
begin
  fWindow.Left := -fWindow.Width;
end;

procedure TModuleMainMenuScreenshots.Render;
var
  ResX, ResY: Integer;
begin
  fTime := fTime + 1;

  if fTime >= 1000 then
    begin
    fTime := 0;
    SetTexture;
    end;

  ModuleManager.ModGLContext.GetResolution(ResX, ResY);

  glMatrixMode(GL_PROJECTION);
  ModuleManager.ModGLMng.SetUp2DMatrix;
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;

  fTexture.Bind;
  glColor4f(1, 1, 1, 1);
  glBegin(GL_QUADS);
    glTexCoord2f(0, 0); glVertex3f(0,    0,    -255);
    glTexCoord2f(0, 1); glVertex3f(0,    ResY, -255);
    glTexCoord2f(1, 1); glVertex3f(ResX, ResY, -255);
    glTexCoord2f(1, 0); glVertex3f(ResX, 0,    -255);
  glEnd;
  fTexture.Unbind;
end;

constructor TModuleMainMenuScreenshots.Create;
begin
  fModName := 'MainMenuScreenshots';
  fModType := 'MainMenu';

  fTexture := nil;

  fFiles := TStringList.Create;

  fWindow := TWindow.Create(nil);
  fWindow.Top := 100;
  fWindow.Width := 300;
  fWindow.Height := 400;
  fWindow.Left := -300;
  fWindow.Render;

  with TButton.Create(fWindow) do
    begin
    Left := 40;
    Width := 236;
    Height := 32;
    Top := 32;
    Caption := 'Start new game';
    Tag := MMVAL_STARTGAME;
    onClick := @SetValue;
    end;

  with TButton.Create(fWindow) do
    begin
    Left := 40;
    Width := 236;
    Height := 32;
    Top := 80;
    Caption := 'Load park';
    Tag := MMVAL_LOADGAME;
    onClick := @SetValue;
    end;

  with TButton.Create(fWindow) do
    begin
    Left := 40;
    Width := 236;
    Height := 32;
    Top := 128;
    Caption := 'Settings';
    Tag := MMVAL_SETTINGS;
    onClick := @SetValue;
    end;

  with TButton.Create(fWindow) do
    begin
    Left := 40;
    Width := 236;
    Height := 32;
    Top := 172;
    Caption := 'Help';
    Tag := MMVAL_HELP;
    onClick := @SetValue;
    end;

  with TButton.Create(fWindow) do
    begin
    Left := 40;
    Width := 236;
    Height := 32;
    Top := 220;
    Caption := 'Quit';
    Tag := MMVAL_QUIT;
    onClick := @SetValue;
    end;

  with TIconifiedButton.Create(fWindow) do
    begin
    Left := 40;
    Height := 64;
    Width := 64;
    Top := 268;
    Icon := 'dialog-ok-apply.png.tga';
    end;
end;

destructor TModuleMainMenuScreenshots.Free;
begin
  fFiles.Free;
  if fTexture <> nil then
    fTexture.Free;
end;

procedure TModuleMainMenuScreenshots.CheckModConf;
begin
end;


end.