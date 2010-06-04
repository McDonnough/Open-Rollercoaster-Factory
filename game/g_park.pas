unit g_park;

interface

uses
  SysUtils, Classes, g_terrain, g_camera, g_loader_park, u_dom, m_gui_button_class, m_gui_class, g_parkui, g_sky;

type
  TPark = class
    protected
      fFile: TDOMDocument;
      fParkLoader: TParkLoader;
      fInited, fPostLoading: Boolean;
      fCanRender: Boolean;
      fParkUI: TParkUI;
      fLoadState: Integer;
      fTimeUntilInvisible: Integer;
    public
      // Parts of the park
      pTerrain: TTerrain;
      pSky: TSky;
      pMainCamera: TCamera;
      pCameras: Array of TCamera;

      property ParkLoader: TParkLoader read fParkLoader;
      property OCFFile: TDOMDocument read fFile;

      (**
        * Call render modules, handle input
        *)
      procedure Render;

      (**
        * Sleep until main menu is invisible
        *)
      procedure StartPostInit(Event: String; Arg, Result: Pointer);

      (**
        * Post-initialization
        *)
      procedure PostInit(Event: String; Arg, Result: Pointer);

      (**
        * Methods of post-initialization
        *)
      procedure ContinueLoading;

      (**
        * Load a park
        *@param File to load
        *)
      constructor Create(FileName: String);

      (**
        * Free resources
        *)
      destructor Free;
    end;

var
  Park: TPark = nil;

implementation

uses
  Main, m_varlist, u_events;

constructor TPark.Create(FileName: String);
begin
  fTimeUntilInvisible := 120;
  fCanRender := false;

  fInited := false;

  fFile := ModuleManager.ModOCFManager.LoadOCFFile(FileName);

  ModuleManager.ModLoadScreen.Progress := 5;
  fParkLoader := TParkLoader.Create;
  fParkLoader.InitDisplay;
  EventManager.AddCallback('TPark.Render', @StartPostInit);
end;

procedure TPark.ContinueLoading;
begin
  case fLoadState of
    0:
      begin
      ModuleManager.ModLoadScreen.Progress := 90;
      ModuleManager.ModLoadScreen.Text := 'Preparing terrain';
      end;
    1:
      begin
      pTerrain := TTerrain.Create;
      pTerrain.LoadDefaults;
      end;
    2:
      begin
      ModuleManager.ModLoadScreen.Progress := 98;
      ModuleManager.ModLoadScreen.Text := 'Creating sky';
      end;
    3: pSky := TSky.Create;
    4:
      begin
      ModuleManager.ModLoadScreen.Progress := 99;
      ModuleManager.ModLoadScreen.Text := 'Loading user interface files';
      end;
    5: fParkUI := TParkUI.Create;
    6:
      begin
      ModuleManager.ModLoadScreen.Progress := 100;
      ModuleManager.ModLoadScreen.Text := 'Preparing for gameplay';
      end;
    200:
      begin
      fPostLoading := false;
      ModuleManager.ModLoadScreen.SetVisibility(false);
      fParkLoader.Visible := false;
      fCanRender := true;
      end;
    end;
  inc(fLoadState);
end;

procedure TPark.StartPostInit(Event: String; Arg, Result: Pointer);
begin
  ModuleManager.ModLoadScreen.Progress := 0;
  ModuleManager.ModLoadScreen.Text := 'Preparing renderer';
  if fTimeUntilInvisible = 0 then
    begin
    EventManager.RemoveCallback(@StartPostInit);
    EventManager.AddCallback('TParkLoader.LoadFiles.NoFilesLeft', @PostInit);
    end
  else
    dec(fTimeUntilInvisible);
end;

procedure TPark.PostInit(Event: String; Arg, Result: Pointer);
begin
  EventManager.RemoveCallback('TParkLoader.LoadFiles.NoFilesLeft', @PostInit);
  ModuleManager.ModRenderer.PostInit;
  ModuleManager.ModCamera.ActiveCamera := TCamera.Create;
  ModuleManager.ModCamera.ActiveCamera.LoadDefaults;
  fLoadState := 0;
  fPostLoading := true;
end;

procedure TPark.Render;
begin
  if not fCanRender then
    ModuleManager.ModLoadScreen.Render
  else
    begin
    fParkUI.Drag;
    pSky.Time := pSky.Time + FPSDisplay.MS / 10;
    ModuleManager.ModCamera.AdvanceActiveCamera;
    ModuleManager.ModRenderer.RenderScene;
    end;
  if fPostLoading then
    ContinueLoading;
  EventManager.CallEvent('TPark.Render', nil, nil);
end;

destructor TPark.Free;
begin
  ModuleManager.ModRenderer.Unload;
  fParkLoader.Free;
  pSky.Free;
  pTerrain.Free;
  fParkUI.Free;
end;

end.