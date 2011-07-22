program orcf;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Classes, m_varlist, main, u_events, g_resources, g_music;

{$IFDEF WINDOWS}{$R orcf.rc}{$ENDIF}

begin
  DecimalSeparator := '.';
  Randomize;
  EventManager := TEventManager.Create;
  ModuleManager := TModuleManager.Create;
  ModuleManager.LoadModules;
  ResourceManager := TResourceManager.Create;
  MusicManager := TMusicManager.Create;
  ChangeRenderState(rsMainMenu);
  ModuleManager.ModGLContext.StartMainLoop;
  MusicManager.Free;
  ResourceManager.Free;
  ModuleManager.UnloadModules;
  ModuleManager.Free;
  EventManager.Free;
end.

