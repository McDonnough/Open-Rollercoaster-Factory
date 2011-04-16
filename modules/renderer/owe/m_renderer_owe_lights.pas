unit m_renderer_owe_lights;

interface

uses
  SysUtils, Classes, DGLOpenGL, math, u_math, u_vectors, u_scene, m_renderer_owe_frustum;

type
  TLight = class
    protected
      fInternalID: Integer;
      fHints: QWord;
      fLightSource: TLightSource;
    public
      property LightSource: TLightSource read fLightSource;
      function Strength(Distance: Single): Single;
      function IsVisible(A: TFrustum): Boolean;
      function MaxLightingEffect: Single;
      procedure Bind(I: Integer);
      procedure Unbind(I: Integer);
      constructor Create(LS: TLightSource);
      destructor Free;
    end;

  TSun = class
    public
      Position: TVector4D;
      AmbientColor, Color: TVector4D;
      procedure Bind(I: Integer);
      constructor Create;
      destructor Free;
    end;

  TLightManager = class
    public
      fRegisteredLights: Array of TLight;
      fSun: TSun;
      procedure SetSun(Sun: TSun);
      procedure AddLight(Light: TLight);
      procedure RemoveLight(Light: TLight);
      destructor Free;
    end;

implementation

uses
  m_varlist;

function TLight.Strength(Distance: Single): Single;
begin
  // 0.5774 = 1 / SQRT(3)
  Result := VecLength(LightSource.Color) * LightSource.DiffuseFactor * LightSource.Energy * 0.5774 * LightSource.FalloffDistance * LightSource.FalloffDistance / (LightSource.FalloffDistance * LightSource.FalloffDistance + Distance * Distance);
end;

function TLight.MaxLightingEffect: Single;
const
  LIGHT_MIN_CHANGE: Single = 0.01;
begin
  // 0.5774 = 1 / SQRT(3)
  Result := sqrt(Max(0.0, VecLength(LightSource.Color) * LightSource.DiffuseFactor * LightSource.Energy * 0.5774 - LIGHT_MIN_CHANGE) * LightSource.FalloffDistance * LightSource.FalloffDistance / LIGHT_MIN_CHANGE);
end;

function TLight.IsVisible(A: TFrustum): Boolean;
begin
  Result := (VecLengthNoRoot(Vector3D(fLightSource.Position) - ModuleManager.ModCamera.ActiveCamera.Position) <= MaxLightingEffect * MaxLightingEffect)
         or (A.IsSphereWithin(fLightSource.Position.X, fLightSource.Position.Y, fLightSource.Position.Z, MaxLightingEffect));
end;

procedure TLight.Bind(I: Integer);
var
  A, B: TVector4D;
begin
  glMatrixMode(GL_MODELVIEW);
  glPushMatrix;
  glLoadIdentity;
  glEnable(GL_LIGHT0 + i);
  A := Vector(LightSource.Color * LightSource.DiffuseFactor, LightSource.Energy);
  B := Vector(LightSource.Color, LightSource.FalloffDistance);
  glLightfv(GL_LIGHT0 + i, GL_DIFFUSE,  @A.X);
  glLightfv(GL_LIGHT0 + i, GL_AMBIENT,  @B.X);
  glLightfv(GL_LIGHT0 + i, GL_POSITION, @LightSource.Position.X);
  glPopMatrix;
end;

procedure TLight.Unbind(I: Integer);
var
  Null: TVector4D;
begin
  Null := Vector(0, 0, 0, 1);
  glMatrixMode(GL_MODELVIEW);
  glPushMatrix;
  glLoadIdentity;
  glEnable(GL_LIGHT0 + i);
  glLightfv(GL_LIGHT0 + i, GL_DIFFUSE,  @Null.X);
  glLightfv(GL_LIGHT0 + i, GL_POSITION, @Null.X);
  glPopMatrix;
end;

constructor TLight.Create(LS: TLightSource);
begin
  fLightSource := LS;
  ModuleManager.ModRenderer.LightManager.AddLight(Self);
end;

destructor TLight.Free;
begin
  ModuleManager.ModRenderer.LightManager.RemoveLight(Self);
end;


constructor TSun.Create;
begin
  Color := Vector(1, 1, 1, 1);
  Position := Vector(-1000, 0, 0, 0);
  ModuleManager.ModRenderer.LightManager.SetSun(Self);
end;

procedure TSun.Bind(I: Integer);
begin
  glEnable(GL_LIGHT0 + i);
  glLightfv(GL_LIGHT0 + i, GL_AMBIENT,  @AmbientColor.X);
  glLightfv(GL_LIGHT0 + i, GL_DIFFUSE,  @Color.X);
  glLightfv(GL_LIGHT0 + i, GL_POSITION, @Position.X);
end;

destructor TSun.Free;
begin
  ModuleManager.ModRenderer.LightManager.SetSun(nil);
end;


procedure TLightManager.SetSun(Sun: TSun);
begin
  fSun := Sun;
end;

procedure TLightManager.AddLight(Light: TLight);
begin
  SetLength(fRegisteredLights, length(fRegisteredLights) + 1);
  fRegisteredLights[high(fRegisteredLights)] := Light;
end;

procedure TLightManager.RemoveLight(Light: TLight);
var
  i: Integer;
begin
  for i := 0 to high(fRegisteredLights) do
    if fRegisteredLights[i] = Light then
      begin
      fRegisteredLights[i] := fRegisteredLights[high(fRegisteredLights)];
      SetLength(fRegisteredLights, length(fRegisteredLights) - 1);
      exit;
      end;
end;

destructor TLightManager.Free;
begin
  while length(fRegisteredLights) > 0 do
    fRegisteredLights[0].Free;
  if fSun <> nil then
    fSun.Free;
end;

end.