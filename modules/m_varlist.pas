unit m_varlist;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_moduleconfig_ini, {$IFDEF UNIX}m_pathes_unix{$ELSE}m_pathes_windows{$ENDIF}, m_log_file,
  m_glcontext_sdl, m_inputhandler_sdl, m_texmng_default, m_shdmng_default, m_loadscreen_default, m_font_texture,
  m_glmng_default, m_gui_window_default, m_gui_label_default, m_gui_default, m_gui_progressbar_default,
  m_language_textfile, m_gui_button_default, m_mainmenu_screenshots, m_gui_iconifiedbutton_default,
  m_gui_edit_default, m_ocfmng_default, m_renderer_opengl;

type
  TModuleManager = class
    protected
      fModModuleConfig: TModuleConfigIni;                                            // Ini backend for module configuration
      fModPathes: {$IFDEF UNIX}TModulePathesUnix{$ELSE}TModulePathesWindows{$ENDIF}; // Use operating system specific modules
      fModLog: TModuleLogFile;                                                       // Log messages go into a simple file
      fModLanguage: TModuleLanguageTextfile;                                         // Text file backend for language output
      fModGLContext: TModuleGLContextSDL;                                            // SDL backend for GL context creation
      fModGLMng: TModuleGLMngDefault;                                                // Default GL manager
      fModInputHandler: TModuleInputHandlerSDL;                                      // SDL based event handling
      fModTexMng: TModuleTextureManagerDefault;                                      // Default texture manager
      fModShdMng: TModuleShaderManagerDefault;                                       // Default Shader Manager
      fModFont: TModuleFontTexture;                                                  // Texture-based font backend
      fModGUI: TModuleGUIDefault;                                                    // Default GUI manager
      fModGUIWindow: TModuleGUIWindowDefault;                                        // Default GUI window
      fModGUILabel: TModuleGUILabelDefault;                                          // Default GUI label
      fModGUIProgressBar: TModuleGUIProgressBarDefault;                              // Default GUI progress bar
      fModGUIButton: TModuleGUIButtonDefault;                                        // Default GUI button
      fModGUIIconifiedButton: TModuleGUIIconifiedButtonDefault;                      // Default button showing an icon
      fModGUIEdit: TModuleGUIEditDefault;                                            // Default input component
      fModLoadScreen: TModuleLoadScreenDefault;                                      // Default loading screens
      fModMainMenu: TModuleMainMenuScreenshots;                                      // Show screenshots in main menu
      fModOCFManager: TModuleOCFManagerDefault;                                      // Default OCF file manager
      fModRenderer: TModuleRendererOpenGL;                                           // OpenGL rendering backed
    public
      property ModModuleConfig: TModuleConfigIni read fModModuleConfig;
      property ModPathes: {$IFDEF UNIX}TModulePathesUnix{$ELSE}TModulePathesWindows{$ENDIF} read fModPathes;
      property ModLog: TModuleLogFile read fModLog;
      property ModLanguage: TModuleLanguageTextFile read fModLanguage;
      property ModGLContext: TModuleGLContextSDL read fModGLContext;
      property ModGLMng: TModuleGLMngDefault read fModGLMng;
      property ModInputHandler: TModuleInputHandlerSDL read fModInputHandler;
      property ModTexMng: TModuleTextureManagerDefault read fModTexMng;
      property ModShdMng: TModuleShaderManagerDefault read fModShdMng;
      property ModFont: TModuleFontTexture read fModFont;
      property ModGUI: TModuleGUIDefault read fModGUI;
      property ModGUIWindow: TModuleGUIWindowDefault read fModGUIWindow;
      property ModGUILabel: TModuleGUILabelDefault read fModGUILabel;
      property ModGUIProgressBar: TModuleGUIProgressBarDefault read fModGUIProgressBar;
      property ModGUIButton: TModuleGUIButtonDefault read fModGUIButton;
      property ModGUIIconifiedButton: TModuleGUIIconifiedButtonDefault read fModGUIIconifiedButton;
      property ModGUIEdit: TModuleGUIEditDefault read fModGUIEdit;
      property ModLoadScreen: TModuleLoadScreenDefault read fModLoadScreen;
      property ModMainMenu: TModuleMainMenuScreenshots read fModMainMenu;
      property ModOCFManager: TModuleOCFManagerDefault read fModOCFManager;
      property ModRenderer: TModuleRendererOpenGL read fModRenderer;

      /// Create all module instances
      procedure LoadModules;

      /// Free them
      procedure UnloadModules;
    end;

var
  ModuleManager: TModuleManager;

implementation

procedure TModuleManager.LoadModules;
begin
  fModPathes := {$IFDEF UNIX}TModulePathesUnix{$ELSE}TModulePathesWindows{$ENDIF}.Create;
  fModPathes.InitPathes;
  fModPathes.CheckModConf;

  fModModuleConfig := TModuleConfigIni.Create;
  fModModuleConfig.CheckModConf;

  fModLog := TModuleLogFile.Create;
  fModLog.CheckModConf;

  fModLanguage := TModuleLanguageTextfile.Create;
  fModLanguage.CheckModConf;

  fModGLContext := TModuleGLContextSDL.Create;
  fModGLContext.CheckModConf;
  fModGLContext.ChangeWindowTitle('Open RollerCoaster Factory');
  fModGLContext.InitGL;

  fModGLMng := TModuleGLMngDefault.Create;
  fModGLMng.CheckModConf;

  fModInputHandler := TModuleInputHandlerSDL.Create;
  fModInputHandler.CheckModConf;

  fModTexMng := TModuleTextureManagerDefault.Create;
  fModTexMng.CheckModConf;

  fModShdMng := TModuleShaderManagerDefault.Create;
  fModShdMng.CheckModConf;

  fModFont := TModuleFontTexture.Create;
  fModFont.CheckModConf;

  fModGUI := TModuleGUIDefault.Create;
  fModGUI.CheckModConf;

  fModGUIWindow := TModuleGUIWindowDefault.Create;
  fModGUIWindow.CheckModConf;

  fModGUILabel := TModuleGUILabelDefault.Create;
  fModGUILabel.CheckModConf;

  fModGUIProgressBar := TModuleGUIProgressBarDefault.Create;
  fModGUIProgressBar.CheckModConf;

  fModGUIButton := TModuleGUIButtonDefault.Create;
  fModGUIButton.CheckModConf;

  fModGUIIconifiedButton := TModuleGUIIconifiedButtonDefault.Create;
  fModGUIIconifiedButton.CheckModConf;

  fModGUIEdit := TModuleGUIEditDefault.Create;
  fModGUIEdit.CheckModConf;

  fModLoadScreen := TModuleLoadScreenDefault.Create;
  fModLoadScreen.CheckModConf;

  fModMainMenu := TModuleMainMenuScreenshots.Create;
  fModMainMenu.CheckModConf;

  fModOCFManager := TModuleOCFManagerDefault.Create;
  fModOCFManager.CheckModConf;

  fModRenderer := TModuleRendererOpenGL.Create;
  fModRenderer.CheckModConf;
end;

procedure TModuleManager.UnloadModules;
begin
  fModRenderer.Free;
  fModOCFManager.Free;
  fModMainMenu.Free;
  fModLoadScreen.Free;
  fModGUIEdit.Free;
  fModGUIIconifiedButton.Free;
  fModGUIButton.Free;
  fModGUIProgressBar.Free;
  fModGUILabel.Free;
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

