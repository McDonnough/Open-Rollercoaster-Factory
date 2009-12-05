unit m_pathes_windows;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_pathes_class;

type
  (** Path module for unix-like systems *)

  TModulePathesWindows = class(TModulePathesClass)
    public
      constructor Create;
      procedure CheckModConf;
      function InitPathes: Boolean;
    end;

implementation

constructor TModulePathesWindows.Create;
begin
  fModName := 'PathesWindows';
  fModType := 'Pathes';
end;

procedure TModulePathesWindows.CheckModConf;
begin
end;

function TModulePathesWindows.InitPathes: Boolean;
begin
  fDelimiter := '\';

  fDataPath := extractFilePath(paramStr(0)) + '\data\';
  fConfigPath := extractFilePath(paramStr(0)) + '\config\';
  fPersonalDataPath := fDataPath;
end;

end.

