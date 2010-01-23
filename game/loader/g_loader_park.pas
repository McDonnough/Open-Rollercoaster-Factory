unit g_loader_park;

interface

uses
  Classes, SysUtils, l_ocf, g_park;

type
  TParkLoader = class(TThread)
    protected
      fPark: TPark;
      procedure Execute; override;
    public
      procedure PostInit;
      procedure Unload;
      procedure InitOCFFile(F: TOCFFile);
      procedure UpdateParkOCF;
      constructor Create(Parent: TPark);
    end;

implementation

uses
  m_varlist, main, g_terrain, g_camera;

procedure TParkLoader.PostInit;
var
  i: Integer;
  CamerasCreated: Integer;
begin
  CamerasCreated := 0;

  // Create objects
  fPark.pTerrain := TTerrain.Create;
  fPark.pMainCamera := TCamera.Create;

  // Init them
  with fPark.OCFFile do
    for i := 0 to high(Sections) do
      begin
      if Sections[i].SectionType = 'Terrain' then
        fPark.pTerrain.ReadFromOCFSection(Sections[i])
      else if Sections[i].SectionType = 'Camera' then
        begin
        if CamerasCreated = 0 then
          fPark.pMainCamera.ReadFromOCFSection(Sections[i])
        else
          begin
          setLength(fPark.pCameras, length(fPark.pCameras) + 1);
          fPark.pCameras[high(fPark.pCameras)] := TCamera.Create;
          fPark.pCameras[high(fPark.pCameras)].ReadFromOCFSection(Sections[i]);
          end;
        Inc(CamerasCreated);
        end;
      end;

  // Load defaults if not already initialized
  fPark.pTerrain.LoadDefaults;
  fPark.pMainCamera.LoadDefaults;

  // Post-prepare some modules
  ModuleManager.ModCamera.ActiveCamera := fPark.pMainCamera;
end;

procedure TParkLoader.Unload;
var
  i: Integer;
begin
  // Free the objects again
  for i := 0 to high(fPark.pCameras) do
    fPark.pCameras[i].Free;
  fPark.pMainCamera.Free;
  fPark.pTerrain.Free;
end;

procedure TParkLoader.InitOCFFile(F: TOCFFile);
begin

end;

procedure TParkLoader.UpdateParkOCF;
begin

end;

procedure TParkLoader.Execute;
var
  i: integer;
  p, pd: Double;
begin
  pd := ModuleManager.ModLoadScreen.Progress;
  p := 1;
  if fPark.OCFFile.References.Count <> 0 then
    p := (100 - pd) / fPark.OCFFile.References.Count;
  for i := 0 to fPark.OCFFile.References.Count - 1 do
    begin
    ModuleManager.ModLoadScreen.Text := 'Loading File (' + fPark.OCFFile.References.Strings[i] + ')';
    ModuleManager.ModOCFManager.LoadOCFFile(fPark.OCFFile.References.Strings[i]);
    pd := pd + p;
    ModuleManager.ModLoadScreen.Progress := Round(pd);
    end;
  ModuleManager.ModLoadScreen.Text := 'Preparing data';
  ModuleManager.ModLoadScreen.Progress := 100;
  ChangeRenderState(rsGame);
end;

constructor TParkLoader.Create(Parent: TPark);
begin
  fPark := Parent;
  inherited Create(false);
end;

end.