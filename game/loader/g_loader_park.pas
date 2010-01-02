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
      constructor Create(Parent: TPark);
    end;

implementation

uses
  m_varlist, main;

procedure TParkLoader.PostInit;
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
end;

constructor TParkLoader.Create(Parent: TPark);
begin
  fPark := Parent;
  inherited Create(false);
end;

end.