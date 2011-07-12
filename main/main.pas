unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_gui_label_class, m_gui_window_class;

type
  TRenderState = (rsMainMenu, rsLoadPark, rsGame, rsHelp, rsSettings);

  TFPSDisplay = class
    private
      fLabel: TLabel;
      fWindow: TWindow;
      fMS, fFPS: Single;
      fTime: UInt64;
      fMSHistory: Array[0..3] of Single;
      procedure ShowHideFPSDisplay(Event: String; Data, Result: Pointer);
    public
      property MS: Single read fMS write fMS;
      property FPS: Single read fFPS write fFPS;
      property Window: TWindow read fWindow;
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
  m_varlist, DGLOpenGL, m_inputhandler_class, m_texmng_class, m_mainmenu_class, g_park, u_math, math, u_dialogs, u_events, g_parkui,
  g_resources, u_scripts, u_vectors, s_setcreator;

type
  TParkLoadDialog = class
    fLoadDialog: TFileDialog;
    procedure FileLoaded(Event: String; Data, Result: Pointer);
    constructor Create;
    end;

var
  ParkLoadDialog: TParkLoadDialog = nil;
  ParkFileName: String = '';
  

procedure TParkLoadDialog.FileLoaded(Event: String; Data, Result: Pointer);
begin
  EventManager.RemoveCallback(@FileLoaded);
  if Event = 'TFileDialog.Selected' then
    ParkFileName := String(Data^);
  fLoadDialog.Free;
  fLoadDialog := nil;
end;

constructor TParkLoadDialog.Create;
begin
  fLoadDialog := TFileDialog.Create(true, 'saved', 'Load park');
  EventManager.AddCallback('TFileDialog.Selected', @FileLoaded);
  EventManager.AddCallback('TFileDialog.Aborted', @FileLoaded);
end;



procedure TFPSDisplay.ShowHideFPSDisplay(Event: String; Data, Result: Pointer);
begin
  if Integer(Result^) = K_f then
    if fWindow.Left < -128 then
      fWindow.Left := -32
    else
      fWindow.Left := -160;
end;

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
  if fWindow.Left > -128 then
    fLabel.Caption := 'FPS: $' + IntToStr(Round(fFPS)) + '$';
end;

constructor TFPSDisplay.Create;
begin
  fMSHistory[0] := 10;
  fMSHistory[1] := 10;
  fMSHistory[2] := 10;
  fMSHistory[3] := 10;
  fWindow := TWindow.Create(nil);
  fWindow.Left := -160;
  fWindow.Top := -32;
  fWindow.Width := 128;
  fWindow.Height := 72;
  fLabel := TLabel.Create(fWindow);
  fLabel.Top := 40;
  fLabel.Left := 40;
  fLabel.Width := 64;
  fLabel.Height := 16;
  fLabel.Size := 16;
  SetTime;

  EventManager.AddCallback('BasicComponent.OnKeyDown', @ShowHideFPSDisplay);
end;


procedure ChangeRenderState(New: TRenderState);
begin
  if FPSDisplay = nil then
    FPSDisplay := TFPSDisplay.Create;
  RenderState := New;
  ModuleManager.ModLoadScreen.SetVisibility(false);
  if New = rsMainMenu then
    begin
    if Park <> nil then
      begin
      Park.Free;
      Park := nil;
      end;
    ModuleManager.ModMainMenu.Setup;
    end
  else
    ModuleManager.ModMainMenu.Hide;
  case New of
    rsGame:
      begin
      with ModuleManager.ModLoadScreen do
        begin
        Progress := 0;
        Headline := 'Loading park';
        Text := 'Initializing';
        SetVisibility(True);
        end;
      end;
    end;
end;

procedure MainLoop; cdecl;
var
  ResX, ResY: Integer;
const
  Bla: Single = 40.0;
begin
  FPSDisplay.Calculate;
  FPSDisplay.SetTime;
  EventManager.ExecuteQuery;
  EventManager.CallEvent('MainLoop', nil, nil);
  ModuleManager.ModGLContext.GetResolution(ResX, ResY);
  ModuleManager.ModInputHandler.UpdateData;
  ModuleManager.ModGLMng.SetUpScreen;
  ModuleManager.ModGUI.CallSignals;
  ModuleManager.ModOCFManager.CheckLoaded;
  ResourceManager.Notify;

  if SetCreator <> nil then
    if SetCreator.CanClose then
      begin
      SetCreator.Free;
      SetCreator := nil;
      end;

  if ModuleManager.ModSettings.CanBeDestroyed then
    ModuleManager.ModSettings.HideConfigurationInterface;

  if (Park = nil) and (ParkUI <> nil) then
    begin
    ParkUI.Free;
    ParkUI := nil;
    end;

  case RenderState of
    rsMainMenu:
      begin
      ModuleManager.ModMainMenu.Render;
      case ModuleManager.ModMainMenu.Value of
        MMVAL_STARTGAME:
          begin
          ChangeRenderState(rsGame);
          Park := TPark.Create('');
          end;
        MMVAL_LOADGAME:
          if ParkLoadDialog = nil then
            ParkLoadDialog := TParkLoadDialog.Create
          else if ParkLoadDialog.fLoadDialog = nil then
            begin
            ParkLoadDialog.Free;
            ParkLoadDialog := nil;
            if ParkFileName <> '' then
              begin
              ChangeRenderState(rsGame);
              Park := TPark.Create(ParkFileName);
              end;
            ParkFileName := '';
            ModuleManager.ModMainMenu.Reset;
            end;
        MMVAL_SETTINGS:
          begin
          ModuleManager.ModSettings.ShowConfigurationInterface;
          ModuleManager.ModMainMenu.Reset;
          end;
        MMVAL_SETCREATOR:
          begin
          if SetCreator = nil then
            SetCreator := TSetCreator.Create;
          ModuleManager.ModMainMenu.Reset;
          end;
        MMVAL_QUIT: ModuleManager.ModInputHandler.QuitRequest := True;
        end;
      end;
    rsGame: Park.Render;
    end;

  ModuleManager.ModGUI.Render;
  sleep(Max(1, 10 - Round(FPSDisplay.MS)));
  ModuleManager.ModGLContext.SwapBuffers;

  if ModuleManager.ModInputHandler.QuitRequest then
    begin
    ModuleManager.ModGLContext.EndMainLoop;
    ChangeRenderState(rsMainMenu);
    end;
end;

end.

