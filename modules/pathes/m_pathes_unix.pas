unit m_pathes_unix;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_pathes_class;

type
  (** Path module for unix-like systems *)

  TModulePathesUnix = class(TModulePathesClass)
    public
      constructor Create;
      procedure CheckModConf;
      function InitPathes: Boolean;
    end;

implementation

uses
  unix;

constructor TModulePathesUnix.Create;
begin
  fModName := 'PathesUnix';
  fModType := 'Pathes';
end;

procedure TModulePathesUnix.CheckModConf;
begin
end;

function TModulePathesUnix.InitPathes: Boolean;
begin
//       _____           _____
//   ,ad8PPPP88b,     ,d88PPPP8ba,
// d8P"      "Y8b, ,d8P"      "Y8b
// dP'           "8a8"           `Yd
// 8(              "              )8
// I8                             8I
//  Yb,          LINUX          ,dP
//   "8a,                     ,a8"
//     "8a,                 ,a8"
//       "Yba             adP"
//         `Y8a         a8P'
//           `88,     ,88'
//             "8b   d8"
//              "8b d8"
//               `888'
//                 "
  fDelimiter := '/';

  fConfigPath := getEnvironmentVariable('HOME') + fDelimiter + '.orcf';
  if not directoryExists(fConfigPath) then
    mkdir(fConfigPath);
  fConfigPath := fConfigPath + fDelimiter;

  fPersonalDataPath := getEnvironmentVariable('HOME') + fDelimiter + 'orcf-data';
  if not directoryExists(fPersonalDataPath) then
    mkdir(fPersonalDataPath);
  fPersonalDataPath := fPersonalDataPath + fDelimiter;

  if (extractFilePath(paramstr(0)) = '/usr/bin/') or (extractFilePath(paramstr(0)) = '/usr/local/bin/') then
    fDataPath := extractFilePath(extractFileDir(paramStr(0))) + 'share/orcf/'
  else
    fDataPath := extractFilePath(paramStr(0)) + 'data/';
end;

end.

