unit m_renderer_owe;

interface

uses
  Classes, SysUtils, m_renderer_class, DGLOpenGL, g_park, u_math, u_vectors,
  m_renderer_owe_camera, math, m_texmng_class, m_shdmng_class, u_functions, m_renderer_owe_frustum,
  m_renderer_owe_sky, m_renderer_owe_classes, u_scene, m_renderer_owe_lights, m_renderer_owe_terrain,
  m_renderer_owe_autoplants, u_files, u_graphics;

type
  TModuleRendererOWE = class(TModuleRendererClass)
    protected
      fRendererSky: TRSky;
      fRendererCamera: TRCamera;
      fRendererTerrain: TRTerrain;
      fRendererAutoplants: TRAutoplants;
      fLightManager: TLightManager;
      fGBuffer, fLightBuffer, fSceneBuffer, fSSAOBuffer, fSunRayBuffer, fBloomBuffer, fFocalBlurBuffer, fMotionBlurBuffer, fSpareBuffer, fSunShadowBuffer, fTmpShadowBuffer: TFBO;
      fFSAASamples: Integer;
      fReflectionDepth, fReflectionUpdateInterval: Integer;
      fUseSunShadows, fUseLightShadows, fUseSunRays, fUseRefractions: Boolean;
      fUseBloom, fUseScreenSpaceAmbientOcclusion, fUseMotionBlur, fUseFocalBlur: Boolean;
      fLODDistanceOffset, fLODDistanceFactor, fMotionBlurStrength: Single;
      fShadowBufferSamples: Single;
      fSubdivisionCuts: Integer;
      fSubdivisionDistance: Single;
      fBufferSizeX, fBufferSizeY: Integer;
      fSSAOSamples, fShadowBlurSamples: Integer;
      fTmpBloomBuffer: TFBO;
      fMaxShadowPasses: Integer;
      fAutoplantCount: Integer;
      fAutoplantDistance: Single;
      fTerrainDetailDistance, fTerrainTesselationDistance, fTerrainBumpmapDistance: Single;
      fFullscreenShader, fBlackShader, fAAShader, fSunRayShader, fSunShader, fLightShader, fCompositionShader, fBloomShader, fBloomBlurShader, fFocalBlurShader, fShadowDepthShader, fLensFlareShader: TShader;
      fVecToFront: TVector3D;
      fFocusDistance: Single;
      fFrustum: TFrustum;
      fTransparencyMask, fLensFlareMask: TTexture;
      fShadowSize: Single;
      fShadowOffset: TVector3D;
      fUseLensFlare: Boolean;
      fWaterReflectionBufferSamples: Single;
    public
      property LightManager: TLightManager read fLightManager;
      property RCamera: TRCamera read fRendererCamera;
      property RSky: TRSky read fRendererSky;
      property RTerrain: TRTerrain read fRendererTerrain;
      property RAutoplants: TRAutoplants read fRendererAutoplants;
      property FullscreenShader: TShader read fFullscreenShader;
      property SunShader: TShader read fSunShader;
      property CompositionShader: TShader read fCompositionShader;
      property MotionBlurBuffer: TFBO read fMotionBlurBuffer;
      property FocalBlurBuffer: TFBO read fFocalBlurBuffer;
      property GBuffer: TFBO read fGBuffer;
      property LightBuffer: TFBO read fLightBuffer;
      property SceneBuffer: TFBO read fSceneBuffer;
      property SSAOBuffer: TFBO read fSSAOBuffer;
      property SunRayBuffer: TFBO read fSunRayBuffer;
      property BloomBuffer: TFBO read fBloomBuffer;
      property SpareBuffer: TFBO read fSpareBuffer;
      property SunShadowBuffer: TFBO read fSunShadowBuffer;
      property FSAASamples: Integer read fFSAASamples;
      property ReflectionDepth: Integer read fReflectionDepth;
      property ReflectionUpdateInterval: Integer read fReflectionUpdateInterval;
      property UseSunShadows: Boolean read fUseSunShadows;
      property UseLightShadows: Boolean read fUseLightShadows;
      property UseBloom: Boolean read fUseBloom;
      property UseMotionBlur: Boolean read fUseMotionBlur;
      property UseSunRays: Boolean read fUseSunRays;
      property UseFocalBlur: Boolean read fUseFocalBlur;
      property UseRefractions: Boolean read fUseRefractions;
      property UseScreenSpaceAmbientOcclusion: Boolean read fUseScreenSpaceAmbientOcclusion;
      property UseLensFlare: Boolean read fUseLensFlare;
      property WaterReflectionBufferSamples: Single read fWaterReflectionBufferSamples;
      property ShadowBufferSamples: Single read fShadowBufferSamples;
      property ShadowBlurSamples: Integer read fShadowBlurSamples;
      property SSAOSamples: Integer read fSSAOSamples;
      property LODDistanceOffset: Single read fLODDistanceOffset;
      property LODDistanceFactor: Single read fLODDistanceFactor;
      property SubdivisionCuts: Integer read fSubdivisionCuts;
      property SubdivisionDistance: Single read fSubdivisionDistance;
      property BufferSizeX: Integer read fBufferSizeX;
      property BufferSizeY: Integer read fBufferSizeY;
      property MaxShadowPasses: Integer read fMaxShadowPasses;
      property AutoplantDistance: Single read fAutoplantDistance;
      property AutoplantCount: Integer read fAutoplantCount;
      property TerrainTesselationDistance: Single read fTerrainTesselationDistance;
      property TerrainDetailDistance: Single read fTerrainDetailDistance;
      property TerrainBumpmapDistance: Single read fTerrainBumpmapDistance;
      property MotionBlurStrength: Single read fMotionBlurStrength;
      property FocusDistance: Single read fFocusDistance;
      property Frustum: TFrustum read fFrustum;
      property TransparencyMask: TTexture read fTransparencyMask;
      property ShadowSize: Single read fShadowSize;
      property ShadowOffset: TVector3D read fShadowOffset;
      procedure PostInit;
      procedure Unload;
      procedure RenderScene;
      procedure CheckModConf;
      function GetRay(MX, MY: Single): TVector3D;
      constructor Create;
      destructor Free;
    end;

implementation

uses
  m_varlist, u_events, main, m_renderer_owe_water;

procedure TModuleRendererOWE.PostInit;
var
  ResX, ResY: Integer;
begin
  fTransparencyMask := TTexture.Create;
  fTransparencyMask.FromFile('orcf-world-engine/inferred/transparency-gradient.tga');
  fTransparencyMask.SetFilter(GL_LINEAR, GL_LINEAR);

  fLensFlareMask := TTexture.Create;
  fLensFlareMask.FromFile('orcf-world-engine/postprocess/images/lensflare.tga');
//   fLensFlareMask.CreateMipmaps;
  fLensFlareMask.SetFilter(GL_LINEAR, GL_LINEAR);

  ModuleManager.ModGLContext.GetResolution(ResX, ResY);
  fBufferSizeX := ResX * FSAASamples;
  fBufferSizeY := ResY * FSAASamples;

  fGBuffer := TFBO.Create(BufferSizeX, BufferSizeY, true);
  fGBuffer.AddTexture(GL_RGBA, GL_NEAREST, GL_NEAREST);         // Materials (opaque only) and specularity
  fGBuffer.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);
  fGBuffer.AddTexture(GL_RGBA16F_ARB, GL_NEAREST, GL_NEAREST);  // Normals and specular hardness
  fGBuffer.Textures[1].SetClamp(GL_CLAMP, GL_CLAMP);
  fGBuffer.AddTexture(GL_RGBA32F_ARB, GL_NEAREST, GL_NEAREST);  // Vertex and depth
  fGBuffer.Textures[2].SetClamp(GL_CLAMP, GL_CLAMP);

  fSpareBuffer := TFBO.Create(BufferSizeX, BufferSizeY, false);
  fSpareBuffer.AddTexture(GL_RGBA, GL_NEAREST, GL_NEAREST);     // Materials (opaque only) and specularity
  fSpareBuffer.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);

  fLightBuffer := TFBO.Create(BufferSizeX, BufferSizeY, false);
  fLightBuffer.AddTexture(GL_RGBA16F_ARB, GL_NEAREST, GL_NEAREST);// Colors, Specular
  fLightBuffer.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);

  fSceneBuffer := TFBO.Create(BufferSizeX, BufferSizeY, true);
  fSceneBuffer.AddTexture(GL_RGB, GL_NEAREST, GL_NEAREST);      // Composed image
  fSceneBuffer.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);

  if UseScreenSpaceAmbientOcclusion then
    begin
    fSSAOBuffer := TFBO.Create(Round(ResX * ShadowBufferSamples), Round(ResY * ShadowBufferSamples), false);
    fSSAOBuffer.AddTexture(GL_RGB, GL_LINEAR, GL_LINEAR);     // Screen Space Ambient Occlusion
    fSSAOBuffer.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);
    end
  else
    fSSAOBuffer := nil;

  if UseBloom then
    begin
    fBloomBuffer := TFBO.Create(Round(ResX * ShadowBufferSamples), Round(ResY * ShadowBufferSamples), false);
    fBloomBuffer.AddTexture(GL_RGB, GL_LINEAR, GL_LINEAR);    // Pseudo-HDR/Color Bleeding
    fBloomBuffer.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);
    end
  else
    fBloomBuffer := nil;

  if UseFocalBlur then
    begin
    fFocalBlurBuffer := TFBO.Create(BufferSizeX, BufferSizeY, false);
    fFocalBlurBuffer.AddTexture(GL_RGB, GL_LINEAR, GL_LINEAR); // Focal blur
    fFocalBlurBuffer.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);
    end
  else
    fFocalBlurBuffer := nil;

  if UseSunRays then
    begin
    fSunRayBuffer := TFBO.Create(Round(ResX * ShadowBufferSamples), Round(ResY * ShadowBufferSamples), false);
    fSunRayBuffer.AddTexture(GL_RGBA, GL_LINEAR, GL_LINEAR);  // Color overlay
    fSunRayBuffer.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);
    end
  else
    fSunRayBuffer := nil;

  if UseBloom then
    begin
    fTmpBloomBuffer := TFBO.Create(Round(ResX * ShadowBufferSamples), Round(ResY * ShadowBufferSamples), true);
    fTmpBloomBuffer.AddTexture(GL_RGB, GL_LINEAR, GL_LINEAR);
    fTmpBloomBuffer.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);
    end
  else
    fTmpBloomBuffer := nil;

  if UseMotionBlur then
    begin
    fMotionBlurBuffer := TFBO.Create(ResX, ResY, false);
    fMotionBlurBuffer.AddTexture(GL_RGBA, GL_NEAREST, GL_NEAREST);
    fMotionBlurBuffer.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);
    end
  else
    fMotionBlurBuffer := nil;

  if UseSunShadows then
    begin
    fSunShadowBuffer := TFBO.Create(Round(2048 * ShadowBufferSamples), Round(2048 * ShadowBufferSamples), true);
    fSunShadowBuffer.AddTexture(GL_RGBA32F_ARB, GL_LINEAR, GL_LINEAR);
    fSunShadowBuffer.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);
    end
  else
    fSunShadowBuffer := nil;

  if UseLightShadows then
    begin
    fTmpShadowBuffer := TFBO.Create(Round(1536 * ShadowBufferSamples), Round(1024 * ShadowBufferSamples), true);
    fTmpShadowBuffer.AddTexture(GL_RGBA32F_ARB, GL_LINEAR, GL_LINEAR);
    fTmpShadowBuffer.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);
    end
  else
    fTmpShadowBuffer := nil;

  fLightManager := TLightManager.Create;
  fRendererCamera := TRCamera.Create;
  fRendererSky := TRSky.Create;
  fRendererTerrain := TRTerrain.Create;
  fRendererAutoplants := TRAutoplants.Create;

  fFullscreenShader := TShader.Create('orcf-world-engine/postprocess/fullscreen.vs', 'orcf-world-engine/postprocess/fullscreen.fs');
  fFullscreenShader.UniformI('Texture', 0);

  fAAShader := TShader.Create('orcf-world-engine/postprocess/fullscreen.vs', 'orcf-world-engine/postprocess/fsaa.fs');
  fAAShader.UniformI('Texture', 0);
  fAAShader.UniformI('ScreenSize', ResX, ResY);
  fAAShader.UniformI('Samples', FSAASamples);

  fSunRayShader := TShader.Create('orcf-world-engine/postprocess/sunrays.vs', 'orcf-world-engine/postprocess/sunrays.fs');
  fSunRayShader.UniformI('MaterialTexture', 0);
  fSunRayShader.UniformI('NormalTexture', 1);
  fSunRayShader.UniformF('exposure', 0.0014);
  fSunRayShader.UniformF('decay', 1.0);
  fSunRayShader.UniformF('density', 0.5);
  fSunRayShader.UniformF('weight', 5.2);

  fSunShader := TShader.Create('orcf-world-engine/postprocess/fullscreen.vs', 'orcf-world-engine/inferred/sun.fs');
  fSunShader.UniformI('GeometryTexture', 0);
  fSunShader.UniformI('NormalTexture', 1);
  fSunShader.UniformI('ShadowTexture', 2);

  fCompositionShader := TShader.Create('orcf-world-engine/postprocess/fullscreen.vs', 'orcf-world-engine/postprocess/composition.fs');
  fCompositionShader.UniformI('MaterialTexture', 0);
  fCompositionShader.UniformI('LightTexture', 1);
  fCompositionShader.UniformI('GTexture', 2);

  fLensFlareShader := TShader.Create('orcf-world-engine/postprocess/lensflare.vs', 'orcf-world-engine/postprocess/lensflare.fs');
  fLensFlareShader.UniformI('Texture', 0);
  fLensFlareShader.UniformI('GeometryTexture', 1);
  fLensFlareShader.UniformF('AspectRatio', ResY / ResX, 1);

  fBloomShader := TShader.Create('orcf-world-engine/postprocess/fullscreen.vs', 'orcf-world-engine/postprocess/bloom.fs');
  fBloomShader.UniformI('Tex', 0);

  fBloomBlurShader := TShader.Create('orcf-world-engine/postprocess/fullscreen.vs', 'orcf-world-engine/postprocess/blur.fs');
  fBloomBlurShader.UniformI('Tex', 0);

  fFocalBlurShader := TShader.Create('orcf-world-engine/postprocess/fullscreen.vs', 'orcf-world-engine/postprocess/focalblur.fs');
  fFocalBlurShader.UniformI('SceneTexture', 0);
  fFocalBlurShader.UniformI('GeometryTexture', 1);

  fShadowDepthShader := TShader.Create('orcf-world-engine/postprocess/fullscreen.vs', 'orcf-world-engine/inferred/shadowDepth.fs');
  fShadowDepthShader.UniformI('AdvanceSamples', Round(FSAASamples / ShadowBufferSamples));
  fShadowDepthShader.UniformI('GeometryTexture', 0);

  fBlackShader := TShader.Create('orcf-world-engine/postprocess/fullscreen.vs', 'orcf-world-engine/inferred/black.fs');
  fBlackShader.Unbind;

  fFrustum := TFrustum.Create;
end;

procedure TModuleRendererOWE.Unload;
var
  i: Integer;
begin
  fFrustum.Free;

  fBlackShader.Free;
  fShadowDepthShader.Free;
  fFocalBlurShader.Free;
  fBloomBlurShader.Free;
  fBloomShader.Free;
  fLensFlareShader.Free;
  fCompositionShader.Free;
  fSunShader.Free;
  fSunRayShader.Free;
  fAAShader.Free;
  fFullscreenShader.Free;

  fGBuffer.Free;
  fSpareBuffer.Free;
  fLightBuffer.Free;
  fSceneBuffer.Free;
  if fSSAOBuffer <> nil then
    fSSAOBuffer.Free;
  if fBloomBuffer <> nil then
    fBloomBuffer.Free;
  if fSunRayBuffer <> nil then
    fSunRayBuffer.Free;
  if fTmpBloomBuffer <> nil then
    fTmpBloomBuffer.Free;
  if fFocalBlurBuffer <> nil then
    fFocalBlurBuffer.Free;
  if fMotionBlurBuffer <> nil then
    fMotionBlurBuffer.Free;
  if fSunShadowBuffer <> nil then
    fSunShadowBuffer.Free;
  if fTmpShadowBuffer <> nil then
    fTmpShadowBuffer.Free;

  fRendererAutoplants.Free;
  fRendererTerrain.Free;
  fRendererSky.Free;
  fRendererCamera.Free;
  fLightManager.Free;

  fLensFlareMask.Free;
  fTransparencyMask.Free;
end;

function TModuleRendererOWE.GetRay(MX, MY: Single): TVector3D;
var
  pmatrix: TMatrix;
  VecLeft, VecUp: TVector3D;
begin
  glGetFloatv(GL_PROJECTION_MATRIX, @pmatrix[0]);

  VecLeft := Normal(fVecToFront, Vector(0, 1, 0));
  VecUp := Normal(VecLeft, fVecToFront);
  Result := normalize(fVecToFront + VecUp * (MY / pMatrix[5]) + VecLeft * (MX / pMatrix[0]));
end;

procedure TModuleRendererOWE.RenderScene;
var
  LensFlareFactor: Single;

  procedure DrawFullscreenQuad;
  begin
    glBegin(GL_QUADS);
      glVertex2f(-1, -1);
      glVertex2f( 1, -1);
      glVertex2f( 1,  1);
      glVertex2f(-1,  1);
    glEnd;
  end;

  procedure RenderLensFlare;
  begin
    glBegin(GL_QUADS);
      glColor4f(RSky.Sun.Color.X, RSky.Sun.Color.Y, RSky.Sun.Color.Z, 0.04 * LensFlareFactor);
      glVertex3f(-1, -1, 0.1); glVertex3f( 1, -1, 0.1); glVertex3f( 1,  1, 0.1); glVertex3f(-1,  1, 0.1);

      glVertex3f(-1, -1, 0.20); glVertex3f( 1, -1, 0.20); glVertex3f( 1,  1, 0.20); glVertex3f(-1,  1, 0.20);
      glVertex3f(-1, -1, 0.21); glVertex3f( 1, -1, 0.21); glVertex3f( 1,  1, 0.21); glVertex3f(-1,  1, 0.21);

      glVertex3f(-1, -1, 0.45); glVertex3f( 1, -1, 0.45); glVertex3f( 1,  1, 0.45); glVertex3f(-1,  1, 0.45);
      glVertex3f(-1, -1, 0.46); glVertex3f( 1, -1, 0.46); glVertex3f( 1,  1, 0.46); glVertex3f(-1,  1, 0.46);
      glVertex3f(-1, -1, 0.47); glVertex3f( 1, -1, 0.47); glVertex3f( 1,  1, 0.47); glVertex3f(-1,  1, 0.47);
      glVertex3f(-1, -1, 0.48); glVertex3f( 1, -1, 0.48); glVertex3f( 1,  1, 0.48); glVertex3f(-1,  1, 0.48);

      glVertex3f(-1, -1, 0.80); glVertex3f( 1, -1, 0.80); glVertex3f( 1,  1, 0.80); glVertex3f(-1,  1, 0.80);
      glVertex3f(-1, -1, 0.82); glVertex3f( 1, -1, 0.82); glVertex3f( 1,  1, 0.82); glVertex3f(-1,  1, 0.82);
      glVertex3f(-1, -1, 0.84); glVertex3f( 1, -1, 0.84); glVertex3f( 1,  1, 0.84); glVertex3f(-1,  1, 0.84);
      glVertex3f(-1, -1, 0.86); glVertex3f( 1, -1, 0.86); glVertex3f( 1,  1, 0.86); glVertex3f(-1,  1, 0.86);
      glVertex3f(-1, -1, 0.88); glVertex3f( 1, -1, 0.88); glVertex3f( 1,  1, 0.88); glVertex3f(-1,  1, 0.88);
      glVertex3f(-1, -1, 0.90); glVertex3f( 1, -1, 0.90); glVertex3f( 1,  1, 0.90); glVertex3f(-1,  1, 0.90);
      glVertex3f(-1, -1, 0.92); glVertex3f( 1, -1, 0.92); glVertex3f( 1,  1, 0.92); glVertex3f(-1,  1, 0.92);
      glVertex3f(-1, -1, 0.94); glVertex3f( 1, -1, 0.94); glVertex3f( 1,  1, 0.94); glVertex3f(-1,  1, 0.94);

      glColor4f(1, 1, 0.5, 0.04 * LensFlareFactor);
      glVertex3f(-1, -1, 1.40); glVertex3f( 1, -1, 1.40); glVertex3f( 1,  1, 1.40); glVertex3f(-1,  1, 1.40);
      glVertex3f(-1, -1, 1.43); glVertex3f( 1, -1, 1.43); glVertex3f( 1,  1, 1.43); glVertex3f(-1,  1, 1.43);
      glVertex3f(-1, -1, 1.46); glVertex3f( 1, -1, 1.46); glVertex3f( 1,  1, 1.46); glVertex3f(-1,  1, 1.46);
      glVertex3f(-1, -1, 1.49); glVertex3f( 1, -1, 1.49); glVertex3f( 1,  1, 1.49); glVertex3f(-1,  1, 1.49);

      glColor4f(1, 0.5, 0.5, 0.04 * LensFlareFactor);
      glVertex3f(-1, -1, 1.70); glVertex3f( 1, -1, 1.70); glVertex3f( 1,  1, 1.70); glVertex3f(-1,  1, 1.70);
      glVertex3f(-1, -1, 1.74); glVertex3f( 1, -1, 1.74); glVertex3f( 1,  1, 1.74); glVertex3f(-1,  1, 1.74);
      glVertex3f(-1, -1, 1.78); glVertex3f( 1, -1, 1.78); glVertex3f( 1,  1, 1.78); glVertex3f(-1,  1, 1.78);
      glVertex3f(-1, -1, 1.82); glVertex3f( 1, -1, 1.82); glVertex3f( 1,  1, 1.82); glVertex3f(-1,  1, 1.82);
    glEnd;
  end;
var
  MX, MY: Single;
  ResX, ResY: Integer;
  Coord: TVector4D;
begin
  ModuleManager.ModGLContext.GetResolution(ResX, ResY);

  // Set up camera

  glMatrixMode(GL_PROJECTION);
  ModuleManager.ModGLMng.SetUp3DMatrix;
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;

  RSky.Advance;
  glLoadIdentity;
  RSky.Sun.Bind(0);

  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT);

  glLoadIdentity;
  RCamera.ApplyRotation(Vector(1, 1, 1));
  RCamera.ApplyTransformation(Vector(1, 1, 1));

  // Do some scene preparation

  Frustum.Calculate;

  RAutoplants.Update;

  // Check some visibilities

  RTerrain.CheckVisibility;

  // Geometry pass

  // Opaque parts only
  GBuffer.Bind;
    glDisable(GL_BLEND);
    glDepthMask(true);
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LESS);
    glEnable(GL_CULL_FACE);

    // Sky
    RSky.Render;

    // Terrain

    RTerrain.CurrentShader := RTerrain.GeometryPassShader;
    RTerrain.Render;

    glDisable(GL_CULL_FACE);
  GBuffer.Unbind;

  // Save material buffer
  SpareBuffer.Bind;
    GBuffer.Textures[0].Bind;
    fFullscreenShader.Bind;
    DrawFullscreenQuad;
    fFullscreenShader.Unbind;
  SpareBuffer.Unbind;

  // SSAO pass

  if UseScreenSpaceAmbientOcclusion then
    begin
    glDisable(GL_BLEND);
    SSAOBuffer.Bind;
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT);
    SSAOBuffer.Unbind;
    end;

  // Transparent parts, fuck up the material buffer
  GBuffer.Bind;
    fTransparencyMask.Bind(7);

    glEnable(GL_ALPHA_TEST);
    glAlphaFunc(GL_GREATER, 0.0);
    glColorMask(true, true, true, false);

    // Autoplants
    RAutoplants.CurrentShader := RAutoplants.GeometryPassShader;
    RAutoplants.Render;


    // End

    glColorMask(true, true, true, true);
    glDisable(GL_DEPTH_TEST);
    glDepthMask(false);
    glDisable(GL_ALPHA_TEST);

  GBuffer.Unbind;

  // Lighting pass
  if UseSunShadows then
    begin
    fShadowOffset := ModuleManager.ModCamera.ActiveCamera.Position;
    fShadowSize := 50 + 2 * (fShadowOffset.Y - RTerrain.GetBlock(fShadowOffset.X, fShadowOffset.Z).MinHeight);
    fShadowOffset.Y := 0.5 * (fShadowOffset.Y + RTerrain.GetBlock(fShadowOffset.X, fShadowOffset.Z).MinHeight);

    fSunShadowBuffer.Bind;
    glDepthMask(true);
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_ALPHA_TEST);
    glAlphaFunc(GL_GREATER, 0.0);
    glDisable(GL_BLEND);

    glClearColor(0.0, 0.0, 0.0, 0.0);
    glClear(GL_DEPTH_BUFFER_BIT or GL_COLOR_BUFFER_BIT or GL_STENCIL_BUFFER_BIT);
    glClearColor(1.0, 1.0, 1.0, 1.0);

    RTerrain.CurrentShader := RTerrain.ShadowPassShader;
    RTerrain.CurrentShader.UniformF('ShadowSize', ShadowSize);
    RTerrain.CurrentShader.UniformF('ShadowOffset', ShadowOffset.X, ShadowOffset.Y, ShadowOffset.Z);
    RTerrain.Render;

    fSunShadowBuffer.Unbind;
    end;

  LightBuffer.Bind;
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT);

    glDisable(GL_ALPHA_TEST);
    glDisable(GL_BLEND);

    if UseSunShadows then
      fSunShadowBuffer.Textures[0].Bind(2);

    GBuffer.Textures[1].Bind(1);
    GBuffer.Textures[2].Bind(0);

    SunShader.Bind;
    SunShader.UniformF('ShadowSize', ShadowSize);
    SunShader.UniformF('ShadowOffset', ShadowOffset.X, ShadowOffset.Y, ShadowOffset.Z);
    SunShader.UniformI('BlurSamples', ShadowBlurSamples);
    DrawFullscreenQuad;
    SunShader.Unbind;
  LightBuffer.Unbind;

  // Sun ray pass

  if UseSunRays then
    begin
    glDisable(GL_BLEND);
    SunRayBuffer.Bind;
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT);

    GBuffer.Textures[1].Bind(1);
    SpareBuffer.Textures[0].Bind(0);

    fSunRayShader.Bind;
    fSunRayShader.UniformF('VecToFront', fVecToFront.X, fVecToFront.Y, fVecToFront.Z);;
    DrawFullscreenQuad;
    fSunRayShader.Unbind;

    SunRayBuffer.Unbind;
    end;

  // Composition

  fSceneBuffer.Bind;
    glDepthMask(true);
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LEQUAL);
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT);

    CompositionShader.Bind;

    GBuffer.Textures[2].Bind(2);
    LightBuffer.Textures[0].Bind(1);
    SpareBuffer.Textures[0].Bind(0);
    DrawFullscreenQuad;

    CompositionShader.Unbind;

    // Transparent parts only

    LightBuffer.Textures[0].Bind(7);

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);


    RAutoplants.CurrentShader := RAutoplants.MaterialPassShader;
    RAutoplants.Render;

    glDisable(GL_BLEND);

    glDisable(GL_DEPTH_TEST);
    glDepthMask(false);

  fSceneBuffer.Unbind;

  GBuffer.Bind;
    // Get depth under mouse
    fFullscreenShader.Bind;
    GBuffer.Textures[2].Bind(0);
    DrawFullscreenQuad;
    glReadPixels(ModuleManager.ModInputHandler.MouseX * FSAASamples, (ResY - ModuleManager.ModInputHandler.MouseY) * FSAASamples, 1, 1, GL_RGBA, GL_FLOAT, @Coord.X);
    fFullscreenShader.Unbind;
  GBuffer.Unbind;

  // Set up selection rays

  with ModuleManager.ModCamera do
    fVecToFront := Normalize(Vector(Sin(DegToRad(ActiveCamera.Rotation.Y)) * Cos(DegToRad(ActiveCamera.Rotation.X)),
                                   -Sin(DegToRad(ActiveCamera.Rotation.X)),
                                   -Cos(DegToRad(ActiveCamera.Rotation.Y)) * Cos(DegToRad(ActiveCamera.Rotation.X))));

  fSelectionStart := ModuleManager.ModCamera.ActiveCamera.Position;

  fSelectionRay := Vector3D(Coord) - fSelectionStart;
  fFocusDistance := Coord.W;

  // Focal Blur pass

  if UseFocalBlur then
    begin
    glDisable(GL_BLEND);

    FocalBlurBuffer.Bind;
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT);

    // Copy image to focal blur buffer

    glColor4f(1, 1, 1, 1);
    SceneBuffer.Textures[0].Bind(0);

    fFullscreenShader.Bind;
    DrawFullscreenQuad;
    fFullscreenShader.Unbind;

    FocalBlurBuffer.Unbind;

    // Apply effect

    SceneBuffer.Bind;

    GBuffer.Textures[2].Bind(1);
    FocalBlurBuffer.Textures[0].Bind(0);

    fFocalBlurShader.Bind;
    fFocalBlurShader.UniformF('FocusDistance', FocusDistance);
    fFocalBlurShader.UniformF('Screen', ResX, ResY);
    fFocalBlurShader.UniformF('Strength', 1.0);
    DrawFullscreenQuad;
    fFocalBlurShader.Unbind;

    SceneBuffer.Unbind;
    end;

    // Apply sun ray effect to the image

  if UseSunRays then
    begin
    SceneBuffer.Bind;

    fFullscreenShader.Bind;

    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE);
    glColor4f(1, 1, 1, 1);
    SunRayBuffer.Textures[0].Bind(0);
    DrawFullscreenQuad;
    glDisable(GL_BLEND);

    fFullscreenShader.Unbind;

    SceneBuffer.Unbind;
    end;

  // Bloom pass

  if UseBloom then
    begin
    glDisable(GL_BLEND);

    BloomBuffer.Bind;

    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT);

    fBloomShader.Bind;
    fSceneBuffer.Textures[0].Bind(0);
    DrawFullscreenQuad;
    fBloomShader.Unbind;

    BloomBuffer.Unbind;

    fBloomBlurShader.Bind;

    // Abuse shadow buffer here for blurring - possible because it is the same size
    fBloomBlurShader.UniformF('BlurDirection', 1.0 / BloomBuffer.Width, 0.0);
    BloomBuffer.Textures[0].Bind(0);

    fTmpBloomBuffer.Bind;
    DrawFullscreenQuad;
    fTmpBloomBuffer.Unbind;

    //...and use the bloom buffer again
    fBloomBlurShader.UniformF('BlurDirection', 0.0, 1.0 / BloomBuffer.Height);
    fTmpBloomBuffer.Textures[0].Bind(0);

    BloomBuffer.Bind;
    DrawFullscreenQuad;
    BloomBuffer.Unbind;

    fBloomBlurShader.Unbind;

    // Apply bloom to scene image
    fSceneBuffer.Bind;

    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE);
    glColor4f(0.3, 0.3, 0.3, 1.0);

    fBloomBuffer.Textures[0].Bind(0);

    fFullscreenShader.Bind;
    DrawFullscreenQuad;
    fFullscreenShader.Unbind;

    fSceneBuffer.Unbind;

    glDisable(GL_BLEND);
    end;


  // Output

  if UseMotionBlur then
    begin
    // Render output to MB buffer
    MotionBlurBuffer.Bind;
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    fAAShader.Bind;

    glColor4f(1, 1, 1, 1 - power(2.7183, -(FPSDisplay.MS * fMotionBlurStrength)));
    fSceneBuffer.Textures[0].Bind(0);
    DrawFullscreenQuad;

    fAAShader.Unbind;

    glDisable(GL_BLEND);
    MotionBlurBuffer.Unbind;

    // Render new buffer contents
    glColor4f(1, 1, 1, 1);
    fFullscreenShader.Bind;

    MotionBlurBuffer.Textures[0].Bind(0);
    DrawFullscreenQuad;

    fFullscreenShader.Unbind;
    end
  else
    begin
    fAAShader.Bind;

    glColor4f(1, 1, 1, 1);
    fSceneBuffer.Textures[0].Bind(0);
    DrawFullscreenQuad;

    fAAShader.Unbind;
    end;

  if UseLensFlare then
    begin
    // And finally add some lens flare

    LensFlareFactor := Clamp(5 * DotProduct(Normalize(fVecToFront), Normalize(Vector3D(RSky.Sun.Position) - ModuleManager.ModCamera.ActiveCamera.Position)), 0, 1);

    glDisable(GL_ALPHA_TEST);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    fLensFlareShader.Bind;
    fLensFlareMask.Bind(0);
    GBuffer.Textures[2].Bind(1);
    RenderLensFlare;
    fLensFlareShader.Unbind;
    end;

  glDisable(GL_BLEND);
end;

procedure TModuleRendererOWE.CheckModConf;
begin
  if GetConfVal('used') <> '1' then
    begin
    SetConfVal('used', '1');
    SetConfVal('samples', '4');
    SetConfVal('reflections.depth', '2');
    SetConfVal('reflections.updateinterval', '1');
    SetConfVal('ssao', '1');
    SetConfVal('ssao.samples', '100');
    SetConfVal('refractions', '1');
    SetConfVal('shadows', '2');
    SetConfVal('shadows.samples', '1');
    SetConfVal('shadows.blursamples', '5');
    SetConfVal('shadows.maxpasses', '2');
    SetConfVal('bloom', '1');
    SetConfVal('focalblur', '1');
    SetConfVal('motionblur', '1');
    SetConfVal('motionblur.strength', '0.05');
    SetConfVal('sunrays', '1');
    SetConfVal('lod.distanceoffset', '0');
    SetConfVal('lod.distancefactor', '1');
    SetConfVal('subdiv.cuts', '2');
    SetConfVal('subdiv.distance', '10');
    SetConfVal('terrain.tesselationdistance', '25');
    SetConfVal('terrain.detaildistance', '100');
    SetConfVal('terrain.bumpmapdistance', '60');
    SetConfVal('autoplants.distance', '30');
    SetConfVal('autoplants.count', '9000');
    SetConfVal('lensflare', '1');
    SetConfVal('water.samples', '1');
    end;
  fFSAASamples := StrToIntWD(GetConfVal('samples'), 4);
  fReflectionDepth := StrToIntWD(GetConfVal('reflections.depth'), 2);
  fReflectionUpdateInterval := StrToIntWD(GetConfVal('reflections.updateinterval'), 1);
  fUseSunShadows := GetConfVal('shadows') <> '0';
  fUseLightShadows := GetConfVal('shadows') = '2';
  fUseBloom := GetConfVal('bloom') = '1';
  fUseRefractions := GetConfVal('refractions') = '1';
  fUseMotionBlur := GetConfVal('motionblur') = '1';
  fUseSunRays := GetConfVal('bloom') = '1';
  fUseFocalBlur := GetConfVal('focalblur') = '1';
  fUseScreenSpaceAmbientOcclusion := GetConfVal('ssao') = '1';
  fUseLensFlare := GetConfVal('lensflare') = '1';
  fShadowBufferSamples := StrToFloatWD(GetConfVal('shadows.samples'), 1);
  fShadowBlurSamples := StrToIntWD(GetConfVal('shadows.blursamples'), 5);
  fMaxShadowPasses := StrToIntWD(GetConfVal('shadows.maxpasses'), 2);
  fMotionBlurStrength := StrToFloatWD(GetConfVal('motionblur.strength'), 0.05);
  fTerrainTesselationDistance := StrToFloatWD(GetConfVal('terrain.tesselationdistance'), 25);
  fTerrainDetailDistance := StrToFloatWD(GetConfVal('terrain.detaildistance'), 100);
  fTerrainBumpmapDistance := StrToFloatWD(GetConfVal('terrain.bumpmapdistance'), 60);
  fWaterReflectionBufferSamples := StrToFloatWD(GetConfVal('water.samples'), 1);
  fSSAOSamples := StrToIntWD(GetConfVal('ssao.samples'), 100);
  fLODDistanceOffset := StrToIntWD(GetConfVal('lod.distanceoffset'), 0);
  fLODDistanceFactor := StrToIntWD(GetConfVal('lod.distancefactor'), 1);
  fSubdivisionCuts := StrToIntWD(GetConfVal('subdiv.cuts'), 2);
  fSubdivisionDistance := StrToIntWD(GetConfVal('subdiv.distance'), 10);
  fAutoplantCount := StrToIntWD(GetConfVal('autoplants.count'), 9000);
  fAutoplantDistance := StrToFloatWD(GetConfVal('autoplants.distance'), 30);
end;

constructor TModuleRendererOWE.Create;
begin
  fModName := 'RendererOWE';
  fModType := 'Renderer';
end;

destructor TModuleRendererOWE.Free;
begin
end;

end.