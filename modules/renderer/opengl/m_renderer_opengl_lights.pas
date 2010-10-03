unit m_renderer_opengl_lights;

interface

uses
  SysUtils, Classes, DGLOpenGL, m_renderer_opengl_interface, u_vectors, u_math, m_renderer_opengl_classes, m_renderer_opengl_frustum;

type
  TLight = class
    protected
      fShadowMap: TFBO;
      fInternalID: Integer;
    private

    public
      Position: TVector4D;
      Color: TVector4D;
      property ShadowMap: TFBO read fShadowMap;
      function Strength(Distance: Single): Single;
      function IsVisible(A: TFrustum): Boolean;
      function MaxLightingEffect: Single;
      procedure CreateShadowMap;
      procedure Bind(I: Integer);
      procedure Unbind(I: Integer);
      constructor Create;
      destructor Free;
    end;

  TLightManager = class(TThread)
    protected
      fRegisteredLights: Array of TLight;
      procedure AddLight(Event: String; Data, Result: Pointer);
      procedure RemoveLight(Event: String; Data, Result: Pointer);
      procedure Execute; override;
    public
      Waiting: Boolean;
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

implementation

uses
  u_events, u_functions, m_varlist, math;

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
  Result := A.IsSphereWithin(Position.X, Position.Y, Position.Z, MaxLightingEffect);
end;

procedure TLight.CreateShadowMap;
begin
  ModuleManager.ModRenderer.MaxRenderDistance := MaxLightingEffect;
  ModuleManager.ModRenderer.DistanceMeasuringPoint := Vector3D(Position);
  fShadowMap.Bind;
  glClear(GL_DEPTH_BUFFER_BIT or GL_COLOR_BUFFER_BIT);
  glDisable(GL_BLEND);
  glDisable(GL_ALPHA_TEST);

  // FRONT
  glViewport(0, 0, fShadowMap.Width div 3, fShadowMap.Height div 2);

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  Bind(1);
  glTranslatef(-Position.X, -Position.Y, -Position.Z);
  ModuleManager.ModRenderer.Frustum.Calculate;

  ModuleManager.ModRenderer.RenderParts(true, true);

  // BACK
  glViewport(2 * fShadowMap.Width div 3, 0, fShadowMap.Width div 3, fShadowMap.Height div 2);

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  glRotatef(180, 0, 1, 0);
  glTranslatef(-Position.X, -Position.Y, -Position.Z);
  ModuleManager.ModRenderer.Frustum.Calculate;

  ModuleManager.ModRenderer.RenderParts(true, true);

  // LEFT
  glViewport(0, fShadowMap.Height div 2, fShadowMap.Width div 3, fShadowMap.Height div 2);

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  glRotatef(270, 0, 1, 0);
  glTranslatef(-Position.X, -Position.Y, -Position.Z);
  ModuleManager.ModRenderer.Frustum.Calculate;

  ModuleManager.ModRenderer.RenderParts(true, true);

  // RIGHT
  glViewport(fShadowMap.Width div 3, 0, fShadowMap.Width div 3, fShadowMap.Height div 2);

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  glRotatef(90, 0, 1, 0);
  glTranslatef(-Position.X, -Position.Y, -Position.Z);
  ModuleManager.ModRenderer.Frustum.Calculate;

  ModuleManager.ModRenderer.RenderParts(true, true);

  // DOWN
  glViewport(fShadowMap.Width div 3, fShadowMap.Height div 2, fShadowMap.Width div 3, fShadowMap.Height div 2);

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  glRotatef(90, 1, 0, 0);
  glTranslatef(-Position.X, -Position.Y, -Position.Z);
  ModuleManager.ModRenderer.Frustum.Calculate;

  ModuleManager.ModRenderer.RenderParts(true, true);

  // UP
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
end;

procedure TLight.Unbind(I: Integer);
var
  Null: TVector4D;
begin
  Null := Vector(0, 0, 0, 0);
  glEnable(GL_LIGHT0 + i);
  glLightfv(GL_LIGHT0 + i, GL_DIFFUSE,  @Null.X);
  glLightfv(GL_LIGHT0 + i, GL_POSITION, @Null.X);
end;

constructor TLight.Create;
begin
  Color := Vector(1, 1, 1, 1);
  Position := Vector(0, 0, 0, 0);
  if fInterface.Options.Items['shadows:enabled'] = 'on'  then
    begin
    fShadowMap := TFBO.Create(768, 256, true); // Cube map
    fShadowMap.AddTexture(GL_RGBA16F_ARB, GL_LINEAR, GL_LINEAR);
    fShadowMap.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);
    fShadowMap.Textures[0].Unbind;
    end;
  EventManager.CallEvent('TLightManager.AddLight', self, @fInternalID);
end;

destructor TLight.Free;
begin
  EventManager.CallEvent('TLightManager.RemoveLight', @fInternalID, nil);
  if fInterface.Options.Items['shadows:enabled'] = 'on' then
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
      fRegisteredLights[i] := fRegisteredLights[high(fRegisteredLights)];
      SetLength(fRegisteredLights, length(fRegisteredLights) - 1);
      end;
end;

procedure TLightManager.Execute;
begin
  while not Terminated do
    begin
    Waiting := true;
    while Waiting do
      sleep(10);
    end;
end;

constructor TLightManager.Create;
begin
  inherited Create(false);
  Waiting := false;
  EventManager.AddCallback('TLightManager.AddLight', @self.AddLight);
  EventManager.AddCallback('TLightManager.RemoveLight', @self.RemoveLight);
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
  for i := 0 to high(fRegisteredLights) do
    if fRegisteredLights[i].IsVisible(X) then
      fRegisteredLights[i].CreateShadowMap;
  fInterface.PopOptions;
  glMatrixMode(GL_MODELVIEW);
  glPopMatrix;
  glMatrixMode(GL_PROJECTION);
  glPopMatrix;
  glMatrixMode(GL_MODELVIEW);
  X.Free;
end;

destructor TLightManager.Free;
begin
  EventManager.RemoveCallback('TLightManager.AddLight');
  EventManager.RemoveCallback('TLightManager.RemoveLight');
  Waiting := False;
  Terminate;
  sleep(100);
end;

end.