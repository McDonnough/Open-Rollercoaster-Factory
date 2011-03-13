unit m_renderer_owe_renderpass;

interface

uses
  SysUtils, Classes, m_renderer_owe_classes, m_renderer_owe_lights, m_shdmng_class, m_texmng_class, u_vectors, u_graphics, u_scene,
  DGLOpenGL;

type
  TRenderPass = class
    protected
      fGBuffer, fLightBuffer, fSpareBuffer, fSceneBuffer: TFBO;
      fWidth, fHeight: Integer;
    public
      MinY, MaxY: Integer;
      RenderAutoplants, RenderTerrain, RenderObjects, RenderParticles, RenderSky, RenderWater: Boolean;
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
  m_varlist, m_renderer_owe;

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
begin
  glPushAttrib(GL_ALL_ATTRIB_BITS);

  glColorMask(true, true, true, true);
  glDepthMask(true);

  // Opaque parts only
  fGBuffer.Bind;
    glDisable(GL_BLEND);
    glDepthMask(true);
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LESS);
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

    glDisable(GL_CULL_FACE);

    // Water
    if (RenderWater) and (RenderTerrain) then
      begin
      glColorMask(false, false, false, false);
      glDepthMask(false);
      ModuleManager.ModRenderer.RWater.Check;
      glDepthMask(true);
      glColorMask(true, true, true, true);

      ModuleManager.ModRenderer.RWater.Render;
      end;

  fGBuffer.Unbind;

  // Save material buffer
  fSpareBuffer.Bind;
    fGBuffer.Textures[0].Bind;
    ModuleManager.ModRenderer.FullscreenShader.Bind;
    DrawFullscreenQuad;
    ModuleManager.ModRenderer.FullscreenShader.Unbind;
  fSpareBuffer.Unbind;

  // Transparent parts, fuck up the material buffer
  fGBuffer.Bind;
    ModuleManager.ModRenderer.TransparencyMask.Bind(7);

    glEnable(GL_ALPHA_TEST);
    glAlphaFunc(GL_GREATER, 0.0);
//     glColorMask(true, true, true, false);

    // Autoplants
    if RenderAutoplants then
      begin
      ModuleManager.ModRenderer.RAutoplants.CurrentShader := ModuleManager.ModRenderer.RAutoplants.GeometryPassShader;
      ModuleManager.ModRenderer.RAutoplants.Render;
      end;

    // Objects
    if RenderObjects then
      begin
      ModuleManager.ModRenderer.RObjects.MaterialMode := false;
      ModuleManager.ModRenderer.RObjects.RenderTransparent;
      end;

    // End

//     glColorMask(true, true, true, true);
    glDisable(GL_DEPTH_TEST);
    glDepthMask(false);
    glDisable(GL_ALPHA_TEST);

  fGBuffer.Unbind;

  // Lighting pass
  fLightBuffer.Bind;
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT);

    glDisable(GL_ALPHA_TEST);
    glDisable(GL_BLEND);

    if ModuleManager.ModRenderer.UseSunShadows then
      ModuleManager.ModRenderer.SunShadowBuffer.Textures[0].Bind(2);

    fGBuffer.Textures[0].Bind(3);
    fGBuffer.Textures[1].Bind(1);
    fGBuffer.Textures[2].Bind(0);

    ModuleManager.ModRenderer.SunShader.Bind;
    ModuleManager.ModRenderer.SunShader.UniformF('ShadowSize', ModuleManager.ModRenderer.ShadowSize);
    ModuleManager.ModRenderer.SunShader.UniformF('ShadowOffset', ModuleManager.ModRenderer.ShadowOffset.X, ModuleManager.ModRenderer.ShadowOffset.Y, ModuleManager.ModRenderer.ShadowOffset.Z);
    ModuleManager.ModRenderer.SunShader.UniformI('BlurSamples', ModuleManager.ModRenderer.ShadowBlurSamples);
    DrawFullscreenQuad;
    ModuleManager.ModRenderer.SunShader.Unbind;
  fLightBuffer.Unbind;

  // Composition

  fSceneBuffer.Bind;
    glDepthMask(true);
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LEQUAL);
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT);

    ModuleManager.ModRenderer.CompositionShader.Bind;

    fGBuffer.Textures[3].Bind(4);
    fGBuffer.Textures[2].Bind(2);
    fLightBuffer.Textures[0].Bind(1);
    fSpareBuffer.Textures[0].Bind(0);
    DrawFullscreenQuad;

    ModuleManager.ModRenderer.CompositionShader.Unbind;

    // Transparent parts only

    fLightBuffer.Textures[0].Bind(7);

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    // Autoplants
    if RenderAutoplants then
      begin
      ModuleManager.ModRenderer.RAutoplants.CurrentShader := ModuleManager.ModRenderer.RAutoplants.MaterialPassShader;
      ModuleManager.ModRenderer.RAutoplants.Render;
      end;

    // Objects
    if RenderObjects then
      begin
      ModuleManager.ModRenderer.RObjects.MaterialMode := true;
      glEnable(GL_CULL_FACE);
      ModuleManager.ModRenderer.RObjects.RenderTransparent;
      glDisable(GL_CULL_FACE);
      end;

    glDisable(GL_BLEND);

    glDisable(GL_DEPTH_TEST);
    glDepthMask(false);

  fSceneBuffer.Unbind;

  glPopAttrib;
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

  fSpareBuffer := TFBO.Create(X, Y, false);
  fSpareBuffer.AddTexture(GL_RGBA16F_ARB, GL_NEAREST, GL_NEAREST);
  fSpareBuffer.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);

  fLightBuffer := TFBO.Create(X, Y, false);
  fLightBuffer.AddTexture(GL_RGBA16F_ARB, GL_NEAREST, GL_NEAREST);// Colors, Specular
  fLightBuffer.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);

  fSceneBuffer := TFBO.Create(X, Y, true);
  fSceneBuffer.AddTexture(GL_RGB, GL_LINEAR, GL_LINEAR);          // Composed image
  fSceneBuffer.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);

  RenderAutoplants := True;
  RenderParticles := True;
  RenderSky := True;
  RenderTerrain := True;
  RenderObjects := True;
end;

destructor TRenderPass.Free;
begin
  fSceneBuffer.Free;
  fLightBuffer.Free;
  fSpareBuffer.Free;
  fGBuffer.Free;
end;

end.