unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  TRenderState = (rsMainMenu);

var
  RenderState: TRenderState;

procedure MainLoop; cdecl;
procedure ChangeRenderState(New: TRenderState);

implementation

uses
  m_varlist, DGLOpenGL, m_inputhandler_class, m_texmng_class, m_mainmenu_class;

procedure ChangeRenderState(New: TRenderState);
begin
  RenderState := New;
  ModuleManager.ModLoadScreen.SetVisibility(false);
  case New of
    rsMainMenu:
      ModuleManager.ModMainMenu.Setup;
    end;
end;

procedure MainLoop; cdecl;
var
  ResX, ResY: Integer;
  a: TTexture;
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
        MMVAL_QUIT: ModuleManager.ModInputHandler.QuitRequest := True;
        end;
      end;
    end;

  ModuleManager.ModGUI.Render;
  ModuleManager.ModGLContext.SwapBuffers;
  sleep(10);
end;

end.

