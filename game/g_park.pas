unit g_park;

interface

uses
  SysUtils, Classes, g_terrain, g_camera, g_loader_park, u_dom;

type
  TPark = class
    protected
      fFile: TDOMDocument;
      fParkLoader: TParkLoader;
      fInited: Boolean;
      fCanRender: Boolean;

    public
      // Parts of the park
      pTerrain: TTerrain;
      pMainCamera: TCamera;
      pCameras: Array of TCamera;

      property ParkLoader: TParkLoader read fParkLoader;
      property OCFFile: TDOMDocument read fFile;

      (**
        * Call render modules, handle input
        *)
      procedure Render;

      (**
        * Post-initialization
        *)
      procedure PostInit(Event: String; Arg, Result: Pointer);

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
  fCanRender := false;

  fInited := false;

  fFile := ModuleManager.ModOCFManager.LoadOCFFile(FileName);

  ModuleManager.ModLoadScreen.Progress := 5;
  fParkLoader := TParkLoader.Create;
  fParkLoader.InitDisplay;
  EventManager.AddCallback('TParkLoader.LoadFiles.NoFilesLeft', @PostInit);
end;

procedure TPark.PostInit(Event: String; Arg, Result: Pointer);
begin
  EventManager.RemoveCallback('TParkLoader.LoadFiles.NoFilesLeft', @PostInit);
  ModuleManager.ModRenderer.PostInit;
  ModuleManager.ModLoadScreen.SetVisibility(false);
  fParkLoader.Visible := false;
  ModuleManager.ModCamera.ActiveCamera := TCamera.Create;
  ModuleManager.ModCamera.ActiveCamera.LoadDefaults;
  fCanRender := true;
  pTerrain := TTerrain.Create;
  pTerrain.LoadDefaults;
end;

procedure TPark.Render;
begin
  if not fCanRender then exit;
  ModuleManager.ModCamera.AdvanceActiveCamera;
  ModuleManager.ModRenderer.RenderScene;
end;

destructor TPark.Free;
begin
  ModuleManager.ModRenderer.Unload;
  fParkLoader.Free;
  pTerrain.Free;
end;

end.