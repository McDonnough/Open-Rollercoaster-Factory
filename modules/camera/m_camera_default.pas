unit m_camera_default;

interface

uses
  SysUtils, Classes, m_camera_class;

type
  TModuleCameraDefault = class(TModuleCameraClass)
    protected
      fSpeed: Single;
    public
      procedure AdvanceActiveCamera;
      procedure CheckModConf;
      constructor Create;
    end;

implementation

uses
  u_vectors, u_math, math, main, m_varlist, m_inputhandler_class, g_camera;

procedure TModuleCameraDefault.AdvanceActiveCamera;
begin
  if ActiveCamera = nil then exit;
  ActiveCamera.Position := ActiveCamera.Position + Vector(Sin(DegToRad(ActiveCamera.Rotation.Y)) * Cos(DegToRad(ActiveCamera.Rotation.X)), -Sin(DegToRad(ActiveCamera.Rotation.X)), -Cos(DegToRad(ActiveCamera.Rotation.Y)) * Cos(DegToRad(ActiveCamera.Rotation.X))) * fSpeed * FPSDisplay.MS;
  if ModuleManager.ModInputHandler.Key[K_UP] then
    begin
    if fSpeed < 0.05 then
      fSpeed := fSpeed + 0.0005 * FPSDisplay.MS
    end
  else if ModuleManager.ModInputHandler.Key[K_DOWN] then
    begin
    if fSpeed > -0.05 then
      fSpeed := fSpeed - 0.0005 * FPSDisplay.MS
    end
  else
    if fSpeed > 0.05 then
      fSpeed := fSpeed - 0.05
    else if fSpeed < -0.05 then
      fSpeed := fSpeed + 0.05
    else
      fSpeed := 0;
  if ModuleManager.ModInputHandler.Key[K_RIGHT] then
    ActiveCamera.Rotation.Y := ActiveCamera.Rotation.Y + FPSDisplay.MS * 0.05
  else if ModuleManager.ModInputHandler.Key[K_LEFT] then
    ActiveCamera.Rotation.Y := ActiveCamera.Rotation.Y - FPSDisplay.MS * 0.05;
  if ModuleManager.ModInputHandler.Key[K_W] then
    ActiveCamera.Rotation.X := ActiveCamera.Rotation.X - FPSDisplay.MS * 0.05
  else if ModuleManager.ModInputHandler.Key[K_S] then
    ActiveCamera.Rotation.X := ActiveCamera.Rotation.X + FPSDisplay.MS * 0.05;
  if ModuleManager.ModInputHandler.Key[K_A] then
    begin
    ActiveCamera.Position.X := ActiveCamera.Position.X + Sin(DegToRad(ActiveCamera.Rotation.Y - 90)) * FPSDisplay.MS * 0.05;
    ActiveCamera.Position.Z := ActiveCamera.Position.Z - Cos(DegToRad(ActiveCamera.Rotation.Y - 90)) * FPSDisplay.MS * 0.05;
    end;
  if ModuleManager.ModInputHandler.Key[K_D] then
    begin
    ActiveCamera.Position.X := ActiveCamera.Position.X - Sin(DegToRad(ActiveCamera.Rotation.Y - 90)) * FPSDisplay.MS * 0.05;
    ActiveCamera.Position.Z := ActiveCamera.Position.Z + Cos(DegToRad(ActiveCamera.Rotation.Y - 90)) * FPSDisplay.MS * 0.05;
    end;
end;

procedure TModuleCameraDefault.CheckModConf;
begin
end;

constructor TModuleCameraDefault.Create;
begin
  fModName := 'CameraDefault';
  fModType := 'Camera';

  fSpeed := 0;
end;

end.