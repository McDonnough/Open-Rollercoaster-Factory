unit m_camera_default;

interface

uses
  SysUtils, Classes, m_camera_class;

type
  TModuleCameraDefault = class(TModuleCameraClass)
    protected
      fSpeed: Single;
      fHSpeed: Single;
    public
      procedure AdvanceActiveCamera;
      procedure CheckModConf;
      constructor Create;
    end;

implementation

uses
  u_vectors, u_math, math, main, m_varlist, m_inputhandler_class, g_camera, g_park;

procedure TModuleCameraDefault.AdvanceActiveCamera;
var
  ShiftFactor: Integer;
begin
  if ActiveCamera = nil then exit;
  ShiftFactor := 1;
  if ModuleManager.ModInputHandler.Key[K_LSHIFT] then
    ShiftFactor := 10;
  ActiveCamera.Position := ActiveCamera.Position + Vector(Sin(DegToRad(ActiveCamera.Rotation.Y)) * Cos(DegToRad(ActiveCamera.Rotation.X)), -Sin(DegToRad(ActiveCamera.Rotation.X)), -Cos(DegToRad(ActiveCamera.Rotation.Y)) * Cos(DegToRad(ActiveCamera.Rotation.X))) * fSpeed * FPSDisplay.MS;
  ActiveCamera.Position.Y := clamp(ActiveCamera.Position.Y, max(0, Park.pTerrain.HeightMap[ActiveCamera.Position.X, ActiveCamera.Position.Z] + 0.2), 300);
  if ModuleManager.ModInputHandler.Key[K_UP] then
    begin
    if fSpeed < 0.020 then
      fSpeed := fSpeed + 0.000040 * FPSDisplay.MS * ShiftFactor
    end
  else if ModuleManager.ModInputHandler.Key[K_DOWN] then
    begin
    if fSpeed > -0.020 then
      fSpeed := fSpeed - 0.000040 * FPSDisplay.MS * ShiftFactor
    end
  else
    fSpeed := fSpeed / 1.2;
  if ModuleManager.ModInputHandler.Key[K_A] then
    begin
    if fHSpeed < 0.020 then
      fHSpeed := fHSpeed + 0.000040 * FPSDisplay.MS * ShiftFactor
    end
  else if ModuleManager.ModInputHandler.Key[K_D] then
    begin
    if fHSpeed > -0.020 then
      fHSpeed := fHSpeed - 0.000040 * FPSDisplay.MS * ShiftFactor
    end
  else
    fHSpeed := fHSpeed / 1.2;
  if ModuleManager.ModInputHandler.Key[K_RIGHT] then
    ActiveCamera.Rotation.Y := ActiveCamera.Rotation.Y + FPSDisplay.MS * 0.05
  else if ModuleManager.ModInputHandler.Key[K_LEFT] then
    ActiveCamera.Rotation.Y := ActiveCamera.Rotation.Y - FPSDisplay.MS * 0.05;
  if ModuleManager.ModInputHandler.Key[K_W] then
    ActiveCamera.Rotation.X := ActiveCamera.Rotation.X - FPSDisplay.MS * 0.05
  else if ModuleManager.ModInputHandler.Key[K_S] then
    ActiveCamera.Rotation.X := ActiveCamera.Rotation.X + FPSDisplay.MS * 0.05;
  ActiveCamera.Position.X := ActiveCamera.Position.X + Sin(DegToRad(ActiveCamera.Rotation.Y - 90)) * FPSDisplay.MS * fHSpeed;
  ActiveCamera.Position.Z := ActiveCamera.Position.Z - Cos(DegToRad(ActiveCamera.Rotation.Y - 90)) * FPSDisplay.MS * fHSpeed;
end;

procedure TModuleCameraDefault.CheckModConf;
begin
end;

constructor TModuleCameraDefault.Create;
begin
  fModName := 'CameraDefault';
  fModType := 'Camera';

  fSpeed := 0;
  fHSpeed := 0;
end;

end.