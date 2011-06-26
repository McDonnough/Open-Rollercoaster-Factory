unit m_camera_default;

interface

uses
  SysUtils, Classes, u_vectors, m_camera_class;

type
  TModuleCameraDefault = class(TModuleCameraClass)
    protected
      fMaxSpeedTime: Single;
      fSpeedFactors: Array[0..8] of Single;
      fSpeedTimes: Array[0..8] of Single;
      fSpeedIncreasing: Array[0..8] of Single;
      fTimeFactors: Array[0..8] of Single;
      fRotating, fMoving: Boolean;
      fInitialXRotation, fInitialYRotation: Single;
      fCamSource, fSourcePosition, fVecToFront, fVecX, fVecZ: TVector3D;

      function SpeedAtTime(T: Single): Single;
      function GetDirection(Key: Integer): Integer;
      procedure HandleMouseDown(Event: String; Data, Result: Pointer);
      procedure HandleMouseUp(Event: String; Data, Result: Pointer);
      procedure HandleScroll(Event: String; Data, Result: Pointer);
      procedure HandleKeyDown(Event: String; Data, Result: Pointer);
      procedure HandleKeyUp(Event: String; Data, Result: Pointer);
    public
      procedure AdvanceActiveCamera;
      procedure CheckModConf;
      constructor Create;
    end;

implementation

uses
  u_math, math, main, m_varlist, m_inputhandler_class, g_camera, g_park, u_events;

const
  DIR_FORWARD = 0;
  DIR_BACKWARD = 1;
  DIR_LEFT = 2;
  DIR_RIGHT = 3;
  DIR_ROT_LEFT = 4;
  DIR_ROT_RIGHT = 5;
  DIR_ROT_UP = 6;
  DIR_ROT_DOWN = 7;
  DIR_NONE = 8;

function TModuleCameraDefault.SpeedAtTime(T: Single): Single;
begin
  Result := T;
end;

function TModuleCameraDefault.GetDirection(Key: Integer): Integer;
begin
  Result := 8;
  case Key of
    K_UP: Result := DIR_FORWARD;
    K_DOWN: Result := DIR_BACKWARD;
    K_A: Result := DIR_LEFT;
    K_D: Result := DIR_RIGHT;
    K_LEFT: Result := DIR_ROT_LEFT;
    K_RIGHT: Result := DIR_ROT_RIGHT;
    K_W: Result := DIR_ROT_UP;
    K_S: Result := DIR_ROT_DOWN;
    end;
end;

procedure TModuleCameraDefault.HandleMouseDown(Event: String; Data, Result: Pointer);
begin
  if not ((ModuleManager.ModInputHandler.Key[K_LCTRL]) or (fRotating) or (fMoving)) then
    begin
    if ModuleManager.ModInputHandler.MouseButtons[MOUSE_MIDDLE] then
      fRotating := True
    else if ModuleManager.ModInputHandler.MouseButtons[MOUSE_RIGHT] then
      fMoving := True
    else
      Exit;
    fSourcePosition := ModuleManager.ModRenderer.SelectionStart + ModuleManager.ModRenderer.SelectionRay;
    fInitialYRotation := ActiveCamera.Rotation.Y;
    fInitialXRotation := ActiveCamera.Rotation.X;
    fCamSource := ActiveCamera.Position;
    ModuleManager.ModInputHandler.LockMouse;
    fVecToFront := Normalize(Vector(Sin(DegToRad(ActiveCamera.Rotation.Y)) * Cos(DegToRad(ActiveCamera.Rotation.X)),
                                   -Sin(DegToRad(ActiveCamera.Rotation.X)),
                                   -Cos(DegToRad(ActiveCamera.Rotation.Y)) * Cos(DegToRad(ActiveCamera.Rotation.X))));
    fVecX := Normalize(Cross(fVecToFront, Vector(0, 1, 0))) * 0.01 * VecLength(ModuleManager.ModRenderer.SelectionRay);
    fVecZ := Normalize(Cross(fVecX, Vector(0, 1, 0))) * 0.01 * VecLength(ModuleManager.ModRenderer.SelectionRay);
    end;
end;

procedure TModuleCameraDefault.HandleMouseUp(Event: String; Data, Result: Pointer);
begin
  if not (ModuleManager.ModInputHandler.Key[K_LCTRL]) then
    begin
    if (fRotating) or (fMoving) then
      ModuleManager.ModInputHandler.UnlockMouse;
    fRotating := False;
    fMoving := False;
    end;
end;

procedure TModuleCameraDefault.HandleScroll(Event: String; Data, Result: Pointer);
begin
  if ModuleManager.ModInputHandler.MouseButtons[MOUSE_WHEEL_UP] then
    ActiveCamera.Position := ActiveCamera.Position + ModuleManager.ModRenderer.SelectionRay * 0.15
  else if ModuleManager.ModInputHandler.MouseButtons[MOUSE_WHEEL_DOWN] then
    ActiveCamera.Position := ActiveCamera.Position - ModuleManager.ModRenderer.SelectionRay * 0.15;
end;

procedure TModuleCameraDefault.HandleKeyDown(Event: String; Data, Result: Pointer);
begin
  fSpeedIncreasing[GetDirection(Integer(Result^))] := 1;
end;

procedure TModuleCameraDefault.HandleKeyUp(Event: String; Data, Result: Pointer);
begin
  fSpeedIncreasing[GetDirection(Integer(Result^))] := -1;
end;

procedure TModuleCameraDefault.AdvanceActiveCamera;
var
  i: Integer;
begin
  if ActiveCamera = nil then exit;

  if fRotating then
    begin
    ActiveCamera.Rotation.Y := fInitialYRotation - (ModuleManager.ModInputHandler.LockX - ModuleManager.ModInputHandler.MouseX);
    ActiveCamera.Rotation.X := fInitialXRotation - (ModuleManager.ModInputHandler.LockY - ModuleManager.ModInputHandler.MouseY);
    ActiveCamera.Position := fCamSource - fSourcePosition;
    ActiveCamera.Position := ActiveCamera.Position * Matrix3D(RotationMatrix((ModuleManager.ModInputHandler.LockY - ModuleManager.ModInputHandler.MouseY), Normalize(Cross(fVecToFront, Vector(0, 1, 0)))));
    ActiveCamera.Position := ActiveCamera.Position * Matrix3D(RotationMatrix((ModuleManager.ModInputHandler.LockX - ModuleManager.ModInputHandler.MouseX), Vector(0, 1, 0)));
    ActiveCamera.Position := ActiveCamera.Position + fSourcePosition;
    end
  else if fMoving then
    begin
    ActiveCamera.Position := fCamSource - fVecX * (ModuleManager.ModInputHandler.LockX - ModuleManager.ModInputHandler.MouseX);
    ActiveCamera.Position := ActiveCamera.Position - fVecZ * (ModuleManager.ModInputHandler.LockY - ModuleManager.ModInputHandler.MouseY);
    end;

  // Advance speeds etc
  for i := 0 to 7 do
    begin
    fSpeedTimes[i] := Clamp(fSpeedTimes[i] + fSpeedIncreasing[i] * 0.001 * FPSDisplay.MS * fTimeFactors[i], 0, fMaxSpeedTime);
    fSpeedFactors[i] := SpeedAtTime(fSpeedTimes[i]);
    end;
  
  ActiveCamera.Position := ActiveCamera.Position + Normalize(Vector(Sin(DegToRad(ActiveCamera.Rotation.Y)) * Cos(DegToRad(ActiveCamera.Rotation.X)), -Sin(DegToRad(ActiveCamera.Rotation.X)), -Cos(DegToRad(ActiveCamera.Rotation.Y)) * Cos(DegToRad(ActiveCamera.Rotation.X)))) * (fSpeedFactors[DIR_FORWARD] - fSpeedFactors[DIR_BACKWARD]) * FPSDisplay.MS * 0.02;
  ActiveCamera.Position.Y := clamp(ActiveCamera.Position.Y, max(0, Park.pTerrain.HeightMap[ActiveCamera.Position.X, ActiveCamera.Position.Z] + 0.6), 300);

  ActiveCamera.Position.X := ActiveCamera.Position.X + Sin(DegToRad(ActiveCamera.Rotation.Y - 90)) * (fSpeedFactors[DIR_LEFT] - fSpeedFactors[DIR_RIGHT]) * FPSDisplay.MS * 0.02;
  ActiveCamera.Position.Z := ActiveCamera.Position.Z - Cos(DegToRad(ActiveCamera.Rotation.Y - 90)) * (fSpeedFactors[DIR_LEFT] - fSpeedFactors[DIR_RIGHT]) * FPSDisplay.MS * 0.02;

  ActiveCamera.Rotation.X := ActiveCamera.Rotation.X + FPSDisplay.MS * 0.05 * (fSpeedFactors[DIR_ROT_DOWN] - fSpeedFactors[DIR_ROT_UP]);
  ActiveCamera.Rotation.Y := ActiveCamera.Rotation.Y + FPSDisplay.MS * 0.05 * (fSpeedFactors[DIR_ROT_RIGHT] - fSpeedFactors[DIR_ROT_LEFT]);
end;

procedure TModuleCameraDefault.CheckModConf;
begin
end;

constructor TModuleCameraDefault.Create;
var
  i: Integer;
begin
  fModName := 'CameraDefault';
  fModType := 'Camera';

  fMaxSpeedTime := 1;

  for i := 0 to high(fSpeedIncreasing) do
    begin
    fSpeedIncreasing[i] := 0;
    fSpeedFactors[i] := 0;
    fSpeedTimes[i] := 0;
    fTimeFactors[i] := 1;
    if i >= 4 then
      fTimeFactors[i] := 4;
    end;

  fRotating := False;
  fMoving := False;

  EventManager.AddCallback('BasicComponent.OnKeyDown', @HandleKeyDown);
  EventManager.AddCallback('BasicComponent.OnKeyUp', @HandleKeyUp);
  EventManager.AddCallback('BasicComponent.OnScroll', @HandleScroll);
  EventManager.AddCallback('BasicComponent.OnClick', @HandleMouseDown);
  EventManager.AddCallback('BasicComponent.OnRelease', @HandleMouseUp);
end;

end.