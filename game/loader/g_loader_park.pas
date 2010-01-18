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
  m_varlist, main, g_terrain;

procedure TParkLoader.PostInit;
var
  i: Integer;
begin
  // Create objects
  fPark.pTerrain := TTerrain.Create;

  // Init them
  with fPark.OCFFile do
    for i := 0 to high(Sections) do
      begin
      if Sections[i].SectionType = 'Terrain' then fPark.pTerrain.ReadFromOCFSection(Sections[i]);
      end;

  // Load defaults if not already initialized
  fPark.pTerrain.LoadDefaults;
end;

procedure TParkLoader.Unload;
begin
  // Free the objects again
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
  sleep(1000);
end;

constructor TParkLoader.Create(Parent: TPark);
begin
  fPark := Parent;
  inherited Create(false);
end;

end.