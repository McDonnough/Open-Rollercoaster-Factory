unit m_renderer_owe_renderpass;

interface

uses
  SysUtils, Classes, m_renderer_owe_classes, m_shdmng_class, m_texmng_class, u_vectors, u_graphics, u_scene,
  DGLOpenGL;

type
  TRenderPass = class
    protected
      fGBuffer, fLightBuffer, fSpareBuffer, fSceneBuffer: TFBO;
      fWidth, fHeight: Integer;
      fIsUnderWater: Boolean;
    public
      MinY, MaxY: Integer;
      RenderAutoplants, RenderTerrain, RenderObjects, RenderParticles, RenderSky, RenderWater, EnableFog, EnableRefractionFog: Boolean;
      property Width: Integer read fWidth;
      property Height: Integer read fHeight;
      property Scene: TFBO read fSceneBuffer;
      property GBuffer: TFBO read fGBuffer;
      procedure Render;
      constructor Create(X, Y: Integer);
      destructor Free;
    end;

implementation

uses
  m_varlist, m_renderer_owe, g_park, m_renderer_owe_lights;

procedure TRenderPass.Render;
  procedure DrawFullscreenQuad;
  begin
    glBegin(GL_QUADS);
      glVertex2f(-1, -1);
      glVertex2f( 1, -1);
      glVertex2f( 1,  1);
      glVertex2f(-1,  1);
    glEnd;
  end;
var
  fWaterHeight: Single;
  i: Integer;
begin
  if EnableRefractionFog then
    ModuleManager.ModRenderer.FogRefractMode := 1;

  ModuleManager.ModRenderer.RenderParticles := RenderParticles;
  ModuleManager.ModRenderer.RObjects.CurrentGBuffer := fGBuffer;

  glPushAttrib(GL_ALL_ATTRIB_BITS);

  glDisable(GL_BLEND);
  glDisable(GL_ALPHA_TEST);

  glColorMask(true, true, true, true);
  glDepthMask(true);

  if EnableFog then
    ModuleManager.ModRenderer.MaxRenderDistance := ModuleManager.ModRenderer.MaxFogDistance
  else
    ModuleManager.ModRenderer.MaxRenderDistance := 10000;
    
  fWaterHeight := Park.pTerrain.WaterMap[ModuleManager.ModRenderer.ViewPoint.X, ModuleManager.ModRenderer.ViewPoint.Z];
  fIsUnderWater := False;
  if ModuleManager.ModRenderer.ViewPoint.Y < fWaterHeight then
    begin
    fIsUnderWater := True;
    ModuleManager.ModRenderer.MaxRenderDistance := 55;
    end;

  // Opaque parts only
  GBuffer.Bind;
    glDisable(GL_BLEND);
    glDepthMask(true);
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LESS);
    glClearColor(0, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT);

    glDepthMask(false);
    ModuleManager.ModRenderer.RenderMaxVisibilityQuad;
    glDepthMask(true);
    glEnable(GL_CULL_FACE);

    // Sky
    if RenderSky then
      ModuleManager.ModRenderer.RSky.Render;

    // Objects
    if RenderObjects then
      ModuleManager.ModRenderer.RObjects.RenderOpaque;

    // Terrain
    if RenderTerrain then
      begin
      ModuleManager.ModRenderer.RTerrain.CurrentShader := ModuleManager.ModRenderer.RTerrain.GeometryPassShader;
      ModuleManager.ModRenderer.RTerrain.Render;
      end;

    // Water
    if RenderWater then
      begin
//       glColorMask(false, false, false, false);
//       glDepthMask(false);
//       ModuleManager.ModRenderer.RWater.Check;
//       glDepthMask(true);
//       glColorMask(true, true, true, true);
      ModuleManager.ModRenderer.RWater.RenderSimple;
      end;
//   GBuffer.Unbind;

//   GBuffer.Bind;

    glDisable(GL_CULL_FACE);
  GBuffer.Unbind;

  // Save material buffer
  fSpareBuffer.Bind;
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT);
    GBuffer.Textures[0].Bind(0);
    ModuleManager.ModRenderer.FullscreenShader.Bind;
    DrawFullscreenQuad;
    ModuleManager.ModRenderer.FullscreenShader.Unbind;
  fSpareBuffer.Unbind;

  // Transparent parts, fuck up the material buffer
  GBuffer.Bind;
    ModuleManager.ModRenderer.TransparencyMask.Bind(7);

    glDisable(GL_ALPHA_TEST);
//     glColorMask(true, true, true, false);

    // Autoplants
    if RenderAutoplants then
      begin
      ModuleManager.ModRenderer.RAutoplants.CurrentShader := ModuleManager.ModRenderer.RAutoplants.GeometryPassShader;
      ModuleManager.ModRenderer.RAutoplants.Render;
      end;

    // Objects and particles
    if RenderObjects then
      begin
      ModuleManager.ModRenderer.RParticles.CurrentShader := ModuleManager.ModRenderer.RParticles.GeometryShader;
      ModuleManager.ModRenderer.RObjects.MaterialMode := False;
      glEnable(GL_CULL_FACE);
      ModuleManager.ModRenderer.RObjects.RenderTransparent;
      glDisable(GL_CULL_FACE);
      end;

    // End

//     glColorMask(true, true, true, true);
    glDisable(GL_DEPTH_TEST);
    glDepthMask(false);
    glDisable(GL_ALPHA_TEST);

  GBuffer.Unbind;

  // Lighting pass
  fLightBuffer.Bind;
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT);

    glDisable(GL_ALPHA_TEST);
    glDisable(GL_BLEND);

    ModuleManager.ModRenderer.RTerrain.TerrainMap.Bind(4);

    GBuffer.Textures[5].Bind(6);

    if ModuleManager.ModRenderer.UseSunShadows then
      ModuleManager.ModRenderer.SunShadowBuffer.Textures[0].Bind(2);

    GBuffer.Textures[0].Bind(3);
    GBuffer.Textures[1].Bind(1);
    GBuffer.Textures[2].Bind(0);

    ModuleManager.ModRenderer.SunShader.Bind;
    ModuleManager.ModRenderer.SunShader.UniformI('UseSSAO', 0);
    ModuleManager.ModRenderer.SunShader.UniformF('ShadowSize', ModuleManager.ModRenderer.ShadowSize);
    ModuleManager.ModRenderer.SunShader.UniformF('ShadowOffset', ModuleManager.ModRenderer.ShadowOffset.X, ModuleManager.ModRenderer.ShadowOffset.Y, ModuleManager.ModRenderer.ShadowOffset.Z);
    DrawFullscreenQuad;
    ModuleManager.ModRenderer.SunShader.Unbind;

    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE);

    for i := 0 to high(ModuleManager.ModRenderer.LightManager.fRegisteredLights) do
      if ModuleManager.ModRenderer.LightManager.fRegisteredLights[i].IsVisible(ModuleManager.ModRenderer.Frustum) then
        begin
        ModuleManager.ModRenderer.LightManager.fRegisteredLights[i].Bind(1);
        if ModuleManager.ModRenderer.LightManager.fRegisteredLights[i].ShadowMap <> nil then
          begin
          ModuleManager.ModRenderer.LightManager.fRegisteredLights[i].ShadowMap.Map.Textures[0].Bind(2);
          ModuleManager.ModRenderer.LightShaderWithShadow.Bind;
          end
        else
          ModuleManager.ModRenderer.LightShader.Bind;
//         DrawFullscreenQuad;
        ModuleManager.ModRenderer.LightManager.fRegisteredLights[i].RenderBoundingCube;
        ModuleManager.ModTexMng.ActivateTexUnit(2);
        ModuleManager.ModTexMng.BindTexture(-1);
        ModuleManager.ModTexMng.ActivateTexUnit(0);
        ModuleManager.ModRenderer.LightManager.fRegisteredLights[i].UnBind(1);
        end;
    ModuleManager.ModRenderer.LightShader.UnBind;

    GBuffer.Textures[0].UnBind;
    GBuffer.Textures[1].UnBind;
    GBuffer.Textures[2].UnBind;

    glDisable(GL_BLEND);
  fLightBuffer.Unbind;

  // Composition

  fSceneBuffer.Bind;
    glDepthMask(true);
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LEQUAL);
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT);

    ModuleManager.ModRenderer.CompositionShader.Bind;
    if (fIsUnderWater) or (EnableRefractionFog) then
      begin
      ModuleManager.ModRenderer.FogColor := Vector(0.20, 0.30, 0.27) * Vector3D(ModuleManager.ModRenderer.RSky.Sun.AmbientColor) * 3.0;
      ModuleManager.ModRenderer.FogStrength := 0.152; // log(0.9) / log(0.5);
      end
    else if EnableFog then
      begin
      ModuleManager.ModRenderer.FogColor := Vector3D(Pow(ModuleManager.ModRenderer.RSky.Sun.AmbientColor + ModuleManager.ModRenderer.RSky.Sun.Color, 0.33)) * 0.5;
      ModuleManager.ModRenderer.FogStrength := ModuleManager.ModRenderer.RSky.FogStrength;
      end
    else
      begin
      ModuleManager.ModRenderer.FogColor := Vector(1.0, 1.0, 1.0);
      ModuleManager.ModRenderer.FogStrength := 0.0;
      end;
    ModuleManager.ModRenderer.CompositionShader.UniformF('FogColor', ModuleManager.ModRenderer.FogColor);
    ModuleManager.ModRenderer.CompositionShader.UniformF('FogStrength', ModuleManager.ModRenderer.FogStrength);
    ModuleManager.ModRenderer.CompositionShader.UniformF('WaterHeight', ModuleManager.ModRenderer.RWater.CurrentHeight);
    ModuleManager.ModRenderer.CompositionShader.UniformF('WaterRefractionMode', ModuleManager.ModRenderer.FogRefractMode);

    GBuffer.Textures[4].Bind(3);
    GBuffer.Textures[3].Bind(4);
    GBuffer.Textures[2].Bind(2);
    fSpareBuffer.Textures[0].Bind(0);
    fLightBuffer.Textures[0].Bind(7);
    fLightBuffer.Textures[1].Bind(6);
    DrawFullscreenQuad;

    ModuleManager.ModRenderer.CompositionShader.Unbind;

    // Transparent parts only

    fLightBuffer.Textures[1].Bind(4);

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    // Autoplants
    if RenderAutoplants then
      begin
      ModuleManager.ModRenderer.RAutoplants.CurrentShader := ModuleManager.ModRenderer.RAutoplants.MaterialPassShader;
      ModuleManager.ModRenderer.RAutoplants.Render;
      end;

    // Objects and particles
    if RenderObjects then
      begin
      ModuleManager.ModRenderer.RParticles.CurrentShader := ModuleManager.ModRenderer.RParticles.MaterialShader;
      ModuleManager.ModRenderer.RObjects.MaterialMode := True;
      glEnable(GL_CULL_FACE);
      ModuleManager.ModRenderer.RObjects.RenderTransparent;
      glDisable(GL_CULL_FACE);
      end;

    glDisable(GL_BLEND);

    glDisable(GL_DEPTH_TEST);
    glDepthMask(false);

  fSceneBuffer.Unbind;

  glPopAttrib;

  ModuleManager.ModTexMng.ActivateTexUnit(7); ModuleManager.ModTexMng.BindTexture(-1);
  ModuleManager.ModTexMng.ActivateTexUnit(6); ModuleManager.ModTexMng.BindTexture(-1);
  ModuleManager.ModTexMng.ActivateTexUnit(5); ModuleManager.ModTexMng.BindTexture(-1);
  ModuleManager.ModTexMng.ActivateTexUnit(4); ModuleManager.ModTexMng.BindTexture(-1);
  ModuleManager.ModTexMng.ActivateTexUnit(3); ModuleManager.ModTexMng.BindTexture(-1);
  ModuleManager.ModTexMng.ActivateTexUnit(2); ModuleManager.ModTexMng.BindTexture(-1);
  ModuleManager.ModTexMng.ActivateTexUnit(1); ModuleManager.ModTexMng.BindTexture(-1);
  ModuleManager.ModTexMng.ActivateTexUnit(0); ModuleManager.ModTexMng.BindTexture(-1);

  ModuleManager.ModRenderer.RObjects.CurrentGBuffer := ModuleManager.ModRenderer.GBuffer;

  ModuleManager.ModRenderer.FogRefractMode := 0;
end;

constructor TRenderPass.Create(X, Y: Integer);
begin
  fWidth := X;
  fHeight := Y;

  fGBuffer := TFBO.Create(X, Y, true);
  fGBuffer.AddTexture(GL_RGBA16F_ARB, GL_NEAREST, GL_NEAREST);  // Materials (opaque only) and specularity
  fGBuffer.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);
  fGBuffer.AddTexture(GL_RGBA16F_ARB, GL_NEAREST, GL_NEAREST);  // Normals and specular hardness
  fGBuffer.Textures[1].SetClamp(GL_CLAMP, GL_CLAMP);
  fGBuffer.AddTexture(GL_RGBA32F_ARB, GL_NEAREST, GL_NEAREST);  // Vertex and depth
  fGBuffer.Textures[2].SetClamp(GL_CLAMP, GL_CLAMP);
  fGBuffer.AddTexture(GL_RGB, GL_NEAREST, GL_NEAREST);          // Material IDs
  fGBuffer.Textures[3].SetClamp(GL_CLAMP, GL_CLAMP);
  fGBuffer.AddTexture(GL_RGBA16F_ARB, GL_NEAREST, GL_NEAREST);  // Reflection and reflectivity
  fGBuffer.Textures[4].SetClamp(GL_CLAMP, GL_CLAMP);
  fGBuffer.AddTexture(GL_RGBA16F_ARB, GL_NEAREST, GL_NEAREST);  // Emission
  fGBuffer.Textures[5].SetClamp(GL_CLAMP, GL_CLAMP);
  fGBuffer.Unbind;

  fSpareBuffer := TFBO.Create(X, Y, false);
  fSpareBuffer.AddTexture(GL_RGBA16F_ARB, GL_NEAREST, GL_NEAREST);
  fSpareBuffer.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);
  fSpareBuffer.Unbind;

  fLightBuffer := TFBO.Create(X, Y, false);
  fLightBuffer.AddTexture(GL_RGBA16F_ARB, GL_NEAREST, GL_NEAREST);// Colors
  fLightBuffer.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);
  fLightBuffer.AddTexture(GL_RGB16F_ARB, GL_NEAREST, GL_NEAREST); // Specular
  fLightBuffer.Textures[1].SetClamp(GL_CLAMP, GL_CLAMP);
  fLightBuffer.Unbind;

  fSceneBuffer := TFBO.Create(X, Y, true);
  fSceneBuffer.AddTexture(GL_RGB16F_ARB, GL_LINEAR, GL_LINEAR);   // Composed image
  fSceneBuffer.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);
  fSceneBuffer.Unbind;

  RenderAutoplants := True;
  RenderParticles := True;
  RenderSky := True;
  RenderTerrain := True;
  RenderObjects := True;
  RenderWater := True;
  EnableFog := True;
  EnableRefractionFog := False;
end;

destructor TRenderPass.Free;
begin
  fSceneBuffer.Free;
  fLightBuffer.Free;
  fSpareBuffer.Free;
  fGBuffer.Free;
end;

end.