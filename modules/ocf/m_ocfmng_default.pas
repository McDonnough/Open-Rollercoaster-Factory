unit m_ocfmng_default;

interface

uses
  SysUtils, Classes, m_ocfmng_class, l_ocf;

type
  TModuleOCFManagerDefault = class(TModuleOCFManagerClass)
    protected
      fOCFFiles: array of TOCFFile;
    public
      function LoadOCFFile(FileName: String; AutoLoadRef: Boolean = True): TOCFFile;
      procedure CheckModConf;
      constructor Create;
      destructor Free;
    end;

implementation

function TModuleOCFManagerDefault.LoadOCFFile(FileName: String; AutoLoadRef: Boolean = True): TOCFFile;
var
  i: Integer;
begin
  for i := 0 to high(fOCFFiles) do
    if fOCFFiles[i].FileName = FileName then
      exit(fOCFFiles[i]);
  setLength(fOCFFiles, length(fOCFFiles) + 1);
  fOCFFiles[high(fOCFFiles)] := TOCFFile.Create;
  fOCFFiles[high(fOCFFiles)].FileName := FileName;
  fOCFFiles[high(fOCFFiles)].ReadFromFile;
  if AutoLoadRef then
    for i := 0 to fOCFFiles[high(fOCFFiles)].References.Count - 1 do
      LoadOCFFile(fOCFFiles[high(fOCFFiles)].References.Strings[i]);
  Result := fOCFFiles[high(fOCFFiles)];
end;

constructor TModuleOCFManagerDefault.Create;
begin
  fModName := 'OCFManagerDefault';
  fModType := 'OCFManager';
end;

procedure TModuleOCFManagerDefault.CheckModConf;
begin
end;

destructor TModuleOCFManagerDefault.Free;
var
  i: Integer;
begin
  for i := 0 to high(fOCFFiles) do
    fOCFFiles[i].Free;
end;

end.