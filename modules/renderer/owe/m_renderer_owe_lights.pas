unit m_renderer_owe_lights;

interface

uses
  SysUtils, Classes, DGLOpenGL, math, u_math, u_vectors, u_scene, m_renderer_owe_frustum,
  m_renderer_owe_classes;

type
  TLight = class
    private
      fCalculatedStrength: Single;
      fShadowMap: TFBO;
    protected
      fInternalID: Integer;
      fHints: QWord;
      fLightSource: TLightSource;
    public
      property LightSource: TLightSource read fLightSource;
      property ShadowMap: TFBO read fShadowMap;
      function Strength(Distance: Single): Single;
      function IsVisible(A: TFrustum): Boolean;
      function MaxLightingEffect: Single;
      procedure Bind(I: Integer);
      procedure Unbind(I: Integer);
//       procedure CreateShadows(I: Integer);
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

  TLightManager = class(TThread)
    protected
      fCanWork, fWorking: Boolean;
      fShadowBuffers: Array of TFBO;
      fMaxShadowBuffers: Integer;
    public
      fRegisteredLights: Array of TLight;
      fSun: TSun;
      procedure Sync;
      procedure Execute; override;
      procedure SetSun(Sun: TSun);
      procedure AddLight(Light: TLight);
      procedure RemoveLight(Light: TLight);
      procedure QuicksortLights;
      constructor Create;
      procedure Free;
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
  LIGHT_MIN_CHANGE: Single = 0.03;
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


procedure TLightManager.Sync;
begin
  while fWorking do
    sleep(1);
end;

procedure TLightManager.QuicksortLights;
  procedure DoQuicksort(First, Last: Integer);
    procedure Swap(X, Y: Integer);
    var
      Z: TLight;
    begin
      Z := fRegisteredLights[X];
      fRegisteredLights[X] := fRegisteredLights[Y];
      fRegisteredLights[Y] := Z;
    end;
  var
    PivotID, i, j: Integer;
    Pivot: Single;
  begin
    if First >= Last then
      exit;
    PivotID := (First + Last) div 2;
    Pivot := fRegisteredLights[PivotID].fCalculatedStrength;

    i := First;
    j := Last - 1;

    repeat
      while (fRegisteredLights[i].fCalculatedStrength <= Pivot) and (i < Last) do
        inc(i);

      while (fRegisteredLights[j].fCalculatedStrength >= Pivot) and (j > First) do
        dec(j);

      if i < j then
        Swap(i, j);
    until
      i >= j;
    Swap(i, PivotID);

    DoQuicksort(First, PivotID - 1);
    DoQuicksort(PivotID + 1, Last);
  end;
begin
  DoQuicksort(0, high(fRegisteredLights));
end;

procedure TLightManager.Execute;
var
  i: Integer;
begin
  fWorking := False;
  fCanWork := False;
  while not Terminated do
    begin
    if fCanWork then
      begin
      fCanWork := False;
      fWorking := True;

      for i := 0 to high(fRegisteredLights) do
        fRegisteredLights[i].fCalculatedStrength := fRegisteredLights[i].Strength(VecLength(Vector3D(fRegisteredLights[i].LightSource.Position) - ModuleManager.ModCamera.ActiveCamera.Position));

      QuicksortLights;

      for i := 0 to Min(fMaxShadowBuffers - 1, high(fRegisteredLights)) do
        fRegisteredLights[i].fShadowMap := fShadowBuffers[i];

      fWorking := False;
      end
    else
      sleep(1);
    end;
end;

procedure TLightManager.SetSun(Sun: TSun);
begin
  fSun := Sun;
end;

procedure TLightManager.AddLight(Light: TLight);
begin
  Sync;
  SetLength(fRegisteredLights, length(fRegisteredLights) + 1);
  fRegisteredLights[high(fRegisteredLights)] := Light;
  if length(fRegisteredLights) <= fMaxShadowBuffers then
    begin
    setLength(fShadowBuffers, length(fShadowBuffers) + 1);
    fShadowBuffers[high(fShadowBuffers)] := TFBO.Create(3 * Round(256 * ModuleManager.ModRenderer.LightShadowBufferSamples), 2 * Round(256 * ModuleManager.ModRenderer.LightShadowBufferSamples), true);
    fShadowBuffers[high(fShadowBuffers)].AddTexture(GL_RGBA16F_ARB, GL_LINEAR, GL_LINEAR);
    fShadowBuffers[high(fShadowBuffers)].Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);
    fShadowBuffers[high(fShadowBuffers)].Unbind;
    end;
end;

procedure TLightManager.RemoveLight(Light: TLight);
var
  i, j: Integer;
begin
  Sync;
  for i := 0 to high(fRegisteredLights) do
    if fRegisteredLights[i] = Light then
      begin
      fRegisteredLights[i] := fRegisteredLights[high(fRegisteredLights)];
      SetLength(fRegisteredLights, length(fRegisteredLights) - 1);
      if length(fRegisteredLights) < fMaxShadowBuffers then
        begin
        fShadowBuffers[high(fShadowBuffers)].Free;
        setLength(fShadowBuffers, length(fShadowBuffers) - 1);
        for j := 0 to high(fRegisteredLights) do
          fRegisteredLights[j].fShadowMap := fShadowBuffers[j];
        end;
      break;
      end;
end;

constructor TLightManager.Create;
begin
  fMaxShadowBuffers := ModuleManager.ModRenderer.MaxShadowPasses;
end;

procedure TLightManager.Free;
var
  i: Integer;
begin
  while length(fRegisteredLights) > 0 do
    fRegisteredLights[0].Free;
  if fSun <> nil then
    fSun.Free;
  Terminate;
  Sync;
  inherited Free;
end;

end.