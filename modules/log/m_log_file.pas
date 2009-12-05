unit m_log_file;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_log_class;

type
  TModuleLogFile = class(TModuleLogClass)
    protected
      fSL: TStringList;
    public
      constructor Create;
      destructor Free;
      procedure AddError(s, sFile: String; sLine: Integer);
      procedure AddWarning(s, sFile: String; sLine: Integer);
      procedure CheckModConf;
    end;

implementation

uses
  m_varlist;

constructor TModuleLogFile.Create;
begin
  fModName := 'LogFile';
  fModType := 'Log';
  fSL := TStringList.create;
end;

destructor TModuleLogFile.Free;
begin
  fSL.SaveToFile(Self.GetConfVal('LogFile'));
  fSL.free;
end;

procedure TModuleLogFile.AddError(s, sFile: String; sLine: Integer);
begin
  writeln('Error (' + sFile + ', line ' + IntToStr(sLine) + '): ' + s);
  fSL.Add('Error (' + sFile + ', line ' + IntToStr(sLine) + '): ' + s);
  fSL.SaveToFile(GetConfVal('LogFile'));
  fSL.free;
  halt(1);
end;

procedure TModuleLogFile.AddWarning(s, sFile: String; sLine: Integer);
begin
  writeln('Warning (' + sFile + ', line ' + IntToStr(sLine) + '): ' + s);
  fSL.Add('Warning (' + sFile + ', line ' + IntToStr(sLine) + '): ' + s);
end;

procedure TModuleLogFile.CheckModConf;
begin
  if GetConfVal('used') = '' then
    SetConfVal('LogFile', ModuleManager.ModPathes.ConfigPath + 'log.txt');
  SetConfVal('used', '1');
end;

end.

