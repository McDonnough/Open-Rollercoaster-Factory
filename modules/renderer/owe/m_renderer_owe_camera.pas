unit m_renderer_owe_camera;

interface

uses
  SysUtils, Classes, DGLOpenGL, m_renderer_owe_classes, u_vectors, u_math;

type
  TRCamera = class
    procedure ApplyRotation(Factor: TVector3D);
    procedure ApplyTransformation(Factor: TVector3D);
    end;

implementation

uses
  m_varlist;

procedure TRCamera.ApplyRotation(Factor: TVector3D);
begin
  glRotatef(ModuleManager.ModCamera.ActiveCamera.Rotation.Z * Factor.Z, 0, 0, 1);
  glRotatef(ModuleManager.ModCamera.ActiveCamera.Rotation.X * Factor.X, 1, 0, 0);
  glRotatef(ModuleManager.ModCamera.ActiveCamera.Rotation.Y * Factor.Y, 0, 1, 0);
end;

procedure TRCamera.ApplyTransformation(Factor: TVector3D);
begin
  glTranslatef(-ModuleManager.ModCamera.ActiveCamera.Position.X * Factor.X, -ModuleManager.ModCamera.ActiveCamera.Position.Y * Factor.Y, -ModuleManager.ModCamera.ActiveCamera.Position.Z * Factor.Z);
end;


end.