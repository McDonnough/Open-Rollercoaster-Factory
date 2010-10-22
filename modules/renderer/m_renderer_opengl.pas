unit m_renderer_opengl;

interface

uses
  Classes, SysUtils, m_renderer_class, DGLOpenGL, g_park, u_math, u_vectors,
  m_renderer_opengl_camera, m_renderer_opengl_terrain, math, m_texmng_class,
  m_shdmng_class, m_renderer_opengl_plugins, u_functions, m_renderer_opengl_frustum,
  m_renderer_opengl_interface, m_renderer_opengl_lights, m_renderer_opengl_sky,
  m_renderer_opengl_classes, m_renderer_opengl_objects, u_scene;

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
//       fTestVBO: TObjectVBO;
    public
      ShadowQuad: Array[0..3] of TVector3D;
      VecToFront, OS, OC: TVector3D;
      CR, CG, CB: Boolean;
      RCamera: TRCamera;
      RTerrain: TRTerrain;
      MaxRenderDistance: Single;
      DistanceMeasuringPoint: TVector3D;
      RObjects: TRObjects;
      RSky: TRSky;
      MinRenderHeight: Single;
      DynamicLODBias, StaticLODBias: Integer;
      property Frustum: TFrustum read fFrustum;
      property RenderInterface: TRendererOpenGLInterface read fInterface;
      property DistTexture: TTexture read fDistTexture;
      property LightManager: TLightManager read fLightManager;
      procedure PostInit;
      procedure Unload;
      procedure RenderScene;
      procedure CheckModConf;
      procedure RenderShadows;
      procedure Render(EyeMode: Single = 0; EyeFocus: Single = 10);
      procedure RenderParts(Solid, Transparent: Boolean);
      function GetRay(MX, MY: Single): TVector3D;
      function GetNegRay(MX, MY: Single): TVector3D;
      function mapPixelToQuad(P: TVector2D): TVector2D;
      function ProjectToBottom(A: TVector3D): TVector2D;
      constructor Create;
      destructor Free;
    end;

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
  RObjects := TRObjects.Create;
  RSky := TRSky.Create;
  RenderEffectManager := TRenderEffectManager.Create;
  s := Explode(',', GetConfVal('effects'));
  for i := 0 to high(s) do
    RenderEffectManager.LoadEffect(StrToInt(S[i]));
  MinRenderHeight := 0;
end;

procedure TModuleRendererOpenGL.Unload;
begin
  RenderEffectManager.Free;
  RSky.Free;
  RObjects.Free;
  RTerrain.Unload;
  RTerrain.Free;
  RCamera.Free;
  fLightManager.Free;
end;

procedure TModuleRendererOpenGL.RenderParts(Solid, Transparent: Boolean);
const
  SolidOnly: Byte = 1;
  TransparentOnly: Byte = 2;
begin
  if Solid then
    begin
    RSky.Render('', nil, nil);
    RObjects.Render('', @SolidOnly, nil);
    RTerrain.Render('', nil, nil);
    end;
  if Transparent then
    begin
    RObjects.Render('', @TransparentOnly, nil);
    RTerrain.RenderAutoplants('', nil, nil);
    end;
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
    fInterface.Options.Items['sky:rendering'] := 'off';
    fInterface.Options.Items['shader:mode'] := 'transform:depth';

    RTerrain.RenderWaterSurfaces;
    glClear(GL_DEPTH_BUFFER_BIT);
    RenderParts(true, false);
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
    RenderParts(true, true);
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
    RenderParts(true, true);
    glColorMask(false, false, false, true);
    glDisable(GL_BLEND);
    glClear(GL_DEPTH_BUFFER_BIT);
    fInterface.PushOptions;
      fInterface.Options.Items['terrain:autoplants'] := 'off';
      fInterface.Options.Items['shader:mode'] := 'transform:depth';
      fInterface.Options.Items['sky:rendering'] := 'off';
      RenderParts(true, false);
    fInterface.PopOptions;
    glColorMask(CR, CG, CB, true);
    RTerrain.fWaterLayerFBOs[i].RefractionFBO.Unbind;
    glDisable(GL_CLIP_PLANE0);
    end;
  fInterface.PopOptions;

  RObjects.RenderReflections;

  fFrustum.Calculate;

  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
  RenderParts(true, false);
  RTerrain.RenderWaterSurfaces;
  RenderParts(false, true);

  fInterface.Options.Items['all:above'] := '0';
  fInterface.Options.Items['all:below'] := '256';
end;


function TModuleRendererOpenGL.mapPixelToQuad(P: TVector2D): TVector2D;
var
  ABtoP, CtoD, B1, B2, D1, C1: TVector2D;
  a: TVector3D;
  nShadowQuad: Array[0..3] of TVector2D;
begin
  nShadowQuad[0] := Vector(ShadowQuad[0].x, ShadowQuad[0].z);
  nShadowQuad[1] := Vector(ShadowQuad[1].x, ShadowQuad[1].z);
  nShadowQuad[2] := Vector(ShadowQuad[2].x, ShadowQuad[2].z);
  nShadowQuad[3] := Vector(ShadowQuad[3].x, ShadowQuad[3].z);
  a := Cross(Vector(0.0, 1.0, 0.0), Vector(nShadowQuad[0].x - nShadowQuad[1].x, 0.0, nShadowQuad[0].y - nShadowQuad[1].y));
  ABtoP := Vector(A.X, A.Z);
  CtoD := nShadowQuad[3] - nShadowQuad[2];
  B1 := LineIntersection(nShadowQuad[0], nShadowQuad[1], P, P + ABtoP);
  B2 := LineIntersection(nShadowQuad[3], nShadowQuad[2], P, P + ABtoP);
  D1 := LineIntersection(nShadowQuad[0], nShadowQuad[3], P, P + CtoD);
  C1 := LineIntersection(nShadowQuad[1], nShadowQuad[2], P, P + CtoD);
  result.x := VecLength(D1 - P) / VecLength(D1 - C1);
  if (VecLengthNoRoot(C1 - P) > VecLengthNoRoot(C1 - D1)) and (VecLengthNoRoot(C1 - P) > VecLengthNoRoot(D1 - P)) then
    result.x := -result.x;
  result.y := VecLength(B1 - P) / VecLength(B1 - B2);
  if (VecLengthNoRoot(B2 - P) > VecLengthNoRoot(B2 - B1)) and (VecLengthNoRoot(B2 - P) > VecLengthNoRoot(B1 - P)) then
    result.y := -result.y;
end;

function TModuleRendererOpenGL.ProjectToBottom(A: TVector3D): TVector2D;
begin
  A := A + (A - OS) * A.Y / abs(A.Y - OS.Y);
  Result := Vector(A.X, A.Z);
end;

procedure TModuleRendererOpenGL.RenderShadows;
var
  i: Integer;
  LightVec, t1, t2: TVector3D;
  tmp1, tmp2: TVector2D;
  H: Single;
  S, T: Single;
  NewShadowQuad: Array[0..3] of TVector3D;
begin
  with ModuleManager.ModRenderer.RSky.Sun.Position do
    OS := Vector(X, Y, Z);
  OC := ModuleManager.ModCamera.ActiveCamera.Position;
  H := OC.Y - MinRenderHeight;
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  ModuleManager.ModGLMng.SetUp3DMatrix;
  ShadowQuad[0] := GetRay(-1, -1);
  ShadowQuad[1] := GetRay( 1, -1);
  ShadowQuad[2] := GetRay( 1,  1);
  ShadowQuad[3] := GetRay(-1,  1);
  if (ShadowQuad[0].Y > ShadowQuad[3].Y) or (ShadowQuad[1].Y > ShadowQuad[2].Y) then
    begin
    t1 := ShadowQuad[0];            t2 := ShadowQuad[1];
    ShadowQuad[0] := ShadowQuad[3]; ShadowQuad[1] := ShadowQuad[2];
    ShadowQuad[3] := t1;            ShadowQuad[2] := t2;
    end;
{  if (ShadowQuad[0].Y > 0) and (ShadowQuad[1].Y > 0) and (ShadowQuad[2].Y > 0) and (ShadowQuad[3].Y > 0) then
    begin
    ShadowQuad[0] := GetNegRay(-1, -1);
    ShadowQuad[1] := GetNegRay( 1, -1);
    ShadowQuad[2] := GetNegRay( 1,  1);
    ShadowQuad[3] := GetNegRay(-1,  1);
    H := H + 30;
    end
  else }if (ShadowQuad[2].Y > -0.004 * H) or (ShadowQuad[3].Y > -0.004 * H) then
    begin
    ShadowQuad[2].Y := -0.004 * H;
    ShadowQuad[3].Y := -0.004 * H;
    end;
  if DotProduct(normalize((ShadowQuad[0] + ShadowQuad[1]) / 2), normalize((ShadowQuad[3] + ShadowQuad[2]) / 2)) > DotProduct(normalize((ShadowQuad[3] + ShadowQuad[2]) / 2), Vector(0, -1, 0)) then
    begin
    ShadowQuad[0] := normalize(Vector(0, -1, 0) - Cross(VecToFront, Vector(0, 1, 0)) * Vector(1, 0, 1));
    ShadowQuad[1] := normalize(Cross(VecToFront, Vector(0, 1, 0)) * Vector(1, 0, 1) + Vector(0, -1, 0));
    end;
  t1 := normalize(Vector(VecToFront.X, 0, VecToFront.Z));
  t2 := normalize(OS - OC);
  S := DotProduct(t1, normalize(t2 * Vector(1, 0, 1)));
  if S >= 0 then
    begin
    for i := 0 to 1 do
      begin
      t1 := GetRay(1 - 2 * i, 1) * -1;
      t2 := GetRay(-1, -1);
      ShadowQuad[i] := ShadowQuad[i] + Vector(t1.x, 0, t1.z) / abs(t2.y) * Min(20, H) * S;
      end;
    if (ShadowQuad[2].Y > Mix(-0.004, -0.008, S) * H) or (ShadowQuad[3].Y > Mix(-0.004, -0.008, S) * H) then
      begin
      ShadowQuad[2].Y := Mix(-0.004, -0.008, S) * H;
      ShadowQuad[3].Y := Mix(-0.004, -0.008, S) * H;
      end;
    end
  else
    begin
    for i := 2 to 3 do
      begin
      t1 := GetRay(1 - 2 * (i - 2), 1) * -1;
      t2 := GetRay(-1, -1);
      ShadowQuad[i] := ShadowQuad[i] + Vector(t1.x, 0, t1.z) / abs(t2.y) * Min(20, H) * S;
      end;
    if (ShadowQuad[0].Y > Mix(0.004, 0.008, S) * H) or (ShadowQuad[1].Y > Mix(0.004, 0.008, S) * H) then
      begin
      ShadowQuad[0].Y := Mix(0.004, 0.008, S) * H;
      ShadowQuad[1].Y := Mix(0.004, 0.008, S) * H;
      end;
    // Workaround for a bug that prevents parts of shadows from being rendered
//     T := DotProduct(Normalize(VecToFront), Vector(0, -1, 0));
//     T := T * T;
//     ShadowQuad[0] := ShadowQuad[0] + (ShadowQuad[0] - ShadowQuad[1]) * 0.5 * (abs(T)) * min(0.3, 0.6 + 0.5 * S);
//     ShadowQuad[0] := ShadowQuad[0] + (ShadowQuad[0] - ShadowQuad[3]) * 0.5 * (abs(T)) * min(0.3, 0.6 + 0.5 * S);
//     ShadowQuad[1] := ShadowQuad[1] + (ShadowQuad[1] - ShadowQuad[0]) * 0.5 * (abs(T)) * min(0.3, 0.6 + 0.5 * S);
//     ShadowQuad[1] := ShadowQuad[1] + (ShadowQuad[1] - ShadowQuad[2]) * 0.5 * (abs(T)) * min(0.3, 0.6 + 0.5 * S);
//     ShadowQuad[2] := ShadowQuad[2] + (ShadowQuad[2] - ShadowQuad[1]) * 0.5 * (abs(T)) * min(0.3, 0.6 + 0.5 * S);
//     ShadowQuad[2] := ShadowQuad[2] + (ShadowQuad[2] - ShadowQuad[3]) * 0.5 * (abs(T)) * min(0.3, 0.6 + 0.5 * S);
//     ShadowQuad[3] := ShadowQuad[3] + (ShadowQuad[3] - ShadowQuad[0]) * 0.5 * (abs(T)) * min(0.3, 0.6 + 0.5 * S);
//     ShadowQuad[3] := ShadowQuad[3] + (ShadowQuad[3] - ShadowQuad[2]) * 0.5 * (abs(T)) * min(0.3, 0.6 + 0.5 * S);
    end;

{  FitToLight(ShadowQuad[0], ShadowQuad[1], OldShadowQuad[0] - OldShadowQuad[1]);
  FitToLight(ShadowQuad[0], ShadowQuad[3], OldShadowQuad[1] - OldShadowQuad[2]);
  FitToLight(ShadowQuad[1], ShadowQuad[0], OldShadowQuad[1] - OldShadowQuad[0]);
  FitToLight(ShadowQuad[1], ShadowQuad[2], OldShadowQuad[0] - OldShadowQuad[3]);}
{  FitToLight(ShadowQuad[2], ShadowQuad[1]);
  FitToLight(ShadowQuad[2], ShadowQuad[3]);
  FitToLight(ShadowQuad[3], ShadowQuad[0]);
  FitToLight(ShadowQuad[3], ShadowQuad[2]);}
  for i := 0 to 3 do
    begin
    ShadowQuad[i] := OC + ShadowQuad[i] * H / abs(ShadowQuad[i].Y);
    end;
  for i := 0 to 3 do
    begin
    LightVec := (ShadowQuad[i] - OS);
    ShadowQuad[i] := ShadowQuad[i] + LightVec * MinRenderHeight / abs(LightVec.Y);
    end;

  tmp1 := LineIntersection(Vector(ShadowQuad[1].X, ShadowQuad[1].Z), Vector(ShadowQuad[2].X, ShadowQuad[2].Z),
                           Vector(ShadowQuad[3].X, ShadowQuad[3].Z), Vector(ShadowQuad[3].X, ShadowQuad[3].Z) + Vector(ShadowQuad[1].X, ShadowQuad[1].Z) - Vector(ShadowQuad[0].X, ShadowQuad[0].Z));
  tmp2 := LineIntersection(Vector(ShadowQuad[0].X, ShadowQuad[0].Z), Vector(ShadowQuad[3].X, ShadowQuad[3].Z),
                           Vector(ShadowQuad[2].X, ShadowQuad[2].Z), Vector(ShadowQuad[2].X, ShadowQuad[2].Z) + Vector(ShadowQuad[1].X, ShadowQuad[1].Z) - Vector(ShadowQuad[0].X, ShadowQuad[0].Z));
  if VecLengthNoRoot(OS - Vector(tmp1.x, 0, tmp1.y)) > VecLengthNoRoot(OS - Vector(tmp2.x, 0, tmp2.y)) then
    ShadowQuad[2] := Vector(tmp1.X, 0, tmp1.Y)
  else
    ShadowQuad[3] := Vector(tmp2.X, 0, tmp2.Y);

  fInterface.PushOptions;
  ModuleManager.ModRenderer.RSky.Sun.ShadowMap.Bind;
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
//   glMatrixMode(GL_TEXTURE);
//   glLoadIdentity;
//   gluPerspective(fSunShadowOpenAngle, 1, 0.5, 20000);
//   gluLookAt(OS.X, OS.Y, OS.Z,
//             Round(OC.X), Round(OC.Y), Round(OC.Z),
//             0, 1, 0);
  fInterface.Options.Items['shader:mode'] := 'sunshadow:sunshadow';
  fInterface.Options.Items['terrain:autoplants'] := 'off';
  fInterface.Options.Items['sky:rendering'] := 'off';
  if (Park.pSky.Time >= 86400 / 4) and (Park.pSky.Time <= 86400 / 4 * 3) then
    RenderParts(true, true);
  ModuleManager.ModRenderer.RSky.Sun.ShadowMap.UnBind;
  fInterface.PopOptions;
end;

function TModuleRendererOpenGL.GetNegRay(MX, MY: Single): TVector3D;
var
  pmatrix: TMatrix;
  VecLeft, VecUp: TVector3D;
begin
  glGetFloatv(GL_PROJECTION_MATRIX, @pmatrix[0]);

  with ModuleManager.ModCamera do
    VecToFront := Normalize(Vector(Sin(DegToRad(ActiveCamera.Rotation.Y)) * Cos(-DegToRad(ActiveCamera.Rotation.X)),
                                  -Sin(DegToRad(-ActiveCamera.Rotation.X)),
                                  -Cos(DegToRad(ActiveCamera.Rotation.Y)) * Cos(-DegToRad(ActiveCamera.Rotation.X))));
  VecLeft := Normal(VecToFront, Vector(0, 1, 0));
  VecUp := Normal(VecLeft, VecToFront);
  Result := normalize(VecToFront + VecUp * (MY / pMatrix[5]) + VecLeft * (MX / pMatrix[0]));
end;

function TModuleRendererOpenGL.GetRay(MX, MY: Single): TVector3D;
var
  pmatrix: TMatrix;
  VecLeft, VecUp: TVector3D;
begin
  glGetFloatv(GL_PROJECTION_MATRIX, @pmatrix[0]);

  with ModuleManager.ModCamera do
    VecToFront := Normalize(Vector(Sin(DegToRad(ActiveCamera.Rotation.Y)) * Cos(DegToRad(ActiveCamera.Rotation.X)),
                                  -Sin(DegToRad(ActiveCamera.Rotation.X)),
                                  -Cos(DegToRad(ActiveCamera.Rotation.Y)) * Cos(DegToRad(ActiveCamera.Rotation.X))));
  VecLeft := Normal(VecToFront, Vector(0, 1, 0));
  VecUp := Normal(VecLeft, VecToFront);
  Result := normalize(VecToFront + VecUp * (MY / pMatrix[5]) + VecLeft * (MX / pMatrix[0]));
end;

procedure TModuleRendererOpenGL.RenderScene;
var
  i: Integer;

  procedure GetSelectionRay;
  var
    MX, MY: Single;
  begin
    fSelectionStart := ModuleManager.ModCamera.ActiveCamera.Position;

    MX := 2 * (ModuleManager.ModInputHandler.MouseX / ResX) - 1;
    MY := -2 * (ModuleManager.ModInputHandler.MouseY / ResY) + 1;

    fSelectionRay := GetRay(MX, MY);
  end;
begin
  CR := true;
  CG := true;
  CB := true;

  fInterface.Options.Items['all:renderpass'] := '0';

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;

  // Preparation
  RSky.Advance;
  RSky.CameraLight.Position.X := ModuleManager.ModCamera.ActiveCamera.Position.X;
  RSky.CameraLight.Position.Y := ModuleManager.ModCamera.ActiveCamera.Position.Y + 2;
  RSky.CameraLight.Position.Z := ModuleManager.ModCamera.ActiveCamera.Position.Z;
  RSky.CameraLight.Position.W := 5;
//   RSky.CameraLight.DiffuseFactor := 0.3;
//   RSky.CameraLight.AmbientFactor := 0.7;
  RSky.CameraLight.Color := Vector(1, 1, 1, 1);

  RSky.CameraLight2.Position.X := ModuleManager.ModCamera.ActiveCamera.Position.X;
  RSky.CameraLight2.Position.Z := ModuleManager.ModCamera.ActiveCamera.Position.Z;
  RSky.CameraLight2.Position.Y := Park.pTerrain.HeightMap[RSky.CameraLight2.Position.X, RSky.CameraLight2.Position.Z] + 2;
  RSky.CameraLight2.Position.W := 2;
  RSky.CameraLight2.Color := Vector(1, 1, 1, 1);

  // Assigning lights to meshes
  if not LightManager.Working then
    begin
    LightManager.AssignLightsToObjects;
    LightManager.Working := true;
    end;

  // Rendering
  fInterface.Options.Items['shader:mode'] := 'normal:normal';
  fInterface.Options.Items['all:frustumcull'] := 'on';

  glEnable(GL_DEPTH_TEST);
  glDepthMask(true);

  glDisable(GL_BLEND);

  if (fInterface.Options.Items['shadows:enabled'] = 'on') then
    begin
    DistanceMeasuringPoint := OC;
    MaxRenderDistance := 10000;
    RenderShadows;
    fLightManager.RenderShadows;
    MaxRenderDistance := 10000;
    DistanceMeasuringPoint := OC;
    end;
//   RSky.CameraLight.Bind(1);
//   RSky.CameraLight2.Bind(2);
//   glActiveTexture(GL_TEXTURE0);

  MinRenderHeight := OC.Y - 8;
  glSecondaryColor3f(OC.X, OC.Y, OC.Z);

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
//
//   glUseProgram(0);
//   glDisable(GL_TEXTURE_2D);
//   glDisable(GL_CULL_FACE);

//   glColor4f(1, 1, 1, 1);
//   glBegin(GL_QUADS);
//     glVertex3f(-10, 70, -10);
//     glVertex3f( 10, 70, -10);
//     glVertex3f( 10, 70,  10);
//     glVertex3f(-10, 70,  10);
//   glEnd;
//   fTestVBO.Bind;
//   fTestVBO.Vertices[0] := fTestVBO.Vertices[0] + Vector(0, 0.01, 0);
//   fTestVBO.Render;
//   fTestVBO.Unbind;

//   glEnable(GL_TEXTURE_2D);
//
  glMatrixMode(GL_TEXTURE);
  glLoadIdentity;
  glMatrixMode(GL_MODELVIEW);

  glDisable(GL_CULL_FACE);

  EventManager.CallEvent('TModuleRenderer.PostRender', nil, nil);

  RTerrain.Advance;
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
    SetConfVal('shadows:texsize', '512');
    end;
  StaticLODBias := 0;
  fInterface.Options.Items['terrain:autoplants'] := GetConfVal('terrain:autoplants');
  fInterface.Options.Items['terrain:hd'] := GetConfVal('terrain:hd');
  fInterface.Options.Items['shadows:enabled'] := GetConfVal('shadows:enabled');
  fInterface.Options.Items['shadows:texsize'] := GetConfVal('shadows:texsize');
end;

constructor TModuleRendererOpenGL.Create;
begin
  fSunShadowOpenAngle := 3;
  fModName := 'RendererGL';
  fModType := 'Renderer';
  ModuleManager.ModGLContext.GetResolution(ResX, ResY);
  fInterface := TRendererOpenGLInterface.Create;
  fFrustum := TFrustum.Create;
  SetConfVal('all:polygonmode', 'fill');
  DynamicLODBias := 0;
  fDistTexture := TTexture.Create;
  fDistTexture.CreateNew(ResX, ResY, GL_RGBA);
  fDistTexture.SetClamp(GL_CLAMP, GL_CLAMP);
  fDistTexture.SetFilter(GL_NEAREST, GL_NEAREST);
//   fTestVBO := TObjectVBO.Create(4, 2);
//   with fTestVBO do
//     begin
//     Vertices[0] := Vector(-10, 70, -10); Normals[0] := Vector(0, 1, 0); TexCoords[0] := Vector(0, 0); Colors[0] := Vector(1, 1, 1, 1);
//     Vertices[1] := Vector( 10, 70, -10); Normals[1] := Vector(0, 1, 0); TexCoords[1] := Vector(0, 0); Colors[1] := Vector(1, 1, 1, 1);
//     Vertices[2] := Vector( 10, 70,  10); Normals[2] := Vector(0, 1, 0); TexCoords[2] := Vector(0, 0); Colors[2] := Vector(1, 1, 1, 1);
//     Vertices[3] := Vector(-10, 70,  10); Normals[3] := Vector(0, 1, 0); TexCoords[3] := Vector(0, 0); Colors[3] := Vector(1, 1, 1, 1);
//
//     Indicies[0] := TriangleIndexList(0, 1, 2);
//     Indicies[1] := TriangleIndexList(0, 2, 3);
//     end;
//   fTestVBO.Unbind;
end;

destructor TModuleRendererOpenGL.Free;
begin
//   fTestVBO.Free;
  fDistTexture.Free;
  fFrustum.Free;
  fInterface.Free;
end;

end.