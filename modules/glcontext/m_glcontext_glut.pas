unit m_glcontext_glut;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_glcontext_class, GLUT, dglOpenGL;

type
  TModuleGLContextGLUT = class(TModuleGLContextClass)
    protected
      fWin: THandle;
    public
      constructor Create;
      destructor Free;
      procedure CheckModConf; override;
      procedure ChangeWindowTitle(Text: String); override;
      procedure GetResolution(var ResX: Integer; var ResY: Integer); override;
      procedure SwapBuffers; override;
      procedure StartMainLoop; override;
      procedure EndMainLoop; override;
      procedure InitGL; override;
      function SetResolution(ResX, ResY: Integer): Boolean; override;
      function IsFullscreen: Boolean; override;
      function SetFullscreenState(Fullscreen: Boolean): Boolean; override;
    end;

implementation

uses
  m_varlist, main, u_events;

constructor TModuleGLContextGLUT.Create;
begin
  fModName := 'GLContextGLUT';
  fModType := 'GLContext';

  CheckModConf;

  glutInit(@argc, @argv);
  glutInitDisplayMode(GLUT_DOUBLE or GLUT_RGB or GLUT_STENCIL or GLUT_ACCUM or GLUT_DEPTH);
  glutInitWindowSize(800, 600);
  fWin := glutCreateWindow('ORCF');
  SetResolution(StrToInt(GetConfVal('ResX')), StrToInt(GetConfVal('ResY')));
end;

destructor TModuleGLContextGLUT.Free;
begin
end;

procedure TModuleGLContextGLUT.CheckModConf;
begin
  if GetConfVal('used') = '' then
    begin
    SetConfVal('used', '1');
    setConfVal('ResX', '800');
    SetConfVal('ResY', '600');
    end;
end;

procedure TModuleGLContextGLUT.ChangeWindowTitle(Text: String);
begin
  glutSetWindowTitle(PChar(Text));
end;

procedure TModuleGLContextGLUT.GetResolution(var ResX: Integer; var ResY: Integer);
begin
  ResX := StrToInt(GetConfVal('ResX'));
  ResY := StrToInt(GetConfVal('ResY'));
end;

procedure TModuleGLContextGLUT.SwapBuffers;
begin
  glutSwapBuffers;
end;

procedure TModuleGLContextGLUT.StartMainLoop;
begin
  glutDisplayFunc(@MainLoop);
  glutIdleFunc(@MainLoop);
  glutMainLoop;
end;

procedure TModuleGLContextGLUT.EndMainLoop;
begin
  glutDestroyWindow(fWin);
  ModuleManager.UnloadModules;
  ModuleManager.Free;
  EventManager.Free;
  halt(0);
end;

procedure TModuleGLContextGLUT.InitGL;
begin
  InitOpenGL;
  ReadExtensions;
  ReadImplementationProperties;
end;

function TModuleGLContextGLUT.SetResolution(ResX, ResY: Integer): Boolean;
begin
  glutReshapeWindow(ResX, ResY);
  SetConfVal('ResX', IntToStr(ResX));
  SetConfVal('ResY', IntToStr(ResY));
  result := true;
end;

function TModuleGLContextGLUT.IsFullscreen: Boolean;
begin
  result := false;
end;

function TModuleGLContextGLUT.SetFullscreenState(Fullscreen: Boolean): Boolean;
begin
  result := false;
end;

end.

