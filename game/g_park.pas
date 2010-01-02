unit g_park;

interface

uses
  SysUtils, Classes, l_ocf;

type
  TPark = class
    protected
      fFile: TOCFFile;
      fParkLoader: Pointer;
      fInited: Boolean;
    public
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

  fFile.FileName := 'Death.ocf';
  fFile.SaveToFile;

  ModuleManager.ModLoadScreen.Progress := 5;
  fParkLoader := TParkLoader.Create(Self);
end;

procedure TPark.Render;
begin
  if not fInited then
    begin
    TParkLoader(fParkLoader).PostInit;
    fInited := true;
    end;
end;

destructor TPark.Free;
begin
  TParkLoader(fParkLoader).Free;
end;

end.