unit g_park;

interface

uses
  SysUtils, Classes, l_ocf, g_terrain;

type
  TPark = class
    protected
      fFile: TOCFFile;
      fParkLoader: Pointer;
      fInited: Boolean;

    public
      // Parts of the park
      pTerrain: TTerrain;

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
  Main, m_varlist, g_loader_park;

constructor TPark.Create(FileName: String);
begin
  fInited := false;

  fFile := ModuleManager.ModOCFManager.LoadOCFFile(FileName, false);

  ModuleManager.ModLoadScreen.Progress := 5;
  fParkLoader := TParkLoader.Create(Self);

  pTerrain := TTerrain.Create;
  pTerrain.SizeX := 10;
  pTerrain.SizeY := 10;
end;

procedure TPark.Render;
begin
  if not fInited then
    begin
    TParkLoader(fParkLoader).PostInit;
    fInited := true;
    end
  else
    ModuleManager.ModRenderer.RenderScene(Self);
end;

destructor TPark.Free;
begin
  TParkLoader(fParkLoader).Free;

  pTerrain.Free;
end;

end.