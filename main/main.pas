unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_gui_label_class, m_gui_window_class;

type
  TRenderState = (rsMainMenu, rsNewPark, rsLoadPark, rsGame, rsHelp, rsSettings);

var
  RenderState: TRenderState;
  FPS: Single = 100;
  MS: Single = 10;
  GUILabel: TLabel = nil;
  GUIWindow: TWindow;

procedure MainLoop; cdecl;
procedure ChangeRenderState(New: TRenderState);

implementation

uses
  m_varlist, DGLOpenGL, m_inputhandler_class, m_texmng_class, m_mainmenu_class, g_park, u_math, math;

procedure ChangeRenderState(New: TRenderState);
begin
  if GUILabel = nil then
    begin
    GUIWindow := TWindow.Create(nil);
    GUIWindow.Left := -32;
    GUIWindow.Top := -32;
    GUIWindow.Width := 200;
    GUIWindow.Height := 72;
    GUILabel := TLabel.Create(GUIWindow);
    GUILabel.Top := 40;
    GUILabel.Left := 40;
    GUILabel.Width := 64;
    GUILabel.Height := 16;
    GUILabel.Size := 16;
    end;
  RenderState := New;
  ModuleManager.ModLoadScreen.SetVisibility(false);
  if New = rsMainMenu then
    ModuleManager.ModMainMenu.Setup
  else
    ModuleManager.ModMainMenu.Hide;
  case New of
    rsNewPark:
      with ModuleManager.ModLoadScreen do
        begin
        Progress := 0;
        Headline := 'Loading park';
        Text := 'Initializing';
        SetVisibility(True);
        end;
    rsGame:
      ModuleManager.ModLoadScreen.SetVisibility(False);
    end;
end;

procedure MainLoop; cdecl;
var
  ResX, ResY: Integer;
  a: TTexture;
  ParkFileName: String;
  Time: UInt64;
begin
  Time := ModuleManager.ModGUITimer.GetTime;
  ModuleManager.ModGLContext.GetResolution(ResX, ResY);
  ModuleManager.ModInputHandler.UpdateData;
  ModuleManager.ModGLMng.SetUpScreen;
  ModuleManager.ModGUI.CallSignals;

  case RenderState of
    rsMainMenu:
      begin
      ModuleManager.ModMainMenu.Render;
      case ModuleManager.ModMainMenu.Value of
        MMVAL_STARTGAME:
          begin
          ChangeRenderState(rsNewPark);
          Park := TPark.Create(ModuleManager.ModPathes.DataPath + 'parks/default/sandbox.ocf');
          end;
        MMVAL_QUIT: ModuleManager.ModInputHandler.QuitRequest := True;
        end;
      end;
    rsNewPark: ModuleManager.ModLoadScreen.Render;
    rsGame: Park.Render;
    end;

  ModuleManager.ModGUI.Render;
  ModuleManager.ModGLContext.SwapBuffers;
  sleep(10);

  if ModuleManager.ModInputHandler.QuitRequest then
    ModuleManager.ModGLContext.EndMainLoop;
  MS := ModuleManager.ModGUITimer.GetTimeDifference(Time) / 10;
  FPS := 1000 / Max(MS, 10);

  GUILabel.Caption := 'FPS: ' + IntToStr(Round(FPS));
end;

end.

