unit m_glcontext_gglut;

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
      procedure CheckModConf;
      procedure ChangeWindowTitle(Text: String);
      procedure GetResolution(var ResX: Integer; var ResY: Integer);
      procedure SwapBuffers;
      procedure StartMainLoop;
      procedure EndMainLoop;
      procedure InitGL;
      function SetResolution(ResX, ResY: Integer): Boolean;
      function IsFullscreen: Boolean;
      function SetFullscreenState(Fullscreen: Boolean): Boolean;
    end;

implementation

uses
  m_varlist, main;

constructor TModuleGLContextGLUT.Create;
begin
  fModName := 'GLContextGLUT';
  fModType := 'GLContext';

  CheckModConf;

  glutInit(@argc, @argv);
  glutInitDisplayMode(GLUT_DOUBLE or GLUT_RGB or GLUT_DEPTH);
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

