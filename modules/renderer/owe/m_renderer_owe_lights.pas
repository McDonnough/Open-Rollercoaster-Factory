unit m_renderer_owe_lights;

interface

uses
  SysUtils, Classes, DGLOpenGL, math, u_math, u_vectors, u_scene, m_renderer_owe_frustum,
  m_renderer_owe_classes, m_renderer_owe_cubemaps, m_renderer_owe_terrain;

type
  TLight = class
    private
      fCalculatedStrength: Single;
      fShadowMap: TShadowCubeMap;
    protected
      fTerrainCastsShadows: Boolean;
      fInternalID: Integer;
      fHints: QWord;
      fLightSource: TLightSource;
    public
      property LightSource: TLightSource read fLightSource;
      property ShadowMap: TShadowCubeMap read fShadowMap;
      function Strength(Distance: Single): Single;
      function IsVisible(A: TFrustum): Boolean;
      function MaxLightingEffect: Single;
      procedure Bind(I: Integer);
      procedure Unbind(I: Integer);
      procedure RenderShadowPass;
      procedure CreateShadows;
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
      fShadowBuffers: Array of TShadowCubeMap;
      fMaxShadowBuffers: Integer;
    public
      fRegisteredLights: Array of TLight;
      fSun: TSun;
      property Working: Boolean read fWorking write fCanWork;
      procedure Sync;
      procedure Execute; override;
      procedure SetSun(Sun: TSun);
      procedure AddLight(Light: TLight);
      procedure RemoveLight(Light: TLight);
      procedure AddLightSource(Event: String; Data, Result: Pointer);
      procedure RemoveLightSource(Event: String; Data, Result: Pointer);
      procedure QuicksortLights;
      procedure CreateShadows;
      constructor Create;
      procedure Free;
    end;

implementation

uses
  m_varlist, u_events;

procedure TLight.RenderShadowPass;
begin
  if fTerrainCastsShadows then
    begin
    ModuleManager.ModRenderer.RTerrain.CurrentShader := ModuleManager.ModRenderer.RTerrain.LightShadowPassShader;
    ModuleManager.ModRenderer.RTerrain.BorderEnabled := false;
    ModuleManager.ModRenderer.RTerrain.Render;
    end;

  ModuleManager.ModRenderer.RObjects.LightShadowMode := True;
  ModuleManager.ModRenderer.RObjects.RenderOpaque;
  ModuleManager.ModRenderer.RObjects.RenderTransparent;
  ModuleManager.ModRenderer.RObjects.LightShadowMode := False;
end;

procedure TLight.CreateShadows;
var
  tmpMaxRenderDistance: Single;
  tmpViewPoint: TVector3D;
  l: Single;

  function CheckRenderTerrain: Boolean;
  var
    i, j: Integer;
    MinBlock, MaxBlock, CBlock: TTerrainBlock;
  begin
    Result := False;

    l := MaxLightingEffect;

    MinBlock := ModuleManager.ModRenderer.RTerrain.GetBlock(LightSource.Position.X - l, LightSource.Position.Z - l);
    MaxBlock := ModuleManager.ModRenderer.RTerrain.GetBlock(LightSource.Position.X + l, LightSource.Position.Z + l);
    for i := MinBlock.X to MaxBlock.X do
      for j := MinBlock.Y to MaxBlock.Y do
        begin
        CBlock := ModuleManager.ModRenderer.RTerrain.GetBlock(25.6 * i + 12.8, 25.6 * j + 12.8);
        if CBlock.MinHeight <> CBlock.MaxHeight then
          Result := Result or (CBlock.MaxHeight > LightSource.Position.Y - l);
        end;
  end;
begin
  if (ShadowMap <> nil) and (LightSource.CastShadows) then
    begin
    l := MaxLightingEffect;
    
    fTerrainCastsShadows := CheckRenderTerrain;
    
    tmpMaxRenderDistance := ModuleManager.ModRenderer.MaxRenderDistance;
    tmpViewPoint := ModuleManager.ModRenderer.ViewPoint;
    
    ModuleManager.ModRenderer.MaxRenderDistance := l;
    ModuleManager.ModRenderer.ViewPoint := Vector3D(LightSource.Position);

    Bind(1);

    ShadowMap.RenderProcedure := @RenderShadowPass;
    ShadowMap.Render(Vector3D(LightSource.Position));

    Unbind(1);

    ModuleManager.ModRenderer.ViewPoint := tmpViewPoint;
    ModuleManager.ModRenderer.MaxRenderDistance := tmpMaxRenderDistance;
    end;
end;

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
  glMatrixMode(GL_MODELVIEW);
  glPushMatrix;
  glLoadIdentity;
  glEnable(GL_LIGHT0 + i);
  glLightfv(GL_LIGHT0 + i, GL_AMBIENT,  @AmbientColor.X);
  glLightfv(GL_LIGHT0 + i, GL_DIFFUSE,  @Color.X);
  glLightfv(GL_LIGHT0 + i, GL_POSITION, @Position.X);
  glPopMatrix;
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

    Swap(PivotID, Last);

    i := First;
    j := Last - 1;

    repeat
      while (fRegisteredLights[i].fCalculatedStrength >= Pivot) and (i < Last) do
        inc(i);

      while (fRegisteredLights[j].fCalculatedStrength <= Pivot) and (j > First) do
        dec(j);

      if i < j then
        Swap(i, j);
    until
      i >= j;
    if fRegisteredLights[i].fCalculatedStrength < Pivot then
      Swap(i, Last);

    DoQuicksort(First, i - 1);
    DoQuicksort(i + 1, Last);
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
        if fRegisteredLights[i].LightSource.CastShadows then
          fRegisteredLights[i].fCalculatedStrength := fRegisteredLights[i].Strength(VecLength(Vector3D(fRegisteredLights[i].LightSource.Position) - ModuleManager.ModCamera.ActiveCamera.Position))
        else
          fRegisteredLights[i].fCalculatedStrength := -1;

      QuicksortLights;

      for i := 0 to high(fRegisteredLights) do
        if (i < fMaxShadowBuffers) and (fRegisteredLights[i].LightSource.CastShadows) then
          fRegisteredLights[i].fShadowMap := fShadowBuffers[i]
        else
          fRegisteredLights[i].fShadowMap := nil;

      fWorking := False;
      end
    else
      sleep(1);
    end;
  writeln('Hint: Terminated light manager thread');
end;

procedure TLightManager.SetSun(Sun: TSun);
begin
  fSun := Sun;
end;

procedure TLightManager.CreateShadows;
var
  i: Integer;
begin
  for i := 0 to Min(fMaxShadowBuffers - 1, high(fRegisteredLights)) do
    begin
    ModuleManager.ModRenderer.Frustum.Push;
    if fRegisteredLights[i].IsVisible(ModuleManager.ModRenderer.Frustum) then
      fRegisteredLights[i].CreateShadows;
    ModuleManager.ModRenderer.Frustum.Pop;
    end;
end;

procedure TLightManager.AddLight(Light: TLight);
begin
  Sync;
  SetLength(fRegisteredLights, length(fRegisteredLights) + 1);
  fRegisteredLights[high(fRegisteredLights)] := Light;
  if length(fRegisteredLights) <= fMaxShadowBuffers then
    begin
    setLength(fShadowBuffers, length(fShadowBuffers) + 1);
    fShadowBuffers[high(fShadowBuffers)] := TShadowCubeMap.Create(Round(256 * ModuleManager.ModRenderer.LightShadowBufferSamples), Round(256 * ModuleManager.ModRenderer.LightShadowBufferSamples), GL_RGBA16F_ARB);
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

procedure TLightManager.AddLightSource(Event: String; Data, Result: Pointer);
begin
  TLight.Create(TLightSource(Data));
end;

procedure TLightManager.RemoveLightSource(Event: String; Data, Result: Pointer);
var
  i: Integer;
begin
  for i := 0 to high(fRegisteredLights) do
    if fRegisteredLights[i].LightSource = TLightSource(Data) then
      fRegisteredLights[i].Free;
end;

constructor TLightManager.Create;
begin
  inherited Create(false);
  fMaxShadowBuffers := ModuleManager.ModRenderer.MaxShadowPasses;
  EventManager.AddCallback('TLightSource.Added', @AddLightSource);
  EventManager.AddCallback('TLightSource.Deleted', @RemoveLightSource);
end;

procedure TLightManager.Free;
var
  i: Integer;
begin
  EventManager.RemoveCallback(@AddLightSource);
  EventManager.RemoveCallback(@RemoveLightSource);
  while length(fRegisteredLights) > 0 do
    fRegisteredLights[0].Free;
  if fSun <> nil then
    fSun.Free;
  Terminate;
  Sync;
  inherited Free;
end;

end.