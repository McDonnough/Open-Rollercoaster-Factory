program orcf;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Classes, m_varlist, main, u_events, u_dialogs;

{$IFDEF WINDOWS}{$R orcf.rc}{$ENDIF}

begin
  Randomize;
  EventManager := TEventManager.Create;
  ModuleManager := TModuleManager.Create;
  ModuleManager.LoadModules;
  DialogManager := TDialogManager.Create;
  ChangeRenderState(rsMainMenu);
  ModuleManager.ModGLContext.StartMainLoop;
  DialogManager.Free;
  ModuleManager.UnloadModules;
  ModuleManager.Free;
  EventManager.Free;
end.

