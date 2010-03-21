unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_gui_label_class, m_gui_window_class;

type
  TRenderState = (rsMainMenu, rsLoadPark, rsGame, rsHelp, rsSettings);

  TFPSDisplay = class
    protected
      fLabel: TLabel;
      fWindow: TWindow;
      fMS, fFPS: Single;
      fTime: UInt64;
      fMSHistory: Array[0..3] of Single;
    public
      property MS: Single read fMS;
      property FPS: Single read fFPS;
      procedure SetTime;
      procedure Calculate;
      constructor Create;
    end;

var
  RenderState: TRenderState;
  FPSDisplay: TFPSDisplay;

procedure MainLoop; cdecl;
procedure ChangeRenderState(New: TRenderState);

implementation

uses
  m_varlist, DGLOpenGL, m_inputhandler_class, m_texmng_class, m_mainmenu_class, g_park, u_math, math;

procedure TFPSDisplay.SetTime;
begin
  fTime := ModuleManager.ModGUITimer.GetTime;
end;

procedure TFPSDisplay.Calculate;
begin
  fMS := 0.3 * (0.1 * (ModuleManager.ModGUITimer.GetTime - fTime))
       + 0.2 * fMSHistory[0]
       + 0.2 * fMSHistory[1]
       + 0.2 * fMSHistory[2]
       + 0.1 * fMSHistory[3];
  fMSHistory[3] := fMSHistory[2];
  fMSHistory[2] := fMSHistory[1];
  fMSHistory[1] := fMSHistory[0];
  fMSHistory[0] := fMS;
  fFPS := 1000 / fMS;
  fLabel.Caption := 'FPS: ' + IntToStr(Round(fFPS));
end;

constructor TFPSDisplay.Create;
begin
  fMSHistory[0] := 10;
  fMSHistory[1] := 10;
  fMSHistory[2] := 10;
  fMSHistory[3] := 10;
  fWindow := TWindow.Create(nil);
  fWindow.Left := -32;
  fWindow.Top := -32;
  fWindow.Width := 200;
  fWindow.Height := 72;
  fLabel := TLabel.Create(fWindow);
  fLabel.Top := 40;
  fLabel.Left := 40;
  fLabel.Width := 64;
  fLabel.Height := 16;
  fLabel.Size := 16;
end;


procedure ChangeRenderState(New: TRenderState);
begin
  if FPSDisplay = nil then
    FPSDisplay := TFPSDisplay.Create;
  RenderState := New;
  ModuleManager.ModLoadScreen.SetVisibility(false);
  if New = rsMainMenu then
    ModuleManager.ModMainMenu.Setup
  else
    ModuleManager.ModMainMenu.Hide;
  case New of
    rsGame:
      with ModuleManager.ModLoadScreen do
        begin
        Progress := 0;
        Headline := 'Loading park';
        Text := 'Initializing';
        SetVisibility(True);
        end;
    end;
end;

procedure MainLoop; cdecl;
var
  ResX, ResY: Integer;
  a: TTexture;
  ParkFileName: String;
begin
  FPSDisplay.SetTime;
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
          ChangeRenderState(rsGame);
          Park := TPark.Create(ModuleManager.ModPathes.DataPath + 'parks/default/sandbox.ocf');
          end;
        MMVAL_QUIT: ModuleManager.ModInputHandler.QuitRequest := True;
        end;
      end;
    rsGame: Park.Render;
    end;

  if Park <> nil then
    Park.ParkLoader.Run;

  ModuleManager.ModGUI.Render;
  sleep(10);
  ModuleManager.ModGLContext.SwapBuffers;

  if ModuleManager.ModInputHandler.QuitRequest then
    ModuleManager.ModGLContext.EndMainLoop;

  FPSDisplay.Calculate;
end;

end.

