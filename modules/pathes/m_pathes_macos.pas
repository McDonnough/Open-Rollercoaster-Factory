unit m_pathes_macos;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_pathes_class;

type
  (** Path module for unix-like systems *)

  TModulePathesMacOS = class(TModulePathesClass)
    public
      constructor Create;
      procedure CheckModConf;
      function InitPathes: Boolean;
    end;

implementation

uses
  unix;

constructor TModulePathesMacOS.Create;
begin
  fModName := 'PathesMacOS';
  fModType := 'Pathes';
end;

procedure TModulePathesMacOS.CheckModConf;
begin
end;

function TModulePathesMacOS.InitPathes: Boolean;
begin
  fDelimiter := '/';

  fConfigPath := getEnvironmentVariable('HOME') + fDelimiter + '.orcf';
  if not directoryExists(fConfigPath) then
    mkdir(fConfigPath);
  fConfigPath := fConfigPath + fDelimiter;

  fPersonalDataPath := getEnvironmentVariable('HOME') + fDelimiter + '/orcf-data';
  if not directoryExists(fPersonalDataPath) then
    mkdir(fPersonalDataPath);
  fPersonalDataPath := fPersonalDataPath + fDelimiter;

  if (extractFilePath(paramstr(0)) = '/usr/bin/') or (extractFilePath(paramstr(0)) = '/usr/local/bin/') then
    fDataPath := extractFilePath(extractFileDir(paramStr(0))) + 'share/orcf/'
  else
    fDataPath := extractFilePath(paramStr(0)) + '../Resources/';
end;

end.


