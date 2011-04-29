unit m_varlist;

{$mode objfpc}{$H+}

interface
    {$IFDEF WINDOWS}
    {$I typedef_windows.inc}
    {$ELSE}
	{$I typedef.inc}
	{$ENDIF}

  TModuleManager = class
    protected
      fModModuleConfig: TModuleConfig;
      fModPathes: TModulePathes;
      fModLog: TModuleLog;
      fModLanguage: TModuleLanguage;
      fModGLContext: TModuleGLContext;
      fModGLMng: TModuleGLMng;
      fModInputHandler: TModuleInputHandler;
      fModTexMng: TModuleTextureManager;
      fModShdMng: TModuleShaderManager;
      fModFont: TModuleFont;
      fModGUI: TModuleGUI;
      fModGUIWindow: TModuleGUIWindow;
      fModGUILabel: TModuleGUILabel;
      fModGUIImage: TModuleGUIImage;
      fModGUITabBar: TModuleGUITabBar;
      fModGUIScrollBox: TModuleGUIScrollBox;
      fModGUIProgressBar: TModuleGUIProgressBar;
      fModGUIButton: TModuleGUIButton;
      fModGUICheckBox: TModuleGUICheckBox;
      fModGUIIconifiedButton: TModuleGUIIconifiedButton;
      fModGUIEdit: TModuleGUIEdit;
      fModGUISlider: TModuleGUISlider;
      fModGUITimer: TModuleGUITimer;
      fModLoadScreen: TModuleLoadScreen;
      fModMainMenu: TModuleMainMenu;
      fModOCFManager: TModuleOCFManager;
      fModRenderer: TModuleRenderer;
      fModCamera: TModuleCamera;
      fModSettings: TModuleSettings;
      fModScriptManager: TModuleScriptManager;
    public
      property ModModuleConfig: TModuleConfig read fModModuleConfig;
      property ModPathes: TModulePathes read fModPathes;
      property ModLog: TModuleLog read fModLog;
      property ModLanguage: TModuleLanguage read fModLanguage;
      property ModGLContext: TModuleGLContext read fModGLContext;
      property ModGLMng: TModuleGLMng read fModGLMng;
      property ModInputHandler: TModuleInputHandler read fModInputHandler;
      property ModTexMng: TModuleTextureManager read fModTexMng;
      property ModShdMng: TModuleShaderManager read fModShdMng;
      property ModFont: TModuleFont read fModFont;
      property ModGUI: TModuleGUI read fModGUI;
      property ModGUIWindow: TModuleGUIWindow read fModGUIWindow;
      property ModGUILabel: TModuleGUILabel read fModGUILabel;
      property ModGUIImage: TModuleGUIImage read fModGUIImage;
      property ModGUITabBar: TModuleGUITabBar read fModGUITabBar;
      property ModGUIScrollBox: TModuleGUIScrollBox read fModGUIScrollBox;
      property ModGUIProgressBar: TModuleGUIProgressBar read fModGUIProgressBar;
      property ModGUIButton: TModuleGUIButton read fModGUIButton;
      property ModGUICheckBox: TModuleGUICheckBox read fModGUICheckBox;
      property ModGUIIconifiedButton: TModuleGUIIconifiedButton read fModGUIIconifiedButton;
      property ModGUIEdit: TModuleGUIEdit read fModGUIEdit;
      property ModGUISlider: TModuleGUISlider read fModGUISlider;
      property ModGUITimer: TModuleGUITimer read fModGUITimer;
      property ModLoadScreen: TModuleLoadScreen read fModLoadScreen;
      property ModMainMenu: TModuleMainMenu read fModMainMenu;
      property ModOCFManager: TModuleOCFManager read fModOCFManager;
      property ModRenderer: TModuleRenderer read fModRenderer;
      property ModCamera: TModuleCamera read fModCamera;
      property ModSettings: TModuleSettings read fModSettings;
      property ModScriptManager: TModuleScriptManager read fModScriptManager;

      /// Create all module instances
      procedure LoadModules;

      /// Free them
      procedure UnloadModules;
    end;

var
  ModuleManager: TModuleManager = nil;

implementation

procedure TModuleManager.LoadModules;
begin
  fModPathes := TModulePathes.Create;
  fModPathes.InitPathes;
  fModPathes.CheckModConf;

  fModModuleConfig := TModuleConfig.Create;
  fModModuleConfig.CheckModConf;

  fModLog := TModuleLog.Create;
  fModLog.CheckModConf;

  fModLanguage := TModuleLanguage.Create;
  fModLanguage.CheckModConf;

  fModGLContext := TModuleGLContext.Create;
  fModGLContext.CheckModConf;
  fModGLContext.ChangeWindowTitle('Open RollerCoaster Factory');
  fModGLContext.InitGL;

  fModGLMng := TModuleGLMng.Create;
  fModGLMng.CheckModConf;

  fModInputHandler := TModuleInputHandler.Create;
  fModInputHandler.CheckModConf;

  fModTexMng := TModuleTextureManager.Create;
  fModTexMng.CheckModConf;

  fModShdMng := TModuleShaderManager.Create;
  fModShdMng.CheckModConf;

  fModFont := TModuleFont.Create;
  fModFont.CheckModConf;

  fModGUI := TModuleGUI.Create;
  fModGUI.CheckModConf;

  fModGUIWindow := TModuleGUIWindow.Create;
  fModGUIWindow.CheckModConf;

  fModGUILabel := TModuleGUILabel.Create;
  fModGUILabel.CheckModConf;

  fModGUIImage := TModuleGUIImage.Create;
  fModGUIImage.CheckModConf;

  fModGUITabBar := TModuleGUITabBar.Create;
  fModGUITabBar.CheckModConf;

  fModGUIScrollBox := TModuleGUIScrollBox.Create;
  fModGUIScrollBox.CheckModConf;

  fModGUIProgressBar := TModuleGUIProgressBar.Create;
  fModGUIProgressBar.CheckModConf;

  fModGUIButton := TModuleGUIButton.Create;
  fModGUIButton.CheckModConf;

  fModGUICheckBox := TModuleGUICheckBox.Create;
  fModGUICheckBox.CheckModConf;

  fModGUIIconifiedButton := TModuleGUIIconifiedButton.Create;
  fModGUIIconifiedButton.CheckModConf;

  fModGUIEdit := TModuleGUIEdit.Create;
  fModGUIEdit.CheckModConf;

  fModGUISlider := TModuleGUISlider.Create;
  fModGUISlider.CheckModConf;

  fModGUITimer := TModuleGUITimer.Create;
  fModGUITimer.CheckModConf;

  fModLoadScreen := TModuleLoadScreen.Create;
  fModLoadScreen.CheckModConf;

  fModMainMenu := TModuleMainMenu.Create;
  fModMainMenu.CheckModConf;

  fModOCFManager := TModuleOCFManager.Create;
  fModOCFManager.CheckModConf;

  fModRenderer := TModuleRenderer.Create;
  fModRenderer.CheckModConf;

  fModCamera := TModuleCamera.Create;
  fModCamera.CheckModConf;

  fModSettings := TModuleSettings.Create;
  fModSettings.CheckModConf;

  fModScriptManager := TModuleScriptManager.Create;
  fModScriptManager.CheckModConf;
end;

procedure TModuleManager.UnloadModules;
begin
  fModScriptManager.Free;
  fModSettings.Free;
  fModCamera.Free;
  fModRenderer.Free;
  fModOCFManager.Free;
  fModMainMenu.Free;
  fModLoadScreen.Free;
  fModGUITimer.Free;
  fModGUISlider.Free;
  fModGUIEdit.Free;
  fModGUIIconifiedButton.Free;
  fModGUICheckBox.Free;
  fModGUIButton.Free;
  fModGUIProgressBar.Free;
  fModGUIImage.Free;
  fModGUILabel.Free;
  fModGUIScrollBox.Free;
  fModGUITabBar.Free;
  fModGUIWindow.Free;
  fModGUI.Free;
  fModFont.Free;
  fModShdMng.Free;
  fModTexMng.Free;
  fModInputHandler.Free;
  fModGLMng.Free;
  fModGLContext.Free;
  fModLanguage.Free;
  fModLog.Free;
  fModModuleConfig.Free;
  fModPathes.Free;
end;

end.

