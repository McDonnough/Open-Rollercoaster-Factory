unit m_moduleconfig_xml;

interface

uses
  SysUtils, Classes, m_moduleconfig_class, u_xml, u_dom;

type
  TModuleConfigXML = class(TModuleConfigClass)
    protected
      fDocument: TDOMDocument;
      procedure ReadFile;
      procedure WriteFile;
    public
      constructor Create;
      destructor Free;
      procedure CheckModConf;
      function SetOption(ModName, KeyName, KeyValue: String): Boolean;
      function ReadOption(ModName, KeyName: String): String;
    end;

implementation

uses
  m_varlist;

procedure TModuleConfigXML.ReadFile;
begin
  if fileExists(ModuleManager.ModPathes.ConfigPath + 'modconf.xml') then
    fDocument := LoadXMLFile(ModuleManager.ModPathes.ConfigPath + 'modconf.xml')
  else
    begin
    fDocument := TDOMDocument.Create;
    fDocument.AppendChild(fDocument.CreateElement('config'));
    end;
end;

procedure TModuleConfigXML.WriteFile;
begin
  WriteXMLFile(fDocument, ModuleManager.ModPathes.ConfigPath + 'modconf.xml');
end;

constructor TModuleConfigXML.Create;
begin
  fModName := 'ModuleConfigXml';
  fModType := 'ModuleConfig';
  ReadFile;
end;

destructor TModuleConfigXML.Free;
begin
  WriteFile;
  fDocument.Free;
end;

procedure TModuleConfigXML.CheckModConf;
begin
end;

function TModuleConfigXML.SetOption(ModName, KeyName, KeyValue: String): Boolean;
var
  Results: TDOMNodeList;
  CurrentModule, CurrentOption: TDOMNode;
  i: Integer;
begin
  Result := false;
  CurrentModule := nil;
  Results := TDOMElement(fDocument.FirstChild).GetElementsByTagName('module');
  for i := 0 to High(Results) do
    if TDOMElement(Results[i]).GetAttribute('name') = ModName then
      CurrentModule := Results[i];
  if CurrentModule = nil then
    begin
    CurrentModule := fDocument.CreateElement('module');
    TDOMElement(CurrentModule).SetAttribute('name', ModName);
    fDocument.FirstChild.AppendChild(CurrentModule);
    end;
  Results := TDOMElement(CurrentModule).GetElementsByTagName('option');
  CurrentOption := nil;
  for i := 0 to high(Results) do
    if TDOMElement(Results[i]).GetAttribute('name') = KeyName then
      CurrentOption := Results[i];
  if CurrentOption = nil then
    begin
    CurrentOption := fDocument.CreateElement('option');
    TDOMElement(CurrentOption).SetAttribute('name', KeyName);
    CurrentModule.AppendChild(CurrentOption);
    end;
  while CurrentOption.LastChild <> nil do
    CurrentOption.RemoveChild(CurrentOption.LastChild);
  CurrentOption.AppendChild(fDocument.CreateTextNode(KeyValue));
  Result := true;
end;

function TModuleConfigXML.ReadOption(ModName, KeyName: String): String;
var
  Results: TDOMNodeList;
  r, CurrentModule: TDOMNode;
  i: Integer;
begin
  Result := '';
  CurrentModule := nil;
  Results := TDOMElement(fDocument.FirstChild).GetElementsByTagName('module');
  for i := 0 to High(Results) do
    if TDOMElement(Results[i]).GetAttribute('name') = ModName then
      CurrentModule := Results[i];
  if CurrentModule = nil then
    exit;
  Results := TDOMElement(CurrentModule).GetElementsByTagName('option');
  CurrentModule := nil;
  for i := 0 to high(Results) do
    if TDOMElement(Results[i]).GetAttribute('name') = KeyName then
      CurrentModule := Results[i];
  if CurrentModule = nil then
    exit;
  r := CurrentModule.FirstChild;
  while r <> nil do
    begin
    Result := Result + r.NodeValue;
    r := r.NextSibling;
    end;
end;

end.