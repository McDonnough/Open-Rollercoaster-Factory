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
  ActiveCamera.Position := ActiveCamera.Position + Vector(Sin(DegToRad(ActiveCamera.Rotation.Y)), Sin(DegToRad(ActiveCamera.Rotation.X)), -Cos(DegToRad(ActiveCamera.Rotation.Y))) * fSpeed * FPSDisplay.MS;
  if ModuleManager.ModInputHandler.Key[K_UP] then
    begin
    if fSpeed < 0.01 then
      fSpeed := fSpeed + 0.0001 * FPSDisplay.MS
    end
  else if ModuleManager.ModInputHandler.Key[K_DOWN] then
    begin
    if fSpeed > -0.01 then
      fSpeed := fSpeed - 0.0001 * FPSDisplay.MS
    end
  else
    if fSpeed > 0.01 then
      fSpeed := fSpeed - 0.01
    else if fSpeed < -0.01 then
      fSpeed := fSpeed + 0.01
    else
      fSpeed := 0;
  if ModuleManager.ModInputHandler.Key[K_RIGHT] then
    ActiveCamera.Rotation.Y := ActiveCamera.Rotation.Y + FPSDisplay.MS * 0.05
  else if ModuleManager.ModInputHandler.Key[K_LEFT] then
    ActiveCamera.Rotation.Y := ActiveCamera.Rotation.Y - FPSDisplay.MS * 0.05
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