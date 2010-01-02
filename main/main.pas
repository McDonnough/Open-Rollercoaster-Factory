unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  TRenderState = (rsMainMenu, rsNewPark, rsLoadPark, rsGame, rsHelp, rsSettings);

var
  RenderState: TRenderState;

procedure MainLoop; cdecl;
procedure ChangeRenderState(New: TRenderState);

implementation

uses
  m_varlist, DGLOpenGL, m_inputhandler_class, m_texmng_class, m_mainmenu_class, g_park;

procedure ChangeRenderState(New: TRenderState);
begin
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
begin
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
end;

end.

