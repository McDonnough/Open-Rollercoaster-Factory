program orcf;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Classes, m_varlist, main;

{$IFDEF WINDOWS}{$R orcf.rc}{$ENDIF}

begin
  Randomize;
  ModuleManager := TModuleManager.Create;
  ModuleManager.LoadModules;
  ChangeRenderState(rsMainMenu);
  ModuleManager.ModGLContext.StartMainLoop;
  ModuleManager.UnloadModules;
  ModuleManager.Free;
end.

