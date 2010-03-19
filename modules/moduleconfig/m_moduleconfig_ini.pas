unit m_moduleconfig_ini;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_moduleconfig_class, m_module;

type
  TModConfs = record
    ModName: String;
    ModConf: AModConf;
    end;

  AModConfs = Array of TModConfs;

  /// Creates an ini file that stores all the necessary information for the modules
  TModuleConfigIni = class(TModuleConfigClass)
    protected
      fModConfs: AModConfs;
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
  m_varlist, u_functions;

procedure TModuleConfigIni.ReadFile;
var
  i: Integer;
  CurrModName: String;

  procedure ParseString(s: String);
  var
    i: Integer;
    p: AString;
  begin
    if (s[1] = '[') and (s[length(s)] = ']') then
      CurrModName := SubString(s, 2, length(s) - 2)
    else
      begin
      p := Explode('=', s);
      if length(p) = 2 then
        SetOption(CurrModName, p[0], p[1]);
      end;
  end;
begin
  if not FileExists(ModuleManager.ModPathes.ConfigPath + 'modconf.ini') then
    exit;
  CurrModName := '';
  with TStringList.Create do
    begin
    LoadFromFile(ModuleManager.ModPathes.ConfigPath + 'modconf.ini');
    for i := 0 to count - 1 do
      ParseString(Strings[i]);
    Free;
    end;
end;

procedure TModuleConfigIni.WriteFile;
var
  i, j: integer;
  s: TStringList;
begin
  s := TStringList.Create;
  for i := 0 to high(fModConfs) do
    begin
    s.Add('[' + fModConfs[i].ModName + ']');
    for j := 0 to high(fModConfs[i].ModConf) do
      s.Add(fModConfs[i].ModConf[j].Key + '=' + fModConfs[i].ModConf[j].Value);
    end;
  s.SaveToFile(ModuleManager.ModPathes.ConfigPath + 'modconf.ini');
  s.Free;
end;

constructor TModuleConfigIni.Create;
begin
  fModName := 'ModuleConfigIni';
  fModType := 'ModuleConfig';
  ReadFile;
end;

destructor TModuleConfigIni.Free;
begin
  WriteFile;
end;

procedure TModuleConfigIni.CheckModConf;
begin
end;

function TModuleConfigIni.SetOption(ModName, KeyName, KeyValue: String): Boolean;
var
  i, j: integer;
begin
  Result := false;
  for i := 0 to high(fModConfs) do
    if fModConfs[i].ModName = ModName then
      begin
      for j := 0 to high(fModConfs[i].ModConf) do
        if fModConfs[i].ModConf[j].Key = KeyName then
          begin
          fModConfs[i].ModConf[j].Value := KeyValue;
          exit(true);
          end;
      setLength(fModConfs[i].ModConf, length(fModConfs[i].ModConf) + 1);
      fModConfs[i].ModConf[high(fModConfs[i].ModConf)].Key := KeyName;
      fModConfs[i].ModConf[high(fModConfs[i].ModConf)].Value := KeyValue;
      exit(true);
      end;
  setLength(fModConfs, length(fModConfs) + 1);
  fModConfs[high(fModConfs)].ModName := ModName;
  setLength(fModConfs[high(fModConfs)].ModConf, 1);
  fModConfs[high(fModConfs)].ModConf[0].Key := KeyName;
  fModConfs[high(fModConfs)].ModConf[0].Value := KeyValue;
  result := true;
end;

function TModuleConfigIni.ReadOption(ModName, KeyName: String): String;
var
  i, j: integer;
begin
  for i := 0 to high(fModConfs) do
    if fModConfs[i].ModName = ModName then
      for j := 0 to high(fModConfs[i].ModConf) do
        if fModConfs[i].ModConf[j].Key = KeyName then
          exit(fModConfs[i].ModConf[j].Value);
  result := '';
end;

end.

