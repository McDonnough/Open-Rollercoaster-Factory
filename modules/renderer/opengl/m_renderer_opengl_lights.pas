unit m_renderer_opengl_lights;

interface

uses
  SysUtils, Classes, DGLOpenGL, m_renderer_opengl_interface, u_vectors, u_math, m_renderer_opengl_classes;

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
      procedure Bind(I: Integer);
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
  u_events;

procedure TLight.Bind(I: Integer);
begin
  glEnable(GL_LIGHT0 + i);
  glLightfv(GL_LIGHT0 + i, GL_DIFFUSE,  @Color.X);
  glLightfv(GL_LIGHT0 + i, GL_POSITION, @Position.X);
end;

constructor TLight.Create;
begin
  Color := Vector(1, 1, 1, 1);
  Position := Vector(0, 0, 0, 0);
  fShadowMap := TFBO.Create(256, 128, true); // Parabolic map
  fShadowMap.AddTexture(GL_RGBA16F_ARB, GL_LINEAR, GL_LINEAR);
  fShadowMap.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);
  fShadowMap.Textures[0].Unbind;
  EventManager.CallEvent('TLightManager.AddLight', self, @fInternalID);
end;

destructor TLight.Free;
begin
  EventManager.CallEvent('TLightManager.RemoveLight', @fInternalID, nil);
  fShadowMap.Free;
end;


constructor TSun.Create;
begin
  Color := Vector(1, 1, 1, 1);
  Position := Vector(-1000, 0, 0, 0);
  fShadowMap := TFBO.Create(2048, 2048, true); // Flat map
  fShadowMap.AddTexture(GL_RGBA32F_ARB, GL_LINEAR, GL_LINEAR);
  fShadowMap.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);
  fShadowMap.Textures[0].Unbind;
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
  fShadowMap.Free;
end;



procedure TLightManager.AddLight(Event: String; Data, Result: Pointer);
begin
  setLength(fRegisteredLights, length(fRegisteredLights) + 1);
  fRegisteredLights[high(fRegisteredLights)] := TLight(Data);
  Integer(Result^) := High(fRegisteredLights);
end;

procedure TLightManager.RemoveLight(Event: String; Data, Result: Pointer);
begin
  fRegisteredLights[Integer(Data^)] := nil;
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

destructor TLightManager.Free;
begin
  EventManager.RemoveCallback('TLightManager.AddLight');
  EventManager.RemoveCallback('TLightManager.RemoveLight');
  Waiting := False;
  Terminate;
  sleep(100);
end;

end.