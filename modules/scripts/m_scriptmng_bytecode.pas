unit m_scriptmng_bytecode;

interface

uses
  SysUtils, Classes, u_scripts, m_scriptmng_class;

type
  TModuleScriptManagerBytecode = class(TModuleScriptManagerClass)
    public
      procedure SetInVar(Script: TScript; Name: String; Location: Pointer);
      procedure SetInOutVar(Script: TScript; Name: String; Location: Pointer);
      procedure Execute(Script: TScript);
      procedure AddScript(Script: TScript);
      procedure DestroyScript(Script: TScript);
      procedure DestroyCode(Code: TScriptCode);
      procedure CheckModConf;
      constructor Create;
    end;

implementation

procedure TModuleScriptManagerBytecode.SetInVar(Script: TScript; Name: String; Location: Pointer);
begin
end;

procedure TModuleScriptManagerBytecode.SetInOutVar(Script: TScript; Name: String; Location: Pointer);
begin
end;

procedure TModuleScriptManagerBytecode.Execute(Script: TScript);
begin
end;

procedure TModuleScriptManagerBytecode.AddScript(Script: TScript);
begin
end;

procedure TModuleScriptManagerBytecode.DestroyScript(Script: TScript);
begin
end;

procedure TModuleScriptManagerBytecode.DestroyCode(Code: TScriptCode);
begin
end;

procedure TModuleScriptManagerBytecode.CheckModConf;
begin
end;

constructor TModuleScriptManagerBytecode.Create;
begin
  fModName := 'ScriptManagerBytecode';
  fModType := 'ScriptManager';
end;

end.