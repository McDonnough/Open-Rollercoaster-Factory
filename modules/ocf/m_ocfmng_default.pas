unit m_ocfmng_default;

interface

uses
  SysUtils, Classes, m_ocfmng_class, u_dom, u_xml;

type
  TModuleOCFManagerDefault = class(TModuleOCFManagerClass)
    protected
      fFileNames: array of String;
      fOCFFiles: array of TDOMDocument;
    public
      function LoadOCFFile(FileName: String): TDOMDocument;
      procedure CheckModConf;
      constructor Create;
      destructor Free;
    end;

implementation

uses
  m_varlist;

function TModuleOCFManagerDefault.LoadOCFFile(FileName: String): TDOMDocument;
var
  i: Integer;
  fFileName: String;
begin
  fFileName := FileName;
  for i := 0 to high(fOCFFiles) do
    if fFilenames[i] = FileName then
      exit(fOCFFiles[i]);
  if not FileExists(fFileName) then
    FileName := ModuleManager.ModPathes.DataPath + fFileName;
  if not FileExists(fFileName) then
    FileName := ModuleManager.ModPathes.PersonalDataPath + fFileName;
  if not FileExists(fFileName) then
    exit(nil);
  setLength(fOCFFiles, length(fOCFFiles) + 1);
  fOCFFiles[high(fOCFFiles)] := LoadXMLFile(FileName);
  Result := fOCFFiles[high(fOCFFiles)];
  setLength(fFileNames, length(fOCFFiles));
  fFileNames[high(fFileNames)] := fFileName;
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