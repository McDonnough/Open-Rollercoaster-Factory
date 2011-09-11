unit m_mainmenu_modern;

interface

uses
  m_module, SysUtils, Classes, m_gui_class, m_gui_window_class, m_gui_button_class, m_mainmenu_class, m_texmng_class, m_gui_iconifiedbutton_class,
  m_gui_edit_class, DGLOpenGL, m_gui_label_class, m_gui_image_class;

type
  TImageButton = class
    protected
      fParent: TGUIComponent;
      fHoverImage, fImage: TImage;
      fCaption: String;
      fOnClick: TCallbackProcedure;
      fLabel: TLabel;
      fTop, fLeft, fTag: Integer;
      procedure SetCaption(C: String);
      procedure SetLeft(A: Integer);
      procedure SetTop(A: Integer);
      procedure SetTag(A: Integer);
      procedure SetOnClick(A: TCallbackProcedure);
    public
      TextLabelTop, TextLabelLeft: Integer;
      property TextLabel: TLabel read fLabel;
      property Image: TImage read fImage;
      property HoverImage: TImage read fHoverImage;
      property Left: Integer read fLeft write setLeft;
      property Top: Integer read fTop write setTop;
      property Tag: Integer read fTag write setTag;
      property OnClick: TCallbackProcedure read fOnClick write SetOnClick;
      property Caption: String read fCaption write setCaption;
      constructor Create(ImageName: String; TheParent: TGUIComponent; HoverImageName: String = '');
      destructor Free;
    end;

  TMainMenuDescriptionUI = class
    protected
      fContainer: TLabel;
      fIcon: TIconifiedButton;
      fTitle, fDescription: TLabel;
      procedure fSetShown(A: Boolean);
    public
      property Shown: Boolean write fSetShown;
      property Container: TLabel read fContainer;
      property Icon: TIconifiedButton read fIcon;
      property Title: TLabel read fTitle;
      property Description: TLabel read fDescription;
      procedure Hide;
      procedure Show;
      constructor Create(TheParent: TGUIComponent);
    end;

  TModuleMainMenuModern = class(TModuleMainMenuClass)
    protected
      ResX, ResY: Integer;
      fLogo, fLogoBG: TImage;
      fCoasterTrack: TImage;
      fWindow: TWindow;
      fQuit, fVersion: TImageButton;
      fNew, fLoad, fSettings, fHelp: TImageButton;
      fImageButtons: Array[1..4] of TImageButton;
      fMainDescription, fNewDescription, fLoadDescription, fSettingsDescription, fHelpDescription: TMainMenuDescriptionUI;
      fDescriptionContainer: TImage;
      procedure MoveQuitButtonLeft(Sender: TGUIComponent);
      procedure MoveQuitButtonRight(Sender: TGUIComponent);
      procedure SetMenuState(Sender: TGUIComponent);
      procedure HighlightItem(Sender: TGUIComponent);
      procedure UnHighlightItem(Sender: TGUIComponent);
      procedure KeyPressed(Sender: TGUIComponent; Key: Integer);
    public
      fMainBackground: TTexture;
      property MainBackground: TTexture read fMainBackground;
      procedure Render;
      procedure Setup;
      procedure Hide;
      procedure CheckModConf;
      constructor Create;
      destructor Free;
    end;

implementation

uses
  u_functions, m_varlist, main, u_vectors, m_inputhandler_class;

procedure TMainMenuDescriptionUI.Hide;
begin
  fContainer.Alpha := 0;
  fIcon.Alpha := 0;
  fTitle.Alpha := 0;
  fDescription.Alpha := 0;
end;

procedure TMainMenuDescriptionUI.Show;
begin
  fContainer.Alpha := 1;
  fIcon.Alpha := 1;
  fTitle.Alpha := 1;
  fDescription.Alpha := 1;
end;

procedure TMainMenuDescriptionUI.fSetShown(A: Boolean);
begin
  if A then
    Show
  else
    Hide;
end;

constructor TMainMenuDescriptionUI.Create(TheParent: TGUIComponent);
begin
  fContainer := TLabel.Create(TheParent);
  fContainer.Width := 568;
  fContainer.Left := 16;
  fContainer.Top := 16;
  fContainer.Height := 314;

  fIcon := TIconifiedButton.Create(fContainer);
  fIcon.Top := 0;
  fIcon.Left := 0;
  fIcon.Height := 64;
  fIcon.Width := 64;

  fTitle := TLabel.Create(fContainer);
  fTitle.Left := 72;
  fTitle.Top := 16;
  fTitle.Width := 496;
  fTitle.Height := 32;
  fTitle.Size := 32;

  fDescription := TLabel.Create(fContainer);
  fDescription.Top := 72;
  fDescription.Left := 0;
  fDescription.Height := 178;
  fDescription.Width := 568;
  fDescription.Size := 24;
  
  Hide;
end;

procedure TImageButton.SetCaption(C: String);
begin
  fCaption := C;
  fLabel.Caption := C;
  fLabel.Width := ModuleManager.ModFont.CalculateTextWidth(ModuleManager.ModLanguage.Translate(C), 24) + 16;
end;

procedure TImageButton.SetLeft(A: Integer);
begin
  fLeft := A;
  fLabel.Left := A + TextLabelLeft;
  fImage.Left := A;
  if fHoverImage <> nil then
    fHoverImage.Left := A;
end;

procedure TImageButton.SetTop(A: Integer);
begin
  fTop := A;
  fLabel.Top := A + TextLabelTop;
  fImage.Top := A;
  if fHoverImage <> nil then
    fHoverImage.Top := A;
end;

procedure TImageButton.SetTag(A: Integer);
begin
  fTag := A;
  fLabel.Tag := A;
  fImage.Tag := A;
  if fHoverImage <> nil then
    fHoverImage.Tag := A;
end;

procedure TImageButton.SetOnClick(A: TCallbackProcedure);
begin
  fOnClick := A;
  fLabel.OnClick := A;
  fImage.OnClick := A;
  if fHoverImage <> nil then
    fHoverImage.OnClick := A;
end;

constructor TImageButton.Create(ImageName: String; TheParent: TGUIComponent; HoverImageName: String = '');
begin
  fParent := TheParent;

  TextLabelLeft := 4;
  TextLabelTop := 4;

  fImage := TImage.Create(TheParent);
  fImage.Tex := TTexture.Create;
  fImage.Tex.FromFile('mainmenumodern/' + ImageName + '.tga', false, false);
  fImage.FreeTextureOnDestroy := True;
  fImage.Width := fImage.Tex.Width;
  fImage.Height := fImage.Tex.Height;

  fHoverImage := nil;
  if HoverImageName <> '' then
    begin
    fHoverImage := TImage.Create(TheParent);
    fHoverImage.FreeTextureOnDestroy := True;
    fHoverImage.Tex := TTexture.Create;
    fHoverImage.Tex.FromFile('mainmenumodern/' + HoverImageName + '.tga', false, false);
    fHoverImage.Width := fHoverImage.Tex.Width;
    fHoverImage.Height := fHoverImage.Tex.Height;
    fHoverImage.Alpha := 0;
    end;

  fLabel := TLabel.Create(TheParent);
  fLabel.Height := fImage.Tex.Height - 8;
  fLabel.Size := fImage.Tex.Height - 8;
  fLabel.Top := 4;
  fLabel.Left := 4;
end;

destructor TImageButton.Free;
begin
  fImage.Free;
  fLabel.Free;
end;

procedure TModuleMainMenuModern.KeyPressed(Sender: TGUIComponent; Key: Integer);
begin
  case Key of
    K_o: fValue := MMVAL_OBJECTCREATOR;
    K_s: fValue := MMVAL_SETCREATOR;
    end;
  ModuleManager.ModGUI.BasicComponent.BringToFront(fLogoBG);
end;

procedure TModuleMainMenuModern.MoveQuitButtonLeft(Sender: TGUIComponent);
begin
  fQuit.Left := ResX - 48 - ModuleManager.ModFont.CalculateTextWidth(fQuit.Caption, 24);
end;

procedure TModuleMainMenuModern.MoveQuitButtonRight(Sender: TGUIComponent);
begin
  fQuit.Left := ResX - 32;
end;

procedure TModuleMainMenuModern.Setup;
begin
  Reset;
  fLogoBG.Left := 400 - 146 - 32 + (ResX - 800) / 2;
  fQuit.Left := ResX - 32;
  fVersion.Left := ResX - 32 - ModuleManager.ModFont.CalculateTextWidth(fVersion.Caption, 24);
  if fMainBackground = nil then
    begin
    fMainBackground := TTexture.Create;
    fMainBackground.FromFile('mainmenumodern/background.tga', false, false);
    end;
  fWindow.Left := -32;
end;

procedure TModuleMainMenuModern.Hide;
begin
  fLogoBG.Left := -384;
  fQuit.Left := ResX;
  fVersion.Left := ResX;
  fWindow.Left := -ResX;
end;

procedure TModuleMainMenuModern.Render;
begin
  glMatrixMode(GL_PROJECTION);
  ModuleManager.ModGLMng.SetUp2DMatrix;
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;

  glColor4f(1, 1, 1, 1);
  if fMainBackground <> nil then
    fMainBackground.Bind(0);
  glBegin(GL_QUADS);
    glTexCoord2f(0, 0); glVertex3f(0 - ((2048 - ResX) div 2),    0,    -255);
    glTexCoord2f(0, 1); glVertex3f(0 - ((2048 - ResX) div 2),    2048, -255);
    glTexCoord2f(1, 1); glVertex3f(2048 - ((2048 - ResX) div 2), 2048, -255);
    glTexCoord2f(1, 0); glVertex3f(2048 - ((2048 - ResX) div 2), 0,    -255);
  glEnd;
  if fMainBackground <> nil then
    fMainBackground.Unbind;
end;

procedure TModuleMainMenuModern.SetMenuState(Sender: TGUIComponent);
begin
  fValue := Sender.Tag;
  ModuleManager.ModGUI.BasicComponent.BringToFront(fLogoBG);
end;

procedure TModuleMainMenuModern.HighlightItem(Sender: TGUIComponent);
begin
  fMainDescription.Shown := False;
  fNewDescription.Shown := Sender.Tag = MMVAL_STARTGAME;
  fLoadDescription.Shown := Sender.Tag = MMVAL_LOADGAME;
  fSettingsDescription.Shown := Sender.Tag = MMVAL_SETTINGS;
  fHelpDescription.Shown := Sender.Tag = MMVAL_HELP;
  if (Sender.Tag >= 1) and (Sender.Tag <= 4) then
    if fImageButtons[Sender.Tag].HoverImage <> nil then
      fImageButtons[Sender.Tag].HoverImage.Alpha := 1;
end;

procedure TModuleMainMenuModern.UnHighlightItem(Sender: TGUIComponent);
begin
  fMainDescription.Shown := True;
  fNewDescription.Shown := False;
  fLoadDescription.Shown := False;
  fSettingsDescription.Shown := False;
  fHelpDescription.Shown := False;
  if (Sender.Tag >= 1) and (Sender.Tag <= 4) then
    if fImageButtons[Sender.Tag].HoverImage <> nil then
      fImageButtons[Sender.Tag].HoverImage.Alpha := 0;
end;

constructor TModuleMainMenuModern.Create;
begin
  fModName := 'MainMenuModern';
  fModType := 'MainMenu';

  ModuleManager.ModGLContext.GetResolution(ResX, ResY);

  fMainBackground := nil;
  fLogoBG := nil;

  fWindow := TWindow.Create(nil);
  fWindow.Left := -ResX;
  fWindow.Top := 64 + (ResY - 600) / 2;
  fWindow.Width := ResX - 32;
  fWindow.Height := 488;
  fWindow.OfsX2 := 768;
  fWindow.OfsY2 := 488;
  fWindow.OnKeyDown := @KeyPressed;

  fCoasterTrack := TImage.Create(fWindow);
  fCoasterTrack.Tex := TTexture.Create;
  fCoasterTrack.Tex.FromFile('mainmenumodern/coastertrack.tga', false, false);
  fCoasterTrack.FreeTextureOnDestroy := True;
  fCoasterTrack.Height := 64;
  fCoasterTrack.Width := 2048;
  fCoasterTrack.Top := 408;
  fCoasterTrack.Left := ResX - 88 - 2048;

  fDescriptionContainer := TImage.Create(fWindow);
  fDescriptionContainer.FreeTextureOnDestroy := True;
  fDescriptionContainer.Tex := TTexture.Create;
  fDescriptionContainer.Tex.FromFile('mainmenumodern/description-background.tga', false, false);
  fDescriptionContainer.Height := 286;
  fDescriptionContainer.Left := 100 + (ResX - 800) / 2;
  fDescriptionContainer.Width := 600;
  fDescriptionContainer.Top := 130;

  fLogoBG := TImage.Create(nil);
  fLogoBG.Left := -320;
  fLogoBG.Top := 24 + (ResY - 600) / 2;
  fLogoBG.Width := 292;
  fLogoBG.Height := 162;
  fLogoBG.FreeTextureOnDestroy := True;
  fLogoBG.Tex := TTexture.Create;
  fLogoBG.Tex.FromFile('mainmenumodern/logobg.tga', false, false);

  fLogo := TImage.Create(fLogoBG);
  fLogo.Left := 16;
  fLogo.Top := 16;
  fLogo.Width := 260;
  fLogo.Height := 130;
  fLogo.FreeTextureOnDestroy := True;
  fLogo.Tex := TTexture.Create;
  fLogo.Tex.FromFile('general/orcf-logo.tga');
  fLogo.Tex.CreateMipmaps;

  fQuit := TImageButton.Create('quit', nil);
  fQuit.Caption := 'Quit';
  fQuit.Image.OnHover := @MoveQuitButtonLeft;
  fQuit.Image.OnLeave := @MoveQuitButtonRight;
  fQuit.TextLabel.OnHover := @MoveQuitButtonLeft;
  fQuit.TextLabel.OnLeave := @MoveQuitButtonRight;
  fQuit.TextLabelLeft := 40;
  fQuit.TextLabelTop := 3;
  fQuit.Tag := MMVAL_QUIT;
  fQuit.Top := 0;
  fQuit.Left := ResX;
  fQuit.OnClick := @SetMenuState;

  fVersion := TImageButton.Create('version', nil);
  fVersion.Caption := 'Version $2011.10p$';
  fVersion.TextLabelLeft := 24;
  fVersion.TextLabelTop := 5;
  fVersion.Top := ResY - 32;
  fVersion.Left := ResX;
  fVersion.TextLabel.TextColor := Vector(1, 1, 1, 1);
  fVersion.Tag := MMVAL_QUIT;

  fNew := TImageButton.Create('button-tl', fWindow, 'button-tl-hl');
  fNew.Tag := MMVAL_STARTGAME;
  fNew.Caption := 'New game';
  fNew.TextLabel.TextColor := Vector(1, 1, 1, 1);
  fNew.TextLabelTop := 8;
  fNew.TextLabel.Height := 32;
  fNew.TextLabel.Size := 32;
  fNew.TextLabelLeft := 16;
  fNew.TextLabel.Width := 350 - 16;
  fNew.TextLabel.OnHover := @HighlightItem;
  fNew.TextLabel.OnLeave := @UnHighlightItem;
  fNew.Left := 50 + (ResX - 800) div 2;
  fNew.Top := 0;
  fNew.Image.OnHover := @HighlightItem;
  fNew.Image.OnLeave := @UnHighlightItem;
  fNew.HoverImage.OnHover := @HighlightItem;
  fNew.HoverImage.OnLeave := @UnHighlightItem;
  fNew.OnClick := @SetMenuState;

  fLoad := TImageButton.Create('button-bl', fWindow, 'button-bl-hl');
  fLoad.Tag := MMVAL_LOADGAME;
  fLoad.Caption := 'Load park';
  fLoad.TextLabel.TextColor := Vector(1, 1, 1, 1);
  fLoad.TextLabelTop := 8;
  fLoad.TextLabel.Height := 32;
  fLoad.TextLabel.Size := 32;
  fLoad.TextLabelLeft := 26;
  fLoad.TextLabel.Width := 350 - 26;
  fLoad.TextLabel.OnHover := @HighlightItem;
  fLoad.TextLabel.OnLeave := @UnHighlightItem;
  fLoad.Left := 50 + (ResX - 800) div 2;
  fLoad.Top := 46;
  fLoad.Image.OnHover := @HighlightItem;
  fLoad.Image.OnLeave := @UnHighlightItem;
  fLoad.HoverImage.OnHover := @HighlightItem;
  fLoad.HoverImage.OnLeave := @UnHighlightItem;
  fLoad.OnClick := @SetMenuState;

  fSettings := TImageButton.Create('button-tr', fWindow, 'button-tr-hl');
  fSettings.Tag := MMVAL_SETTINGS;
  fSettings.Caption := 'Settings';
  fSettings.TextLabel.TextColor := Vector(1, 1, 1, 1);
  fSettings.TextLabelTop := 8;
  fSettings.TextLabel.Height := 32;
  fSettings.TextLabel.Size := 32;
  fSettings.TextLabelLeft := 0;
  fSettings.TextLabel.Width := 350 - 16;
  fSettings.TextLabel.Align := LABEL_ALIGN_RIGHT;
  fSettings.TextLabel.OnHover := @HighlightItem;
  fSettings.TextLabel.OnLeave := @UnHighlightItem;
  fSettings.Left := 400 + (ResX - 800) div 2;
  fSettings.Top := 0;
  fSettings.Image.OnHover := @HighlightItem;
  fSettings.Image.OnLeave := @UnHighlightItem;
  fSettings.HoverImage.OnHover := @HighlightItem;
  fSettings.HoverImage.OnLeave := @UnHighlightItem;
  fSettings.OnClick := @SetMenuState;

  fHelp := TImageButton.Create('button-br', fWindow, 'button-br-hl');
  fHelp.Tag := MMVAL_HELP;
  fHelp.Caption := 'Help';
  fHelp.TextLabel.TextColor := Vector(1, 1, 1, 1);
  fHelp.TextLabelTop := 8;
  fHelp.TextLabel.Height := 32;
  fHelp.TextLabel.Size := 32;
  fHelp.TextLabelLeft := 0;
  fHelp.TextLabel.Width := 350 - 26;
  fHelp.TextLabel.Align := LABEL_ALIGN_RIGHT;
  fHelp.TextLabel.OnHover := @HighlightItem;
  fHelp.TextLabel.OnLeave := @UnHighlightItem;
  fHelp.Left := 400 + (ResX - 800) div 2;
  fHelp.Top := 46;
  fHelp.Image.OnHover := @HighlightItem;
  fHelp.Image.OnLeave := @UnHighlightItem;
  fHelp.HoverImage.OnHover := @HighlightItem;
  fHelp.HoverImage.OnLeave := @UnHighlightItem;
  fHelp.OnClick := @SetMenuState;

  fMainDescription := TMainMenuDescriptionUI.Create(fDescriptionContainer);
  fMainDescription.Icon.Icon := 'dialog-information.tga';
  fMainDescription.Title.Caption := 'Welcome to ORCF';
  fMainDescription.Description.Caption := 'Open RollerCoaster Factory is a free, MPL-licensed' + #10
                                        + 'theme park simulation game.' + #10
                                        + 'This is a development release. Use at own risk.';

  fMainDescription.Show;

  fNewDescription := TMainMenuDescriptionUI.Create(fDescriptionContainer);
  fNewDescription.Icon.Icon := 'user-online.tga';
  fNewDescription.Title.Caption := 'New game';
  fNewDescription.Description.Caption := 'Start with an entirely empty park.';

  fLoadDescription := TMainMenuDescriptionUI.Create(fDescriptionContainer);
  fLoadDescription.Icon.Icon := 'folder-open.tga';
  fLoadDescription.Title.Caption := 'Load park';
  fLoadDescription.Description.Caption := 'Load an existing park file.';

  fSettingsDescription := TMainMenuDescriptionUI.Create(fDescriptionContainer);
  fSettingsDescription.Icon.Icon := 'configure.tga';
  fSettingsDescription.Title.Caption := 'Settings';
  fSettingsDescription.Description.Caption := 'Configure language, graphics, screen resolution' + #10 + 'and other things';

  fHelpDescription := TMainMenuDescriptionUI.Create(fDescriptionContainer);
  fHelpDescription.Icon.Icon := 'system-help.tga';
  fHelpDescription.Title.Caption := 'Help';
  fHelpDescription.Description.Caption := 'Get some basic help.';

  fImageButtons[MMVAL_STARTGAME] := fNew;
  fImageButtons[MMVAL_LOADGAME] := fLoad;
  fImageButtons[MMVAL_SETTINGS] := fSettings;
  fImageButtons[MMVAL_HELP] := fHelp;
end;

destructor TModuleMainMenuModern.Free;
begin
  if fLogoBG <> nil then
    fLogoBG.Free;
  if fMainBackground <> nil then
    fMainBackground.Free;
  fMainDescription.Free;
  fNewDescription.Free;
  fLoadDescription.Free;
  fSettingsDescription.Free;
  fHelpDescription.Free;
end;

procedure TModuleMainMenuModern.CheckModConf;
begin
end;


end.