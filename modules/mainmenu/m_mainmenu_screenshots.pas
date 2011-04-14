unit m_mainmenu_screenshots;

interface

uses
  m_module, SysUtils, Classes, m_gui_class, m_gui_window_class, m_gui_button_class, m_mainmenu_class, m_texmng_class, m_gui_iconifiedbutton_class,
  m_gui_edit_class, DGLOpenGL;

type
  TModuleMainMenuScreenshots = class(TModuleMainMenuClass)
    protected
      fWindow: TGUIComponent;
      fTime: Integer;
      fTexture: TTexture;
      fFiles: TStringList;
      fCurrentFile: Integer;
      fLogo: TTexture;
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
  u_functions, m_varlist, main;

type
  TMainMenuButton = class
    protected
      fCaption: String;
      fIconButton: TIconifiedButton;
      fButton: TButton;
      fTop, fLeft, fTag: Integer;
      fOnClick: TCallbackProcedure;
      procedure SetCaption(C: String);
      procedure SetLeft(A: Integer);
      procedure SetTop(A: Integer);
      procedure SetTag(A: Integer);
      procedure SetOnClick(A: TCallbackProcedure);
    public
      property IconButton: TIconifiedButton read fIconButton;
      property Button: TButton read fButton;
      property Tag: Integer read fTag write setTag;
      property Caption: String read fCaption write setCaption;
      property Left: Integer read fLeft write setLeft;
      property Top: Integer read fTop write setTop;
      property OnClick: TCallbackProcedure read fOnClick write setOnClick;
      constructor Create(Parent: TGUIComponent);
      destructor Free;
    end;

procedure TMainMenuButton.SetCaption(C: String);
begin
  fCaption := C;
  fButton.Caption := '    ' + C;
  fButton.Width := ModuleManager.ModFont.CalculateTextWidth(ModuleManager.ModLanguage.Translate('    ' + C), 24) + 16;
end;

procedure TMainMenuButton.SetLeft(A: Integer);
begin
  fLeft := A;
  fButton.Left := A + 56 - ModuleManager.ModFont.CalculateTextWidth('    ', 24);
  fIconButton.Left := A;
end;

procedure TMainMenuButton.SetTop(A: Integer);
begin
  fTop := A;
  fButton.Top := A + 12;
  fIconButton.Top := A;
end;

procedure TMainMenuButton.SetTag(A: Integer);
begin
  fTag := A;
  fButton.Tag := A;
  fIconButton.Tag := A;
end;

procedure TMainMenuButton.SetOnClick(A: TCallbackProcedure);
begin
  fOnClick := A;
  fButton.OnClick := A;
  fIconButton.OnClick := A;
end;

constructor TMainMenuButton.Create(Parent: TGUIComponent);
begin
  fButton := TButton.Create(Parent);
  fButton.Height := 40;
  fButton.Caption := '';
  fIconButton := TIconifiedButton.Create(Parent);
  fIconButton.Height := 64;
  fIconButton.Width := 64;
end;

destructor TMainMenuButton.Free;
begin
  fIconButton.Free;
  fButton.Free;
end;

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
  fWindow.Left := -16;

  fCurrentFile := 0;

  GetFilesInDirectory(ModuleManager.ModPathes.DataPath + 'screenshots', '*.tga', fFiles, true, true);
  GetFilesInDirectory(ModuleManager.ModPathes.DataPath + 'screenshots', '*.dbcg', fFiles, true, false);
  if ModuleManager.ModPathes.DataPath <> ModuleManager.ModPathes.PersonalDataPath then
    begin
    GetFilesInDirectory(ModuleManager.ModPathes.PersonalDataPath + 'screenshots', '*.tga', fFiles, true, false);
    GetFilesInDirectory(ModuleManager.ModPathes.PersonalDataPath + 'screenshots', '*.dbcg', fFiles, true, false);
    end;

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
  fTime := fTime + Round(FPSDisplay.MS);

  if fTime >= 10000 then
    begin
    fTime := 0;
    SetTexture;
    end;

  ModuleManager.ModGLContext.GetResolution(ResX, ResY);

  glMatrixMode(GL_PROJECTION);
  ModuleManager.ModGLMng.SetUp2DMatrix;
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;

  fTexture.Bind(0);
  glColor4f(1, 1, 1, 1);
  glBegin(GL_QUADS);
    glTexCoord2f(0, 0); glVertex3f(0,    0,    -255);
    glTexCoord2f(0, 1); glVertex3f(0,    ResY, -255);
    glTexCoord2f(1, 1); glVertex3f(ResX, ResY, -255);
    glTexCoord2f(1, 0); glVertex3f(ResX, 0,    -255);
  glEnd;
  fTexture.Unbind;

  fLogo.Bind(0);
  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  glBegin(GL_QUADS);
    glTexCoord2f(0, 0); glVertex3f(ResX - 440,  ResY - 230, -255);
    glTexCoord2f(0, 1); glVertex3f(ResX - 440,  ResY - 20,  -255);
    glTexCoord2f(1, 1); glVertex3f(ResX - 20,   ResY - 20,  -255);
    glTexCoord2f(1, 0); glVertex3f(ResX - 20,   ResY - 230, -255);
  glEnd;
  glDisable(GL_BLEND);
  fLogo.Unbind;
end;

constructor TModuleMainMenuScreenshots.Create;
begin
  fModName := 'MainMenuScreenshots';
  fModType := 'MainMenu';

  fTexture := nil;

  fFiles := TStringList.Create;

  fWindow := TGUIComponent.Create(nil, CLabel);
  fWindow.Height := 400;
  fWindow.Width := 400;
  fWindow.Left := -200;
  fWindow.Top := 100;
  fWindow.Render;

  with TMainMenuButton.Create(fWindow) do
    begin
    Left := 24;
    Top := 24;
    Caption := 'New game';
    IconButton.Icon := 'user-online.tga';
    Tag := MMVAL_STARTGAME;
    OnClick := @SetValue;
    end;

  with TMainMenuButton.Create(fWindow) do
    begin
    Left := 24;
    Top := 88;
    Caption := 'Load park';
    IconButton.Icon := 'folder-open.tga';
    Tag := MMVAL_LOADGAME;
    OnClick := @SetValue;
    end;

  with TMainMenuButton.Create(fWindow) do
    begin
    Left := 24;
    Top := 152;
    Caption := 'Settings';
    IconButton.Icon := 'configure.tga';
    Tag := MMVAL_SETTINGS;
    OnClick := @SetValue;
    end;

  with TMainMenuButton.Create(fWindow) do
    begin
    Left := 24;
    Top := 216;
    Caption := 'Help';
    IconButton.Icon := 'system-help.tga';
    Tag := MMVAL_HELP;
    OnClick := @SetValue;
    end;

  with TMainMenuButton.Create(fWindow) do
    begin
    Left := 24;
    Top := 280;
    Caption := 'Quit';
    IconButton.Icon := 'user-offline.tga';
    Tag := MMVAL_QUIT;
    OnClick := @SetValue;
    end;

  fLogo := TTexture.Create;
  fLogo.FromFile('general/orcf-logo.tga');
  fLogo.CreateMipmaps;
end;

destructor TModuleMainMenuScreenshots.Free;
begin
  fFiles.Free;
  if fTexture <> nil then
    fTexture.Free;
  fLogo.Free;
end;

procedure TModuleMainMenuScreenshots.CheckModConf;
begin
end;


end.