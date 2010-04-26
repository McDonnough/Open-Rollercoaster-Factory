unit m_renderer_opengl;

interface

uses
  Classes, SysUtils, m_renderer_class, DGLOpenGL, g_park, u_math, u_vectors,
  m_renderer_opengl_camera, m_renderer_opengl_terrain, math, m_texmng_class,
  m_shdmng_class, m_renderer_opengl_plugins, u_functions, m_renderer_opengl_frustum,
  m_renderer_opengl_interface, m_renderer_opengl_lights, m_renderer_opengl_sky;

type
  TModuleRendererOpenGL = class(TModuleRendererClass)
    protected
      fFrustum: TFrustum;
      fInterface: TRendererOpenGLInterface;
      RCamera: TRCamera;
      RTerrain: TRTerrain;
      RSky: TRSky;
      RenderEffectManager: TRenderEffectManager;
    public
      property Frustum: TFrustum read fFrustum;
      property RenderInterface: TRendererOpenGLInterface read fInterface;
      procedure PostInit;
      procedure Unload;
      procedure RenderScene;
      procedure CheckModConf;
      procedure Render(EyeMode: Single = 0; EyeFocus: Single = 10);
      constructor Create;
      destructor Free;
    end;

implementation

uses
  m_varlist, u_events;

procedure TModuleRendererOpenGL.PostInit;
var
  s: AString;
  i: INteger;
begin
  RCamera := TRCamera.Create;
  RTerrain := TRTerrain.Create;
  RSky := TRSky.Create;
  RenderEffectManager := TRenderEffectManager.Create;
  s := Explode(',', GetConfVal('effects'));
  for i := 0 to high(s) do
    RenderEffectManager.LoadEffect(StrToInt(S[i]));
end;

procedure TModuleRendererOpenGL.Unload;
begin
  RenderEffectManager.Free;
  RSky.Free;
  RTerrain.Free;
  RCamera.Free;
end;

procedure TModuleRendererOpenGL.Render(EyeMode: Single = 0; EyeFocus: Single = 10);
begin
  glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
  glEnable(GL_CULL_FACE);
  if fInterface.Options.Items['all:polygonmode'] = 'wireframe' then
    glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
  glClear(GL_DEPTH_BUFFER_BIT);
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  glRotatef(RadToDeg(arctan(EyeMode / EyeFocus)), 0, 1, 0);
  glTranslatef(EyeMode, 0, 0);
  RCamera.ApplyRotation(Vector(1, 1, 1));
  RCamera.ApplyTransformation(Vector(1, 1, 1));
  fFrustum.Calculate;

  // Start rendering
  RSky.Render;
  RTerrain.Render;
  glDisable(GL_CULL_FACE);
end;

procedure TModuleRendererOpenGL.RenderScene;
var
  ResX, ResY, i: Integer;
begin
  // Preparation
  RSky.Advance;

  // Rendering
  fInterface.Options.Items['shader:mode'] := 'normal:normal';
  fInterface.Options.Items['all:frustumcull'] := 'on';
  ModuleManager.ModGLContext.GetResolution(ResX, ResY);

  glMatrixMode(GL_PROJECTION);
  ModuleManager.ModGLMng.SetUp3DMatrix;
  glMatrixMode(GL_MODELVIEW);

  glEnable(GL_DEPTH_TEST);
  glDepthMask(true);

  glEnable(GL_BLEND);

  EventManager.CallEvent('TModuleRenderer.Render', nil, nil);
  EventManager.CallEvent('TModuleRenderer.PostRender', nil, nil);
end;

procedure TModuleRendererOpenGL.CheckModConf;
begin
  if GetConfVal('used') = '' then
    begin
    SetConfVal('used', '1');
    SetConfVal('effects', IntToStr(RE_NORMAL) + ',' + IntToStr(RE_2D_FOCUS) + ',' + IntToStr(RE_BLOOM) + ',' + IntToStr(RE_MOTIONBLUR));
    SetConfVal('terrain:autoplants', 'on');
    SetConfVal('terrain:hd', 'on');
    end;
  fInterface.Options.Items['terrain:autoplants'] := GetConfVal('terrain:autoplants');
  fInterface.Options.Items['terrain:hd'] := GetConfVal('terrain:hd');
end;

constructor TModuleRendererOpenGL.Create;
begin
  fModName := 'RendererGL';
  fModType := 'Renderer';
  fInterface := TRendererOpenGLInterface.Create;
  fFrustum := TFrustum.Create;

  SetConfVal('all:polygonmode', 'fill');
end;

destructor TModuleRendererOpenGL.Free;
begin
  fFrustum.Free;
  fInterface.Free;
end;

end.