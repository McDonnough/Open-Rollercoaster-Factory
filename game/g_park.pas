unit g_park;

interface

uses
  SysUtils, Classes, l_ocf, g_terrain, g_camera, g_loader_park;

type
  TPark = class
    protected
      fFile: TOCFFile;
      fParkLoader: TParkLoader;
      fInited: Boolean;

    public
      // Parts of the park
      pTerrain: TTerrain;
      pMainCamera: TCamera;
      pCameras: Array of TCamera;

      property OCFFile: TOCFFile read fFile;

      (**
        * Call render modules, handle input
        *)
      procedure Render;

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
  Park: TPark;

implementation

uses
  Main, m_varlist;

constructor TPark.Create(FileName: String);
begin
  fInited := false;

  fFile := ModuleManager.ModOCFManager.LoadOCFFile(FileName, false);

  ModuleManager.ModLoadScreen.Progress := 5;
  fParkLoader := TParkLoader.Create;
  ModuleManager.ModRenderer.PostInit;
end;

procedure TPark.Render;
begin
  ModuleManager.ModCamera.AdvanceActiveCamera;
  ModuleManager.ModRenderer.RenderScene;
end;

destructor TPark.Free;
begin
  ModuleManager.ModRenderer.Unload;
  fParkLoader.Free;
end;

end.