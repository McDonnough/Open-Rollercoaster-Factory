unit m_glmng_default;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_glmng_class, DGLOpenGL;

type
  TMatrixMode = (mmIdentity, mm2D, mm3D);

  TModuleGLMngDefault = class(TModuleGLMngClass)
    protected
      fMatrixMode: TMatrixMode;
    public
      constructor Create;
      procedure CheckModConf; override;
      procedure SetUp2DMatrix; override;
      procedure SetUp3DMatrix; override;
      procedure SetUpIdentityMatrix; override;
      procedure SetUpScreen; override;
    end;

implementation

uses
  m_varlist;

constructor TModuleGLMngDefault.Create;
begin
  fModName := 'GLMngDefault';
  fModType := 'GLMng';
end;

procedure TModuleGLMngDefault.CheckModConf;
begin
end;

procedure TModuleGLMngDefault.SetUp2DMatrix;
var
  X, Y: Integer;
begin
  ModuleManager.ModGLContext.GetResolution(X, Y);
  fMatrixMode := mm2D;
  glLoadIdentity;
  glOrtho(0, X, Y, 0, 0, 255);
end;

procedure TModuleGLMngDefault.SetUp3DMatrix;
var
  X, Y: Integer;
begin
  ModuleManager.ModGLContext.GetResolution(X, Y);
  fMatrixMode := mm3D;
  glLoadIdentity;
  fFOV := 45 * (y / x / 2 + 0.5);
  gluPerspective(fFOV, X / Y * AspectRatioFactor, 0.1, 10000);
end;

procedure TModuleGLMngDefault.SetUpIdentityMatrix;
begin
  if fMatrixMode = mmIdentity then
    exit;
  fMatrixMode := mmIdentity;
  glLoadIdentity;
end;

procedure TModuleGLMngDefault.SetUpScreen;
var
  X, Y: Integer;
begin
  glClearColor(0.0, 0.0, 0.0, 0.0);
  glClearDepth(1.0);
  ModuleManager.ModGLContext.GetResolution(X, Y);
  glViewport(0, 0, X, Y);
  glClear(GL_DEPTH_BUFFER_BIT or GL_COLOR_BUFFER_BIT or GL_STENCIL_BUFFER_BIT);
  AspectRatioFactor := 1;
end;

end.

