unit m_renderer_opengl_lights;

interface

uses
  SysUtils, Classes, DGLOpenGL, m_renderer_opengl_interface, u_vectors, u_math, m_renderer_opengl_classes, m_renderer_opengl_frustum,
  m_texmng_class, m_shdmng_class;

type
  TLight = class
    protected
      fShadowMap: TFBO;
      fDynamic: Boolean;
      fOldPosition: TVector4D;
      fInternalID: Integer;
    private
      fShadowRefreshOffset: Integer;
    public
      Position: TVector4D;
      Color: TVector4D;
      property Dynamic: Boolean read fDynamic;
      property ShadowMap: TFBO read fShadowMap;
      function Strength(Distance: Single): Single;
      function IsVisible(A: TFrustum): Boolean;
      function MaxLightingEffect: Single;
      procedure CreateShadowMap;
      procedure Bind(I: Integer);
      procedure Unbind(I: Integer);
      constructor Create(Hints: QWord = 0);
      destructor Free;
    end;

  TMeshLightCombination = record
    Mesh: Pointer;
    Lights: Array[0..6] of TLight;
    LightStrengthValues: Array[0..6] of Single;
    end;

  TTerrainblockLightCombination = record
    Lights: Array[0..6] of TLight;
    LightStrengthValues: Array[0..6] of Single;
    end;

  TLightManager = class(TThread)
    protected
      fRegisteredLights: Array of TLight;
      fFrames: Integer;
      fWorking, fCanWork: Boolean;
      fNoLight: TLight;
      fMeshLights: Array of TMeshLightCombination;
      fStrongestTerrainLights: Array of Array of TTerrainblockLightCombination;
      procedure AddLight(Event: String; Data, Result: Pointer);
      procedure RemoveLight(Event: String; Data, Result: Pointer);
      procedure AddMesh(Event: String; Data, Result: Pointer);
      procedure DeleteMesh(Event: String; Data, Result: Pointer);
      procedure TerrainResized(Event: String; Data, Result: Pointer);
      procedure Execute; override;
    public
      property NoLight: TLight read fNoLight;
      property Working: Boolean read fWorking write fCanWork;
      procedure StartBinding;
      procedure EndBinding;
      procedure Sync;
      procedure AssignLightsToObjects;
      procedure RenderShadows;
      constructor Create;
      destructor Free;
    end;

  TSun = class
    protected
      fShadowMap: TFBO;
    public
      Position: TVector4D;
      AmbientColor, Color: TVector4D;
      property ShadowMap: TFBO read fShadowMap;
      procedure Bind(I: Integer);
      constructor Create;
      destructor Free;
    end;

const
  LIGHT_HINT_NO_SHADOW = 1;

implementation

uses
  u_events, u_functions, m_varlist, math, m_renderer_opengl_objects, g_park;

function TLight.Strength(Distance: Single): Single;
begin
  Result := VecLengthNoRoot(Vector3D(Color)) * Position.W * Color.W / Max(0.01, Distance);
end;

function TLight.MaxLightingEffect: Single;
begin
  Result := Position.W * Color.W / 0.1;
end;

function TLight.IsVisible(A: TFrustum): Boolean;
begin
  Result := (VecLengthNoRoot(Vector3D(Position) - ModuleManager.ModCamera.ActiveCamera.Position) <= MaxLightingEffect * MaxLightingEffect)
         or (A.IsSphereWithin(Position.X, Position.Y, Position.Z, MaxLightingEffect));
end;

procedure TLight.CreateShadowMap;
begin
  fDynamic := VecLengthNoRoot(fOldPosition - Position) > 0.0001;
  fOldPosition := Position;
  if not ((fShadowRefreshOffset = ModuleManager.ModRenderer.LightManager.fFrames mod 4) or (Dynamic)) then
    exit;
  ModuleManager.ModRenderer.MaxRenderDistance := MaxLightingEffect;
  ModuleManager.ModRenderer.DistanceMeasuringPoint := Vector3D(Position);
  fShadowMap.Bind;
  glClear(GL_DEPTH_BUFFER_BIT or GL_COLOR_BUFFER_BIT);

  // FRONT
  glDisable(GL_BLEND);
  glDisable(GL_ALPHA_TEST);
  glViewport(0, 0, fShadowMap.Width div 3, fShadowMap.Height div 2);

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  Bind(1);
  glTranslatef(-Position.X, -Position.Y, -Position.Z);
  ModuleManager.ModRenderer.Frustum.Calculate;

  ModuleManager.ModRenderer.RenderParts(true, true);

  // BACK
  glDisable(GL_BLEND);
  glDisable(GL_ALPHA_TEST);
  glViewport(2 * fShadowMap.Width div 3, 0, fShadowMap.Width div 3, fShadowMap.Height div 2);

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  glRotatef(180, 0, 1, 0);
  glTranslatef(-Position.X, -Position.Y, -Position.Z);
  ModuleManager.ModRenderer.Frustum.Calculate;

  ModuleManager.ModRenderer.RenderParts(true, true);

  // LEFT
  glDisable(GL_BLEND);
  glDisable(GL_ALPHA_TEST);
  glViewport(0, fShadowMap.Height div 2, fShadowMap.Width div 3, fShadowMap.Height div 2);

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  glRotatef(270, 0, 1, 0);
  glTranslatef(-Position.X, -Position.Y, -Position.Z);
  ModuleManager.ModRenderer.Frustum.Calculate;

  ModuleManager.ModRenderer.RenderParts(true, true);

  // RIGHT
  glDisable(GL_BLEND);
  glDisable(GL_ALPHA_TEST);
  glViewport(fShadowMap.Width div 3, 0, fShadowMap.Width div 3, fShadowMap.Height div 2);

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  glRotatef(90, 0, 1, 0);
  glTranslatef(-Position.X, -Position.Y, -Position.Z);
  ModuleManager.ModRenderer.Frustum.Calculate;

  ModuleManager.ModRenderer.RenderParts(true, true);

  // DOWN
  glDisable(GL_BLEND);
  glDisable(GL_ALPHA_TEST);
  glViewport(fShadowMap.Width div 3, fShadowMap.Height div 2, fShadowMap.Width div 3, fShadowMap.Height div 2);

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  glRotatef(90, 1, 0, 0);
  glTranslatef(-Position.X, -Position.Y, -Position.Z);
  ModuleManager.ModRenderer.Frustum.Calculate;

  ModuleManager.ModRenderer.RenderParts(true, true);

  // UP
  glDisable(GL_BLEND);
  glDisable(GL_ALPHA_TEST);
  glViewport(2 * fShadowMap.Width div 3, fShadowMap.Height div 2, fShadowMap.Width div 3, fShadowMap.Height div 2);

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  glRotatef(270, 1, 0, 0);
  glTranslatef(-Position.X, -Position.Y, -Position.Z);
  ModuleManager.ModRenderer.Frustum.Calculate;

  ModuleManager.ModRenderer.RenderParts(true, true);

  fShadowMap.UnBind;
  Unbind(1);
end;

procedure TLight.Bind(I: Integer);
begin
  glEnable(GL_LIGHT0 + i);
  glLightfv(GL_LIGHT0 + i, GL_DIFFUSE,  @Color.X);
  glLightfv(GL_LIGHT0 + i, GL_POSITION, @Position.X);
  if (fShadowMap <> nil) and (I <= 3) then
    fShadowMap.Textures[0].Bind(3 + I)
  else if (I <= 3) then
    begin
    ModuleManager.ModTexMng.ActivateTexUnit(3 + I);
    ModuleManager.ModTexMng.BindTexture(-1);
    end;
end;

procedure TLight.Unbind(I: Integer);
var
  Null: TVector4D;
begin
  Null := Vector(0, 0, 0, 1);
  glEnable(GL_LIGHT0 + i);
  glLightfv(GL_LIGHT0 + i, GL_DIFFUSE,  @Null.X);
  glLightfv(GL_LIGHT0 + i, GL_POSITION, @Null.X);
  if (I <= 3) then
    begin
    ModuleManager.ModTexMng.ActivateTexUnit(3 + I);
    ModuleManager.ModTexMng.BindTexture(-1);
    end;
  ModuleManager.ModTexMng.ActivateTexUnit(0);
end;

constructor TLight.Create(Hints: QWord = 0);
begin
  Color := Vector(1, 1, 1, 1);
  Position := Vector(0, 0, 0, 0);
  fShadowMap := nil;
  if (fInterface.Options.Items['shadows:enabled'] = 'on') and (Hints and LIGHT_HINT_NO_SHADOW = 0) then
    begin
    fShadowMap := TFBO.Create(768, 256, true); // Cube map
    fShadowMap.AddTexture(GL_RGBA16F_ARB, GL_LINEAR, GL_LINEAR);
    fShadowMap.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);
    fShadowMap.Textures[0].Unbind;
    end;
  EventManager.CallEvent('TLightManager.AddLight', self, @fInternalID);
  fShadowRefreshOffset := Round(3 * Random);
  fDynamic := false;
end;

destructor TLight.Free;
begin
  EventManager.CallEvent('TLightManager.RemoveLight', @fInternalID, nil);
  if fShadowMap <> nil then
    fShadowMap.Free;
end;


constructor TSun.Create;
begin
  Color := Vector(1, 1, 1, 1);
  Position := Vector(-1000, 0, 0, 0);
  if fInterface.Options.Items['shadows:enabled'] = 'on' then
    begin
    fShadowMap := TFBO.Create(StrToIntWD(fInterface.Options.Items['shadows:texsize'], 512), 4 * StrToIntWD(fInterface.Options.Items['shadows:texsize'], 512), true); // Flat map
    fShadowMap.AddTexture(GL_RGBA16F_ARB, GL_LINEAR, GL_LINEAR);
    fShadowMap.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);
    fShadowMap.Textures[0].Unbind;
    end;
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
  if fInterface.Options.Items['shadows:enabled'] = 'on' then
    fShadowMap.Free;
end;



procedure TLightManager.AddLight(Event: String; Data, Result: Pointer);
begin
  Sync;
  setLength(fRegisteredLights, length(fRegisteredLights) + 1);
  fRegisteredLights[high(fRegisteredLights)] := TLight(Data);
end;

procedure TLightManager.RemoveLight(Event: String; Data, Result: Pointer);
var
  i: Integer;
begin
  for i := 0 to high(fRegisteredLights) do
    if Pointer(fRegisteredLights[i]) = Data then
      begin
      Sync;
      fRegisteredLights[i] := fRegisteredLights[high(fRegisteredLights)];
      SetLength(fRegisteredLights, length(fRegisteredLights) - 1);
      end;
end;

procedure TLightManager.Sync;
begin
  while fWorking do
    sleep(1);
end;

procedure TLightManager.AssignLightsToObjects;
var
  i, j, k: Integer;
begin
  for i := 0 to high(fMeshLights) do
    with TManagedMesh(fMeshLights[i].Mesh) do
      for j := 0 to high(fStrongestLights) do
        fStrongestLights[j] := fMeshLights[i].Lights[j];
  for i := 0 to high(fStrongestTerrainLights) do
    for j := 0 to high(fStrongestTerrainLights[i]) do
      for k := 0 to high(fStrongestTerrainLights[i, j].Lights) do
        ModuleManager.ModRenderer.RTerrain.fStrongestLights[i, j, k] := fStrongestTerrainLights[i, j].Lights[k];
end;

procedure TLightManager.StartBinding;
begin
  glPushMatrix;
  glLoadIdentity;
end;

procedure TLightManager.EndBinding;
begin
  glPopMatrix;
end;

procedure TLightManager.Execute;
var
  i, j, k, l, m: Integer;
  BlockPos: TVector3D;
  Dist: Single;
  MeshPos: TVector4D;
begin
  fWorking := false;
  fCanWork := false;
  while not Terminated do
    try
      if fCanWork then
        begin
        fWorking := true;
        fCanWork := false;
        for i := 0 to high(fStrongestTerrainLights) do
          for j := 0 to high(fStrongestTerrainLights[i]) do
            for k := 0 to high(fStrongestTerrainLights[i, j].Lights) do
              begin
              fStrongestTerrainLights[i, j].Lights[k] := nil;
              fStrongestTerrainLights[i, j].LightStrengthValues[k] := 0;
              end;
        for i := 0 to high(fStrongestTerrainLights) do
          for j := 0 to high(fStrongestTerrainLights[i]) do
            begin
            BlockPos := Vector(12.8 + 25.6 * I, ModuleManager.ModRenderer.RTerrain.fAvgHeight[I, J], 12.8 + 25.6 * J);
            for k := 0 to high(fRegisteredLights) do
              begin
              Dist := VecLength(Vector3D(fRegisteredLights[k].Position) - BlockPos);
              for l := 0 to high(fStrongestTerrainLights[i, j].Lights) do
                begin
                if fRegisteredLights[k].Strength(Dist) > fStrongestTerrainLights[i, j].LightStrengthValues[l] then
                  begin
                  for m := high(fStrongestTerrainLights[i, j].Lights) - 1 downto l do
                    begin
                    fStrongestTerrainLights[i, j].Lights[m + 1] := fStrongestTerrainLights[i, j].Lights[m];
                    fStrongestTerrainLights[i, j].LightStrengthValues[m + 1] := fStrongestTerrainLights[i, j].LightStrengthValues[m];
                    end;
                  fStrongestTerrainLights[i, j].Lights[l] := fRegisteredLights[k];
                  fStrongestTerrainLights[i, j].LightStrengthValues[l] := fRegisteredLights[k].Strength(Dist);
                  break;
                  end;
                end;
              end;
            end;
        for i := 0 to high(fMeshLights) do
          begin
          MeshPos := Vector(0, 0, 0, 1) * TManagedMesh(fMeshLights[i].Mesh).fMesh.TransformMatrix;
          for j := 0 to high(fMeshLights[i].Lights) do
            begin
            fMeshLights[i].LightStrengthValues[j] := 0;
            fMeshLights[i].Lights[j] := nil;
            end;
          for j := 1 to high(fRegisteredLights) do
            begin
            Dist := VecLength(Vector3D(MeshPos) - Vector3D(fRegisteredLights[j].Position));
            for k := 0 to high(fMeshLights[i].Lights) do
              begin
              if fRegisteredLights[j].Strength(Dist) > fMeshLights[i].LightStrengthValues[k] then
                begin
                for l := high(fMeshLights[i].Lights) - 1 downto k do
                  begin
                  fMeshLights[i].Lights[l + 1] := fMeshLights[i].Lights[l];
                  fMeshLights[i].LightStrengthValues[l + 1] := fMeshLights[i].LightStrengthValues[l];
                  end;
                fMeshLights[i].Lights[k] := fRegisteredLights[j];
                fMeshLights[i].LightStrengthValues[k] := fRegisteredLights[j].Strength(Dist);
                break;
                end;
              end;
            end;
          end;
        end;
      fWorking := false;
      sleep(1);
    except
      ModuleManager.ModLog.AddError('Exception in Light Manager Thread');
    end;
  writeln('Hint: Terminated light manager thread');
end;

procedure TLightManager.AddMesh(Event: String; Data, Result: Pointer);
var
  i: Integer;
begin
  Sync;
  setLength(fMeshLights, length(fMeshLights) + 1);
  with fMeshLights[high(fMeshLights)] do
    begin
    Mesh := Data;
    for i := 0 to 6 do
      begin
      Lights[i] := nil;
      LightStrengthValues[i] := 0;
      end;
    end;
end;

procedure TLightManager.DeleteMesh(Event: String; Data, Result: Pointer);
var
  i, j: Integer;
begin
  for i := 0 to high(fMeshLights) do
    if fMeshLights[i].Mesh = Data then
      begin
      Sync;
      fMeshLights[i].Mesh := fMeshLights[high(fMeshLights)].Mesh;
      for j := 0 to 6 do
        begin
        fMeshLights[i].Lights[j] := fMeshLights[high(fMeshLights)].Lights[j];
        fMeshLights[i].LightStrengthValues[j] := fMeshLights[high(fMeshLights)].LightStrengthValues[j];
        end;
      SetLength(fMeshLights, length(fMeshLights) - 1);
      exit;
      end;
end;

procedure TLightManager.TerrainResized(Event: String; Data, Result: Pointer);
var
  i, j, k: Integer;
begin
  Sync;
  SetLength(fStrongestTerrainLights, Park.pTerrain.SizeX div 128);
  for i := 0 to high(fStrongestTerrainLights) do
    begin
    SetLength(fStrongestTerrainLights[i], Park.pTerrain.SizeY div 128);
    for j := 0 to high(fStrongestTerrainLights[i]) do
      for k := 0 to high(fStrongestTerrainLights[i, j].Lights) do
        begin
        fStrongestTerrainLights[i, j].Lights[k] := nil;
        fStrongestTerrainLights[i, j].LightStrengthValues[k] := 0;
        end;
    end;
end;

constructor TLightManager.Create;
begin
  inherited Create(false);
  EventManager.AddCallback('TLightManager.AddLight', @AddLight);
  EventManager.AddCallback('TLightManager.RemoveLight', @RemoveLight);
  EventManager.AddCallback('TRObjects.MeshAdded', @AddMesh);
  EventManager.AddCallback('TRObjects.MeshDeleted', @DeleteMesh);
  EventManager.AddCallback('TTerrain.Resize', @TerrainResized);
  fFrames := 0;
  fNoLight := TLight.Create(LIGHT_HINT_NO_SHADOW);
  fNoLight.Position := Vector(0, 0, 0, 1);
  fNoLight.Color := Vector(0, 0, 0, 1);
end;

procedure TLightManager.RenderShadows;
var
  i: Integer;
  X: TFrustum;
begin
  X := TFrustum.Create;
  glMatrixMode(GL_PROJECTION);
  glPushMatrix;
  glLoadIdentity;
  ModuleManager.ModGLMng.SetUp3DMatrix;
  glMatrixMode(GL_MODELVIEW);
  glPushMatrix;
  glLoadIdentity;
  ModuleManager.ModRenderer.RCamera.ApplyRotation(Vector(1, 1, 1));
  ModuleManager.ModRenderer.RCamera.ApplyTransformation(Vector(1, 1, 1));
  X.Calculate;
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  gluPerspective(90, 1, 0.01, 100);
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  fInterface.PushOptions;
  fInterface.Options.Items['shader:mode'] := 'shadow:shadow';
  fInterface.Options.Items['terrain:autoplants'] := 'off';
  fInterface.Options.Items['sky:rendering'] := 'off';
  for i := 1 to high(fRegisteredLights) do
    if (fRegisteredLights[i].IsVisible(X)) and (fRegisteredLights[i].ShadowMap <> nil) then
      fRegisteredLights[i].CreateShadowMap;
  fInterface.PopOptions;
  glMatrixMode(GL_MODELVIEW);
  glPopMatrix;
  glMatrixMode(GL_PROJECTION);
  glPopMatrix;
  glMatrixMode(GL_MODELVIEW);
  X.Free;
  inc(fFrames);
end;

destructor TLightManager.Free;
begin
  Sync;
  EventManager.RemoveCallback(@TerrainResized);
  EventManager.RemoveCallback(@AddLight);
  EventManager.RemoveCallback(@RemoveLight);
  EventManager.RemoveCallback(@AddMesh);
  EventManager.RemoveCallback(@DeleteMesh);
  fNoLight.Free;
  Terminate;
  sleep(100);
end;

end.