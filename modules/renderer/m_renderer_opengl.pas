unit m_renderer_opengl;

interface

uses
  Classes, SysUtils, m_renderer_class, DGLOpenGL, g_park, u_math, u_vectors,
  m_renderer_opengl_camera, m_renderer_opengl_terrain, math, m_texmng_class,
  m_shdmng_class, m_renderer_opengl_plugins, u_functions, m_renderer_opengl_frustum,
  m_renderer_opengl_interface, m_renderer_opengl_lights, m_renderer_opengl_sky,
  m_renderer_opengl_classes, u_geometry;

type
  TModuleRendererOpenGL = class(TModuleRendererClass)
    protected
      fFrustum: TFrustum;
      fDistPixel: Array[0..3] of GLFloat;
      fInterface: TRendererOpenGLInterface;
      fLightManager: TLightManager;
      RenderEffectManager: TRenderEffectManager;
      ResX, ResY: Integer;
      fDistTexture: TTexture;
      fSunShadowOpenAngle: Single;
    public
      fShadowDelay: Single;
      OS, OC: TVector3D;
      CR, CG, CB: Boolean;
      RCamera: TRCamera;
      RTerrain: TRTerrain;
      RSky: TRSky;
      property Frustum: TFrustum read fFrustum;
      property RenderInterface: TRendererOpenGLInterface read fInterface;
      property DistTexture: TTexture read fDistTexture;
      procedure PostInit;
      procedure Unload;
      procedure RenderScene;
      procedure CheckModConf;
      procedure RenderShadows;
      procedure RenderParts;
      procedure Render(EyeMode: Single = 0; EyeFocus: Single = 10);
      constructor Create;
      destructor Free;
    end;

const
  SHADOW_UPDATE_TIME = 100;

implementation

uses
  m_varlist, u_events, main;

procedure TModuleRendererOpenGL.PostInit;
var
  s: AString;
  i: INteger;
begin
  fLightManager := TLightManager.Create;
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
  RTerrain.Unload;
  RTerrain.Free;
  RCamera.Free;
  fLightManager.Free;
end;

procedure TModuleRendererOpenGL.RenderParts;
begin
  RSky.Render('', nil, nil);
  RTerrain.Render('', nil, nil);
// Does NOT work yet:
//   EventManager.CallEvent('TPark.RenderParts', nil, nil);
  fInterface.Options.Items['all:renderpass'] := IntToStr(StrToInt(fInterface.Options.Items['all:renderpass']) + 1);
end;

procedure TModuleRendererOpenGL.Render(EyeMode: Single = 0; EyeFocus: Single = 10);
const
  ClipPlane: Array[0..3] of GLDouble = (0, -1, 0, 0);
var
  i: Integer;
begin
  fInterface.Options.Items['all:above'] := '0';
  fInterface.Options.Items['all:below'] := '256';
  glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
  glEnable(GL_CULL_FACE);
  if fInterface.Options.Items['all:polygonmode'] = 'wireframe' then
    glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
  glMatrixMode(GL_MODELVIEW);
  glRotatef(RadToDeg(arctan(EyeMode / EyeFocus)), 0, 1, 0);
  glTranslatef(EyeMode, 0, 0);
  if fInterface.Options.Items['all:applyrotation'] <> 'off' then
    RCamera.ApplyRotation(Vector(1, 1, 1));
  if fInterface.Options.Items['all:applytranslation'] <> 'off' then
    RCamera.ApplyTransformation(Vector(1, 1, 1));
  fFrustum.Calculate;

  glClear(GL_DEPTH_BUFFER_BIT);
  glDisable(GL_BLEND);
  glColor4f(1, 1, 1, 1);

  fInterface.PushOptions;
  glPushMatrix;
    fInterface.Options.Items['terrain:autoplants'] := 'off';
    fInterface.Options.Items['all:transparent'] := 'off';
    fInterface.Options.Items['shader:mode'] := 'transform:depth';
    fInterface.Options.Items['sky:rendering'] := 'off';

    RTerrain.RenderWaterSurfaces;
    glClear(GL_DEPTH_BUFFER_BIT);
    RenderParts;
    RTerrain.CheckWaterLayerVisibility;
  glPopMatrix;
  fInterface.PopOptions;
  if EyeMode = 0 then
    begin
    fDistTexture.Bind;
    glCopyTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 0, 0, ResX, ResY, 0);
    fDistTexture.UnBind;
    glReadPixels(ModuleManager.ModInputHandler.MouseX, ResY - ModuleManager.ModInputHandler.MouseY, 1, 1, GL_RGBA, GL_FLOAT, @fDistPixel[0]);
    fMouseDistance := 256 * fDistPixel[0] + fDistPixel[1];
    if fMouseDistance = 0 then
      fMouseDistance := 257;
    end;
  if EyeFocus < 0 then
    exit;
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
  fInterface.PushOptions;
  for i := 0 to high(RTerrain.fWaterLayerFBOs) do
    begin
    if RTerrain.fWaterLayerFBOs[i].Query.Result = 0 then
      continue;

    glEnable(GL_CLIP_PLANE0);

    fInterface.Options.Items['all:above'] := FloatToStr(RTerrain.fWaterLayerFBOs[i].Height);
    fInterface.Options.Items['all:below'] := '256';
    RTerrain.fWaterLayerFBOs[i].ReflectionFBO.Bind;
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
    glPushMatrix;
    glTranslatef(0, RTerrain.fWaterLayerFBOs[i].Height, 0);
    glClipPlane(GL_CLIP_PLANE0, @ClipPlane[0]);
    glScalef(1, -1, 1);
    glTranslatef(0, -RTerrain.fWaterLayerFBOs[i].Height, 0);
    fFrustum.Calculate;
    glFrontFace(GL_CW);
    RenderParts;
    glFrontFace(GL_CCW);
    glPopMatrix;
    RTerrain.fWaterLayerFBOs[i].ReflectionFBO.Unbind;

    fInterface.Options.Items['all:above'] := FloatToStr(RTerrain.fWaterLayerFBOs[i].Height - 10);
    fInterface.Options.Items['all:below'] := FloatToStr(RTerrain.fWaterLayerFBOs[i].Height);
    RTerrain.fWaterLayerFBOs[i].RefractionFBO.Bind;
    glPushMatrix;
    glTranslatef(0, RTerrain.fWaterLayerFBOs[i].Height, 0);
    glClipPlane(GL_CLIP_PLANE0, @ClipPlane[0]);
    glPopMatrix;
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
    fFrustum.Calculate;
    RenderParts;
    glColorMask(false, false, false, true);
    glDisable(GL_BLEND);
    glClear(GL_DEPTH_BUFFER_BIT);
    fInterface.PushOptions;
      fInterface.Options.Items['terrain:autoplants'] := 'off';
      fInterface.Options.Items['all:transparent'] := 'off';
      fInterface.Options.Items['shader:mode'] := 'transform:depth';
      fInterface.Options.Items['sky:rendering'] := 'off';
      RenderParts;
    fInterface.PopOptions;
    glColorMask(CR, CG, CB, true);
    RTerrain.fWaterLayerFBOs[i].RefractionFBO.Unbind;
    glDisable(GL_CLIP_PLANE0);
    end;
  fInterface.PopOptions;

  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
  RTerrain.RenderWaterSurfaces;

  fInterface.Options.Items['all:above'] := '0';
  fInterface.Options.Items['all:below'] := '256';
  RenderParts;
end;

procedure TModuleRendererOpenGL.RenderShadows;
begin
  with ModuleManager.ModRenderer.RSky.Sun.Position do
    OS := Vector(X, Y, Z);
  OC := ModuleManager.ModCamera.ActiveCamera.Position;
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  gluPerspective(fSunShadowOpenAngle, 1, 0.5, 20000);
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  gluLookAt(OS.X, OS.Y, OS.Z,
            Round(OC.X), Round(OC.Y), Round(OC.Z),
            0, 1, 0);
  fFrustum.Calculate;
  glLoadIdentity;

  fInterface.PushOptions;
  ModuleManager.ModRenderer.RSky.Sun.ShadowMap.Bind;
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
  glMatrixMode(GL_TEXTURE);
  glLoadIdentity;
  gluPerspective(fSunShadowOpenAngle, 1, 0.5, 20000);
  gluLookAt(OS.X, OS.Y, OS.Z,
            Round(OC.X), Round(OC.Y), Round(OC.Z),
            0, 1, 0);
  fInterface.Options.Items['shader:mode'] := 'sunshadow:sunshadow';
  fInterface.Options.Items['terrain:autoplants'] := 'off';
  fInterface.Options.Items['sky:rendering'] := 'off';
  RenderParts;

  ModuleManager.ModRenderer.RSky.Sun.ShadowMap.UnBind;
  fInterface.PopOptions;
end;

procedure TModuleRendererOpenGL.RenderScene;
var
  i: Integer;

  procedure GetSelectionRay;
  var
    pmatrix: TMatrix;
    MX, MY: Single;
    VecToFront, VecLeft, VecUp: TVector3d;
  begin
    fSelectionStart := ModuleManager.ModCamera.ActiveCamera.Position;

    glGetFloatv(GL_PROJECTION_MATRIX, @pmatrix[0]);

    MX := 2 * (ModuleManager.ModInputHandler.MouseX / ResX) - 1;
    MY := -2 * (ModuleManager.ModInputHandler.MouseY / ResY) + 1;

    with ModuleManager.ModCamera do
      VecToFront := Normalize(Vector(Sin(DegToRad(ActiveCamera.Rotation.Y)) * Cos(DegToRad(ActiveCamera.Rotation.X)),
                                    -Sin(DegToRad(ActiveCamera.Rotation.X)),
                                    -Cos(DegToRad(ActiveCamera.Rotation.Y)) * Cos(DegToRad(ActiveCamera.Rotation.X))));
    VecLeft := Normal(VecToFront, Vector(0, 1, 0));
    VecUp := Normal(VecLeft, VecToFront);
    fSelectionRay := normalize(VecToFront + VecUp * (MY / pMatrix[5]) + VecLeft * (MX / pMatrix[0]));
  end;
begin
  CR := true;
  CG := true;
  CB := true;

  fInterface.Options.Items['all:renderpass'] := '0';
  fShadowDelay := fShadowDelay + FPSDisplay.MS;

  // Preparation
  RSky.Advance;
  RSky.CameraLight.Position.X := ModuleManager.ModCamera.ActiveCamera.Position.X;
  RSky.CameraLight.Position.Y := ModuleManager.ModCamera.ActiveCamera.Position.Y + 5;
  RSky.CameraLight.Position.Z := ModuleManager.ModCamera.ActiveCamera.Position.Z;
  RSky.CameraLight.Position.W := 10;
  RSky.CameraLight.Color := Vector(1, 1, 1, 1);
//   RSky.CameraLight.Bind(1);

  // Rendering
  fInterface.Options.Items['shader:mode'] := 'normal:normal';
  fInterface.Options.Items['all:frustumcull'] := 'on';

  glEnable(GL_DEPTH_TEST);
  glDepthMask(true);

  glDisable(GL_BLEND);

  glMatrixMode(GL_TEXTURE);
  glLoadIdentity;
  gluPerspective(fSunShadowOpenAngle, 1, 0.5, 20000);
  gluLookAt(OS.X, OS.Y, OS.Z,
            Round(OC.X), Round(OC.Y), Round(OC.Z),
            0, 1, 0);

  if (fShadowDelay >= SHADOW_UPDATE_TIME) and (fInterface.Options.Items['shadows:enabled'] = 'on') then
    RenderShadows;
  fShadowDelay := SHADOW_UPDATE_TIME * fpart(fShadowDelay / SHADOW_UPDATE_TIME);

  glEnable(GL_BLEND);

  glMatrixMode(GL_PROJECTION);
  ModuleManager.ModGLMng.SetUp3DMatrix;
  GetSelectionRay;
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;

  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);

  if fInterface.Options.Items['shadows:enabled'] = 'on' then
    ModuleManager.ModRenderer.RSky.Sun.ShadowMap.Textures[0].Bind(7);

  EventManager.CallEvent('TModuleRenderer.Render', nil, nil);

//   glUseProgram(0);
//   glDisable(GL_TEXTURE_2D);
//   glDisable(GL_CULL_FACE);
//
//   glColor4f(1, 1, 1, 1);
//   glBegin(GL_QUADS);
//     glVertex3f(-10, 0, -10);
//     glVertex3f( 10, 0, -10);
//     glVertex3f( 10, 0,  10);
//     glVertex3f(-10, 0,  10);
//   glEnd;
//
//   glEnable(GL_TEXTURE_2D);

  glMatrixMode(GL_TEXTURE);
  glLoadIdentity;
  glMatrixMode(GL_MODELVIEW);

  glDisable(GL_CULL_FACE);

  EventManager.CallEvent('TModuleRenderer.PostRender', nil, nil);
end;

procedure TModuleRendererOpenGL.CheckModConf;
begin
  if GetConfVal('used') = '' then
    begin
    SetConfVal('used', '1');
    SetConfVal('effects', IntToStr(RE_NORMAL) + ',' + IntToStr(RE_2D_FOCUS) + ',' + IntToStr(RE_BLOOM));
    SetConfVal('terrain:autoplants', 'on');
    SetConfVal('terrain:hd', 'on');
    SetConfVal('shadows:enabled', 'on');
    SetConfVal('shadows:texsize', '2048');
    end;
  fInterface.Options.Items['terrain:autoplants'] := GetConfVal('terrain:autoplants');
  fInterface.Options.Items['terrain:hd'] := GetConfVal('terrain:hd');
  fInterface.Options.Items['shadows:enabled'] := GetConfVal('shadows:enabled');
  fInterface.Options.Items['shadows:texsize'] := GetConfVal('shadows:texsize');
end;

constructor TModuleRendererOpenGL.Create;
begin
  fSunShadowOpenAngle := 1;
  fModName := 'RendererGL';
  fModType := 'Renderer';
  ModuleManager.ModGLContext.GetResolution(ResX, ResY);
  fInterface := TRendererOpenGLInterface.Create;
  fFrustum := TFrustum.Create;
  SetConfVal('all:polygonmode', 'fill');
  fDistTexture := TTexture.Create;
  fDistTexture.CreateNew(ResX, ResY, GL_RGBA);
  fDistTexture.SetClamp(GL_CLAMP, GL_CLAMP);
  fDistTexture.SetFilter(GL_NEAREST, GL_NEAREST);
end;

destructor TModuleRendererOpenGL.Free;
begin
  fDistTexture.Free;
  fFrustum.Free;
  fInterface.Free;
end;

end.