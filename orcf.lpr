program orcf;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Classes, m_varlist, main, u_events;

{$IFDEF WINDOWS}{$R orcf.rc}{$ENDIF}

begin
  DecimalSeparator := '.';
  Randomize;
  EventManager := TEventManager.Create;
  ModuleManager := TModuleManager.Create;
  ModuleManager.LoadModules;
  ChangeRenderState(rsMainMenu);
  ModuleManager.ModGLContext.StartMainLoop;
  ModuleManager.UnloadModules;
  ModuleManager.Free;
  EventManager.Free;
end.

