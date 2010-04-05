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
      procedure AddError(s: String; sFile: String = ''; sLine: Integer = 0);
      procedure AddWarning(s: String; sFile: String = ''; sLine: Integer = 0);
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

procedure TModuleLogFile.AddError(s: String; sFile: String = ''; sLine: Integer = 0);
begin
  writeln('Error: ' + s);
  fSL.Add('Error: ' + s);
  fSL.SaveToFile(GetConfVal('LogFile'));
end;

procedure TModuleLogFile.AddWarning(s: String; sFile: String = ''; sLine: Integer = 0);
begin
  writeln('Warning: ' + s);
  fSL.Add('Warning: ' + s);
end;

procedure TModuleLogFile.CheckModConf;
begin
  if GetConfVal('used') = '' then
    SetConfVal('LogFile', ModuleManager.ModPathes.ConfigPath + 'log.txt');
  SetConfVal('used', '1');
end;

end.

