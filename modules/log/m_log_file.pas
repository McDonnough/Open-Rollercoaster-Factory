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
      procedure AddError(s: String);
      procedure AddWarning(s: String);
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
  fSL.SaveToFile(ModuleManager.ModPathes.ConfigPath + 'log.txt');
  fSL.free;
end;

procedure TModuleLogFile.AddError(s: String);
begin
  writeln('Error: ' + s);
  fSL.Add('Error: ' + s);
  fSL.SaveToFile(ModuleManager.ModPathes.ConfigPath + 'log.txt');
end;

procedure TModuleLogFile.AddWarning(s: String);
begin
  writeln('Warning: ' + s);
  fSL.Add('Warning: ' + s);
end;

procedure TModuleLogFile.CheckModConf;
begin
  SetConfVal('used', '1');
end;

end.

