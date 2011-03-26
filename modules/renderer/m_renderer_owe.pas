unit m_renderer_owe;

interface

uses
  Classes, SysUtils, m_renderer_class, DGLOpenGL, g_park, u_math, u_vectors,
  m_renderer_owe_camera, math, m_texmng_class, m_shdmng_class, u_functions, m_renderer_owe_frustum,
  m_renderer_owe_sky, m_renderer_owe_classes, u_scene, m_renderer_owe_lights, m_renderer_owe_terrain,
  m_renderer_owe_autoplants, m_renderer_owe_water, m_renderer_owe_objects, m_renderer_owe_cubemaps,
  m_renderer_owe_renderpass, u_files, u_graphics, m_gui_class, m_renderer_owe_config, m_settings_class;

type
  TModuleRendererOWE = class(TModuleRendererClass)
    protected
      fOWEConfigInterface: TOWEConfigInterface;
      fRendererSky: TRSky;
      fRendererCamera: TRCamera;
      fRendererTerrain: TRTerrain;
      fRendererAutoplants: TRAutoplants;
      fRendererObjects: TRObjects;
      fRendererWater: TRWater;
      fLightManager: TLightManager;
      fGBuffer, fHDRBuffer, fHDRBuffer2, fLightBuffer, fSceneBuffer, fSSAOBuffer, fSunRayBuffer, fBloomBuffer, fFocalBlurBuffer, fMotionBlurBuffer, fSpareBuffer, fSunShadowBuffer, fTmpShadowBuffer: TFBO;
      fFSAASamples: Integer;
      fReflectionRealtimeMinimum, fReflectionRealtimeDistanceExponent: Single;
      fReflectionRenderTerrain, fReflectionRenderAutoplants, fReflectionRenderObjects, fReflectionRenderParticles: Boolean;
      fReflectionUpdateInterval: Integer;
      fReflectionSize, fEnvMapSize: Integer;
      fUseSunShadows, fUseLightShadows, fUseSunRays, fUseRefractions: Boolean;
      fUseScreenSpaceAmbientOcclusion, fUseMotionBlur, fUseFocalBlur: Boolean;
      fBloomFactor: Single;
      fLODDistanceOffset, fLODDistanceFactor, fMotionBlurStrength: Single;
      fReflectionRenderDistanceOffset, fReflectionRenderDistanceFactor: Single;
      fReflectionTerrainDetailDistance, fReflectionTerrainTesselationDistance, fReflectionTerrainBumpmapDistance: Single;
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
      fFullscreenShader, fBlackShader, fAAShader, fSunRayShader, fSunShader, fLightShader, fCompositionShader, fBloomShader, fBloomBlurShader, fFocalBlurShader, fShadowDepthShader, fLensFlareShader, fHDRAverageShader: TShader;
      fVecToFront: TVector3D;
      fFocusDistance: Single;
      fFrustum: TFrustum;
      fTransparencyMask, fLensFlareMask: TTexture;
      fShadowSize: Single;
      fShadowOffset: TVector3D;
      fUseLensFlare: Boolean;
      fWaterReflectionBufferSamples: Single;
      fFrameID: Integer;
      fGamma: Single;
      fFrontFace: GLEnum;
      fEnvironmentMap: TCubeMap;
      fEnvironmentPass: TRenderPass;
      fEnvironmentMapFrames, fEnvironmentMapInterval: Integer;
      fWaterReflectTerrain, fWaterReflectAutoplants, fWaterReflectObjects, fWaterReflectParticles, fWaterReflectSky: Boolean;
      fWaterRefractTerrain, fWaterRefractAutoplants, fWaterRefractObjects, fWaterRefractParticles: Boolean;
      fIsUnderWater: Boolean;
      fWaterHeight: Single;
      fUnderWaterShader: TShader;
      fSimpleShader: TShader;
      fMaxFogDistance: Single;
    public
      CurrentTerrainBumpmapDistance, CurrentTerrainDetailDistance, CurrentTerrainTesselationDistance: Single;
      CurrentLODDistanceFactor, CurrentLODDistanceOffset: Single;
      ViewPoint: TVector3D;
      MaxRenderDistance: Single;
      FogStrength, FogRefractMode: Single;
      FogColor: TVector3D;
      property LightManager: TLightManager read fLightManager;
      property RCamera: TRCamera read fRendererCamera;
      property RSky: TRSky read fRendererSky;
      property RTerrain: TRTerrain read fRendererTerrain;
      property RAutoplants: TRAutoplants read fRendererAutoplants;
      property RObjects: TRObjects read fRendererObjects;
      property RWater: TRWater read fRendererWater;
      property FullscreenShader: TShader read fFullscreenShader;
      property SunShader: TShader read fSunShader;
      property CompositionShader: TShader read fCompositionShader;
      property MotionBlurBuffer: TFBO read fMotionBlurBuffer;
      property FocalBlurBuffer: TFBO read fFocalBlurBuffer;
      property HDRAverageShader: TShader read fHDRAverageShader;
      property SimpleShader: TShader read fSimpleShader;
      property GBuffer: TFBO read fGBuffer;
      property HDRBuffer: TFBO read fHDRBuffer;
      property HDRBuffer2: TFBO read fHDRBuffer2;
      property LightBuffer: TFBO read fLightBuffer;
      property SceneBuffer: TFBO read fSceneBuffer;
      property SSAOBuffer: TFBO read fSSAOBuffer;
      property SunRayBuffer: TFBO read fSunRayBuffer;
      property BloomBuffer: TFBO read fBloomBuffer;
      property SpareBuffer: TFBO read fSpareBuffer;
      property SunShadowBuffer: TFBO read fSunShadowBuffer;
      property FSAASamples: Integer read fFSAASamples;
      property ReflectionUpdateInterval: Integer read fReflectionUpdateInterval;
      property EnvironmentMapInterval: Integer read fEnvironmentMapInterval;
      property ReflectionSize: Integer read fReflectionSize;
      property EnvMapSize: Integer read fEnvMapSize;
      property UseSunShadows: Boolean read fUseSunShadows;
      property UseLightShadows: Boolean read fUseLightShadows;
      property BloomFactor: Single read fBloomFactor;
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
      property ReflectionLODDistanceOffset: Single read fReflectionRenderDistanceOffset;
      property ReflectionLODDistanceFactor: Single read fReflectionRenderDistanceFactor;
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
      property ReflectionTerrainTesselationDistance: Single read fReflectionTerrainTesselationDistance;
      property ReflectionTerrainDetailDistance: Single read fReflectionTerrainDetailDistance;
      property ReflectionTerrainBumpmapDistance: Single read fReflectionTerrainBumpmapDistance;
      property ReflectionRenderTerrain: Boolean read fReflectionRenderTerrain;
      property ReflectionRenderObjects: Boolean read fReflectionRenderObjects;
      property ReflectionRenderParticles: Boolean read fReflectionRenderParticles;
      property ReflectionRenderAutoplants: Boolean read fReflectionRenderAutoplants;
      property ReflectionRealtimeMinimum: Single read fReflectionRealtimeMinimum;
      property ReflectionRealtimeDistanceExponent: Single read fReflectionRealtimeDistanceExponent;
      property WaterReflectTerrain: Boolean read fWaterReflectTerrain;
      property WaterReflectAutoplants: Boolean read fWaterReflectAutoplants;
      property WaterReflectObjects: Boolean read fWaterReflectObjects;
      property WaterReflectParticles: Boolean read fWaterReflectParticles;
      property WaterReflectSky: Boolean read fWaterReflectSky;
      property WaterRefractTerrain: Boolean read fWaterRefractTerrain;
      property WaterRefractAutoplants: Boolean read fWaterRefractAutoplants;
      property WaterRefractObjects: Boolean read fWaterRefractObjects;
      property WaterRefractParticles: Boolean read fWaterRefractParticles;
      property MotionBlurStrength: Single read fMotionBlurStrength;
      property FocusDistance: Single read fFocusDistance;
      property Frustum: TFrustum read fFrustum;
      property TransparencyMask: TTexture read fTransparencyMask;
      property ShadowSize: Single read fShadowSize;
      property ShadowOffset: TVector3D read fShadowOffset;
      property FrameID: Integer read fFrameID;
      property Gamma: Single read fGamma;
      property EnvironmentMap: TCubeMap read fEnvironmentMap;
      property MaxFogDistance: Single read fMaxFogDistance;
      procedure DynamicSettingsSetNormal;
      procedure DynamicSettingsSetReflection;
      procedure PostInit;
      procedure Unload;
      procedure RenderScene;
      procedure RenderMaxVisibilityQuad;
      procedure CheckModConf;
      procedure InvertFrontFace;
      procedure ApplyChanges(Event: String; Data, Result: Pointer);
      procedure CreateConfigInterface(Event: String; Data, Result: Pointer);
      procedure DestroyConfigInterface(Event: String; Data, Result: Pointer);
      function GetRay(MX, MY: Single): TVector3D;
      constructor Create;
      destructor Free;
    end;

implementation

uses
  m_varlist, u_events, main;

procedure TModuleRendererOWE.DynamicSettingsSetNormal;
begin
  CurrentLODDistanceFactor := LODDistanceFactor;
  CurrentLODDistanceOffset := LODDistanceOffset;
  CurrentTerrainBumpmapDistance := TerrainBumpmapDistance;
  CurrentTerrainDetailDistance := TerrainDetailDistance;
  CurrentTerrainTesselationDistance := TerrainTesselationDistance;
end;

procedure TModuleRendererOWE.DynamicSettingsSetReflection;
begin
  CurrentLODDistanceFactor := ReflectionLODDistanceFactor;
  CurrentLODDistanceOffset := ReflectionLODDistanceOffset;
  CurrentTerrainBumpmapDistance := ReflectionTerrainBumpmapDistance;
  CurrentTerrainDetailDistance := ReflectionTerrainDetailDistance;
  CurrentTerrainTesselationDistance := ReflectionTerrainTesselationDistance;
end;

procedure TModuleRendererOWE.PostInit;
var
  ResX, ResY: Integer;
begin
  fFrontFace := GL_CCW;

  fFrameID := 0;

  fTransparencyMask := TTexture.Create;
  fTransparencyMask.FromFile('orcf-world-engine/inferred/transparency-gradient.tga');
  fTransparencyMask.SetFilter(GL_LINEAR, GL_LINEAR);

  fLensFlareMask := TTexture.Create;
  fLensFlareMask.FromFile('orcf-world-engine/postprocess/images/lensflare.tga');
  fLensFlareMask.CreateMipmaps;
  fLensFlareMask.SetFilter(GL_LINEAR, GL_LINEAR);

  ModuleManager.ModGLContext.GetResolution(ResX, ResY);
  fBufferSizeX := ResX * FSAASamples;
  fBufferSizeY := ResY * FSAASamples;

  fGBuffer := TFBO.Create(BufferSizeX, BufferSizeY, true);
  fGBuffer.AddTexture(GL_RGBA16F_ARB, GL_NEAREST, GL_NEAREST);  // Materials (opaque only) and specularity
  fGBuffer.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);
  fGBuffer.AddTexture(GL_RGBA16F_ARB, GL_NEAREST, GL_NEAREST);  // Normals and specular hardness
  fGBuffer.Textures[1].SetClamp(GL_CLAMP, GL_CLAMP);
  fGBuffer.AddTexture(GL_RGBA32F_ARB, GL_NEAREST, GL_NEAREST);  // Vertex and depth
  fGBuffer.Textures[2].SetClamp(GL_CLAMP, GL_CLAMP);
  fGBuffer.AddTexture(GL_RGB, GL_NEAREST, GL_NEAREST);          // Transparency Material ID
  fGBuffer.Textures[3].SetClamp(GL_CLAMP, GL_CLAMP);

  fSpareBuffer := TFBO.Create(BufferSizeX, BufferSizeY, false);
  fSpareBuffer.AddTexture(GL_RGBA16F_ARB, GL_NEAREST, GL_NEAREST);     // Materials (opaque only) and specularity
  fSpareBuffer.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);

  fLightBuffer := TFBO.Create(BufferSizeX, BufferSizeY, false);
  fLightBuffer.AddTexture(GL_RGBA16F_ARB, GL_NEAREST, GL_NEAREST);     // Colors, Specular
  fLightBuffer.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);

  fSceneBuffer := TFBO.Create(BufferSizeX, BufferSizeY, true);
  fSceneBuffer.AddTexture(GL_RGB16F_ARB, GL_NEAREST, GL_NEAREST);      // Composed image
  fSceneBuffer.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);

  fHDRBuffer := TFBO.Create(BufferSizeX, 1, false);
  fHDRBuffer.AddTexture(GL_RGBA16F_ARB, GL_NEAREST, GL_NEAREST);

  fHDRBuffer2 := TFBO.Create(1, 1, false);
  fHDRBuffer2.AddTexture(GL_RGBA16F_ARB, GL_NEAREST, GL_NEAREST);

  if UseScreenSpaceAmbientOcclusion then
    begin
    fSSAOBuffer := TFBO.Create(Round(ResX * ShadowBufferSamples), Round(ResY * ShadowBufferSamples), false);
    fSSAOBuffer.AddTexture(GL_RGB, GL_LINEAR, GL_LINEAR);     // Screen Space Ambient Occlusion
    fSSAOBuffer.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);
    end
  else
    fSSAOBuffer := nil;

  if BloomFactor > 0 then
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

  if BloomFactor > 0 then
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
  fRendererObjects := TRObjects.Create;
  fRendererWater := TRWater.Create;

  fEnvironmentMap := TCubeMap.Create(EnvMapSize, EnvMapSize, GL_RGB16F_ARB);
  fEnvironmentPass := TRenderPass.Create(EnvMapSize, EnvMapSize);
  fEnvironmentPass.RenderAutoplants := False;
  fEnvironmentPass.RenderObjects := False;
  fEnvironmentPass.RenderParticles := False;

  fFullscreenShader := TShader.Create('orcf-world-engine/postprocess/fullscreen.vs', 'orcf-world-engine/postprocess/fullscreen.fs');
  fFullscreenShader.UniformI('Texture', 0);

  fHDRAverageShader := TShader.Create('orcf-world-engine/postprocess/fullscreen.vs', 'orcf-world-engine/postprocess/hdr.fs');
  fHDRAverageShader.UniformI('Texture', 0);

  fAAShader := TShader.Create('orcf-world-engine/postprocess/fullscreen.vs', 'orcf-world-engine/postprocess/fsaa.fs');
  fAAShader.UniformI('Texture', 0);
  fAAShader.UniformI('HDRColor', 1);
  fAAShader.UniformF('Gamma', Gamma);
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
  fSunShader.UniformI('MaterialTexture', 3);
  fSunShader.UniformI('HeightMap', 4);

  fCompositionShader := TShader.Create('orcf-world-engine/postprocess/fullscreen.vs', 'orcf-world-engine/postprocess/composition.fs');
  fCompositionShader.UniformI('MaterialTexture', 0);
  fCompositionShader.UniformI('LightTexture', 1);
  fCompositionShader.UniformI('GTexture', 2);
  fCompositionShader.UniformI('MaterialMap', 4);

  fLensFlareShader := TShader.Create('orcf-world-engine/postprocess/lensflare.vs', 'orcf-world-engine/postprocess/lensflare.fs');
  fLensFlareShader.UniformI('Texture', 0);
  fLensFlareShader.UniformI('GeometryTexture', 1);
  fLensFlareShader.UniformF('AspectRatio', ResY / ResX, 1);

  fBloomShader := TShader.Create('orcf-world-engine/postprocess/fullscreen.vs', 'orcf-world-engine/postprocess/bloom.fs');
  fBloomShader.UniformI('Tex', 0);
  fBloomShader.UniformI('HDRColor', 1);

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

  fUnderWaterShader := TShader.Create('orcf-world-engine/postprocess/underWater.vs', 'orcf-world-engine/postprocess/underWater.fs');
  fUnderWaterShader.UniformI('GeometryMap', 0);
  fUnderWaterShader.UniformI('RenderedScene', 1);
  fUnderWaterShader.Unbind;

  fSimpleShader := TShader.Create('orcf-world-engine/inferred/simple.vs', 'orcf-world-engine/inferred/simple.fs');
  fSimpleShader.Unbind;

  fFrustum := TFrustum.Create;

  fEnvironmentMapFrames := 0;
end;

procedure TModuleRendererOWE.Unload;
var
  i: Integer;
begin
  fFrustum.Free;

  fSimpleShader.Free;
  fUnderWaterShader.Free;
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
  fHDRAverageShader.Free;
  fFullscreenShader.Free;

  fEnvironmentPass.Free;
  fEnvironmentMap.Free;

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
  fHDRBuffer.Free;
  fHDRBuffer2.Free;

  fRendererWater.Free;
  fRendererObjects.Free;
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

procedure TModuleRendererOWE.RenderMaxVisibilityQuad;
begin
  glDisable(GL_CULL_FACE);
  fSimpleShader.Bind;
  glBegin(GL_QUADS);
    glVertex3f(-MaxRenderDistance,  MaxRenderDistance,  MaxRenderDistance);
    glVertex3f(-MaxRenderDistance, -MaxRenderDistance,  MaxRenderDistance);
    glVertex3f( MaxRenderDistance, -MaxRenderDistance,  MaxRenderDistance);
    glVertex3f( MaxRenderDistance,  MaxRenderDistance,  MaxRenderDistance);
    glVertex3f(-MaxRenderDistance,  MaxRenderDistance, -MaxRenderDistance);
    glVertex3f(-MaxRenderDistance, -MaxRenderDistance, -MaxRenderDistance);
    glVertex3f( MaxRenderDistance, -MaxRenderDistance, -MaxRenderDistance);
    glVertex3f( MaxRenderDistance,  MaxRenderDistance, -MaxRenderDistance);
    glVertex3f(-MaxRenderDistance, -MaxRenderDistance,  MaxRenderDistance);
    glVertex3f(-MaxRenderDistance, -MaxRenderDistance, -MaxRenderDistance);
    glVertex3f( MaxRenderDistance, -MaxRenderDistance, -MaxRenderDistance);
    glVertex3f( MaxRenderDistance, -MaxRenderDistance,  MaxRenderDistance);
    glVertex3f(-MaxRenderDistance,  MaxRenderDistance,  MaxRenderDistance);
    glVertex3f(-MaxRenderDistance,  MaxRenderDistance, -MaxRenderDistance);
    glVertex3f( MaxRenderDistance,  MaxRenderDistance, -MaxRenderDistance);
    glVertex3f( MaxRenderDistance,  MaxRenderDistance,  MaxRenderDistance);
    glVertex3f( MaxRenderDistance, -MaxRenderDistance,  MaxRenderDistance);
    glVertex3f( MaxRenderDistance, -MaxRenderDistance, -MaxRenderDistance);
    glVertex3f( MaxRenderDistance,  MaxRenderDistance, -MaxRenderDistance);
    glVertex3f( MaxRenderDistance,  MaxRenderDistance,  MaxRenderDistance);
    glVertex3f(-MaxRenderDistance, -MaxRenderDistance,  MaxRenderDistance);
    glVertex3f(-MaxRenderDistance, -MaxRenderDistance, -MaxRenderDistance);
    glVertex3f(-MaxRenderDistance,  MaxRenderDistance, -MaxRenderDistance);
    glVertex3f(-MaxRenderDistance,  MaxRenderDistance,  MaxRenderDistance);
  glEnd;
  fSimpleShader.Unbind;
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
      glColor4f(RSky.Sun.Color.X, RSky.Sun.Color.Y, RSky.Sun.Color.Z, 0.04 * LensFlareFactor * Power(0.5, 100.0 * FogStrength));
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

      glColor4f(1, 1, 0.5, 0.04 * LensFlareFactor * Power(0.5, 100.0 * FogStrength));
      glVertex3f(-1, -1, 1.40); glVertex3f( 1, -1, 1.40); glVertex3f( 1,  1, 1.40); glVertex3f(-1,  1, 1.40);
      glVertex3f(-1, -1, 1.43); glVertex3f( 1, -1, 1.43); glVertex3f( 1,  1, 1.43); glVertex3f(-1,  1, 1.43);
      glVertex3f(-1, -1, 1.46); glVertex3f( 1, -1, 1.46); glVertex3f( 1,  1, 1.46); glVertex3f(-1,  1, 1.46);
      glVertex3f(-1, -1, 1.49); glVertex3f( 1, -1, 1.49); glVertex3f( 1,  1, 1.49); glVertex3f(-1,  1, 1.49);

      glColor4f(1, 0.5, 0.5, 0.04 * LensFlareFactor * Power(0.5, 100.0 * FogStrength));
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
  FogStrength := RSky.FogStrength;
  FogRefractMode := 0;
  fMaxFogDistance := Log10(0.003) / (Log10(0.5) * FogStrength);
  
  MaxRenderDistance := MaxFogDistance;

  ViewPoint := ModuleManager.ModCamera.ActiveCamera.Position;

  fIsUnderWater := False;

  fWaterHeight := Park.pTerrain.WaterMap[ModuleManager.ModRenderer.ViewPoint.X, ModuleManager.ModRenderer.ViewPoint.Z];
  if ModuleManager.ModRenderer.ViewPoint.Y < fWaterHeight then
    begin
    fIsUnderWater := True;
    MaxRenderDistance := 55;
    end;

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
  RWater.Advance;

  RObjects.ShadowMode := False;

  RTerrain.BorderEnabled := True;

  if fIsUnderWater then
    MaxRenderDistance := 55
  else
    MaxRenderDistance := MaxFogDistance;

  ViewPoint := ModuleManager.ModCamera.ActiveCamera.Position;

  // Do water renderpasses
  RWater.RenderBuffers;

  // Create object reflections
  DynamicSettingsSetReflection;
    RTerrain.BorderEnabled := True;
    RObjects.RenderReflections;

    ViewPoint := ModuleManager.ModCamera.ActiveCamera.Position;

    if fEnvironmentMapFrames <= 0 then
      begin
      fEnvironmentMap.Render(fEnvironmentPass, ModuleManager.ModCamera.ActiveCamera.Position);
      fEnvironmentMapFrames := fEnvironmentMapInterval;
      end
    else
      dec(fEnvironmentMapFrames);

  DynamicSettingsSetNormal;

  ViewPoint := ModuleManager.ModCamera.ActiveCamera.Position;

  // Render final scene

  if fIsUnderWater then
    MaxRenderDistance := 55
  else
    MaxRenderDistance := MaxFogDistance;

  // Check some visibilities
  Frustum.Calculate;
//   RTerrain.CheckVisibility;
//   RObjects.CheckVisibility;

  // Geometry pass

  // Opaque parts only
  GBuffer.Bind;
    glDisable(GL_BLEND);
    glDepthMask(true);
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LESS);

    glDepthMask(false);
    RenderMaxVisibilityQuad;
    glDepthMask(true);
    
    glEnable(GL_CULL_FACE);

    // Sky
    RSky.Render;

    // Objects
    RObjects.RenderOpaque;

    // Terrain
    RTerrain.CurrentShader := RTerrain.GeometryPassShader;
    RTerrain.BorderEnabled := true;
    RTerrain.Render;

    // Water
    glColorMask(false, false, false, false);
    glDepthMask(false);
    RWater.Check;
    glDepthMask(true);
    glColorMask(true, true, true, true);
//   GBuffer.Unbind;

//   GBuffer.Bind;
    RWater.Render;

    glDisable(GL_CULL_FACE);
  GBuffer.Unbind;

  // Save material buffer
  SpareBuffer.Bind;
    GBuffer.Textures[0].Bind;
    fFullscreenShader.Bind;
    DrawFullscreenQuad;
    fFullscreenShader.Unbind;
    GBuffer.Textures[0].UnBind;
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
    glAlphaFunc(GL_NOTEQUAL, 0.0);
//     glColorMask(true, true, true, false);

    // Autoplants
    RAutoplants.CurrentShader := RAutoplants.GeometryPassShader;
    RAutoplants.Render;

    // Objects
    RObjects.MaterialMode := False;
    RObjects.RenderTransparent;

    // End

//     glColorMask(true, true, true, true);
    glDisable(GL_DEPTH_TEST);
    glDepthMask(false);
    glDisable(GL_ALPHA_TEST);

  GBuffer.Unbind;

  // Shadow pass
  
  if UseSunShadows then
    begin
    fShadowOffset := ModuleManager.ModCamera.ActiveCamera.Position;
    fShadowSize := 50 + 2 * (fShadowOffset.Y - RTerrain.GetBlock(fShadowOffset.X, fShadowOffset.Z).MinHeight);
    fShadowOffset.Y := 0.5 * (fShadowOffset.Y + RTerrain.GetBlock(fShadowOffset.X, fShadowOffset.Z).MinHeight);

    fSunShadowBuffer.Bind;
    glDepthMask(true);
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_ALPHA_TEST);
    glAlphaFunc(GL_NOTEQUAL, 0.0);
    glDisable(GL_BLEND);

    glClearColor(0.0, 0.0, 0.0, 0.0);
    glClear(GL_DEPTH_BUFFER_BIT or GL_COLOR_BUFFER_BIT or GL_STENCIL_BUFFER_BIT);
    glClearColor(1.0, 1.0, 1.0, 1.0);

    RTerrain.CurrentShader := RTerrain.ShadowPassShader;
    RTerrain.CurrentShader.UniformF('ShadowSize', ShadowSize);
    RTerrain.CurrentShader.UniformF('ShadowOffset', ShadowOffset.X, ShadowOffset.Y, ShadowOffset.Z);
    RTerrain.BorderEnabled := false;
    RTerrain.Render;

    RObjects.ShadowMode := True;
    RObjects.RenderOpaque;
    RObjects.RenderTransparent;
    RObjects.ShadowMode := False;

    fSunShadowBuffer.Unbind;
    end;

  // Lighting pass

  LightBuffer.Bind;
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT);

    glDisable(GL_ALPHA_TEST);
    glDisable(GL_BLEND);

    RTerrain.TerrainMap.Bind(4);

    if UseSunShadows then
      fSunShadowBuffer.Textures[0].Bind(2);

    GBuffer.Textures[0].Bind(3);
    GBuffer.Textures[1].Bind(1);
    GBuffer.Textures[2].Bind(0);

    SunShader.Bind;
    SunShader.UniformF('TerrainSize', Park.pTerrain.SizeX / 5, Park.pTerrain.SizeY / 5);
    SunShader.UniformF('ShadowSize', ShadowSize);
    SunShader.UniformF('ShadowOffset', ShadowOffset.X, ShadowOffset.Y, ShadowOffset.Z);
    SunShader.UniformI('BlurSamples', ShadowBlurSamples);
    SunShader.UniformF('BumpOffset', RWater.BumpOffset.X, RWater.BumpOffset.Y);
    DrawFullscreenQuad;
    SunShader.Unbind;

    RTerrain.TerrainMap.UnBind;
    GBuffer.Textures[0].UnBind;
    GBuffer.Textures[1].UnBind;
    GBuffer.Textures[2].UnBind;
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
    if fIsUnderWater then
      begin
      FogColor := Vector(0.20, 0.30, 0.27) * Vector3D(RSky.Sun.AmbientColor) * 3.0;
      FogStrength := 0.152; // log(0.9) / log(0.5);
      end
    else
      begin
      FogColor := Vector3D(Pow(RSky.Sun.AmbientColor + RSky.Sun.Color, 0.33)) * 0.5;
      FogStrength := RSky.FogStrength;
      end;
    CompositionShader.UniformF('FogColor', FogColor);
    CompositionShader.UniformF('FogStrength', FogStrength);
    CompositionShader.UniformF('WaterHeight', 0);
    CompositionShader.UniformF('WaterRefractionMode', 0);

    GBuffer.Textures[3].Bind(4);
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

    RObjects.MaterialMode := True;
    glEnable(GL_CULL_FACE);
    RObjects.RenderTransparent;
    glDisable(GL_CULL_FACE);

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

  // Under-water view

  if fIsUnderWater then
    begin
    fSpareBuffer.Bind;
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT);
    fUnderWaterShader.Bind;
    fUnderWaterShader.UniformF('Height', fWaterHeight);
    fUnderWaterShader.UniformF('ViewPoint', ViewPoint.X, ViewPoint.Y, ViewPoint.Z);
    fUnderWaterShader.UniformF('BumpOffset', RWater.BumpOffset.X, RWater.BumpOffset.Y);

    fSceneBuffer.Textures[0].Bind(1);
    GBuffer.Textures[2].Bind(0);

    DrawFullscreenQuad;

    fUnderWaterShader.Unbind;
    fSpareBuffer.Unbind;

    glDisable(GL_BLEND);
    glEnable(GL_ALPHA_TEST);


    fSceneBuffer.Bind;
    fFullscreenShader.Bind;

    fSpareBuffer.Textures[0].Bind(0);

    DrawFullscreenQuad;

    fSpareBuffer.Textures[0].UnBind;

    fFullscreenShader.UnBind;
    fSceneBuffer.Bind;
    end;

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
    glColor4f(Power(0.5, 100.0 * FogStrength), Power(0.5, 100.0 * FogStrength), Power(0.5, 100.0 * FogStrength), 1);
    SunRayBuffer.Textures[0].Bind(0);
    DrawFullscreenQuad;
    glDisable(GL_BLEND);

    fFullscreenShader.Unbind;

    SceneBuffer.Unbind;
    end;

  // Get average scene color
  fHDRAverageShader.Bind;

  glDisable(GL_ALPHA_TEST);
  glDisable(GL_CULL_FACE);
  glDisable(GL_BLEND);

  fHDRBuffer.Bind;
    fSceneBuffer.Textures[0].Bind(0);
    fHDRAverageShader.UniformI('Size', BufferSizeY);
    fHDRAverageShader.UniformI('Dir', 0, 1);
    DrawFullscreenQuad;
  fHDRBuffer.Unbind;

  fHDRBuffer2.Bind;
    fHDRBuffer.Textures[0].Bind(0);
    fHDRAverageShader.UniformI('Size', BufferSizeX);
    fHDRAverageShader.UniformI('Dir', 1, 0);
//     DrawFullscreenQuad;
    glBegin(GL_POINTS);
      glVertex2f(-1, -1);
    glEnd;
  fHDRBuffer2.Unbind;

  fHDRAverageShader.Unbind;

  // Bloom pass

  if BloomFactor > 0 then
    begin
    glDisable(GL_BLEND);

    BloomBuffer.Bind;

    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT);

    fBloomShader.Bind;
    fHDRBuffer2.Textures[0].Bind(1);
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
    glColor4f(BloomFactor, BloomFactor, BloomFactor, 1.0);

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
    fHDRBuffer2.Textures[0].Bind(1);
    fSceneBuffer.Textures[0].Bind(0);
    DrawFullscreenQuad;

    fAAShader.Unbind;

    glDisable(GL_BLEND);
    glDisable(GL_ALPHA_TEST);
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

    fHDRBuffer2.Textures[0].Bind(1);
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

  inc(fFrameID);
end;

procedure TModuleRendererOWE.CheckModConf;
begin
  if GetConfVal('used') <> '1' then
    begin
    SetConfVal('used', '1');
    SetConfVal('samples', '1');
    SetConfVal('reflections.realtime.minimum', '1.0');
    SetConfVal('reflections.realtime.distanceexponent', '0.05');
    SetConfVal('reflections.realtime.size', '128');
    SetConfVal('reflections.envmap.size', '256');
    SetConfVal('reflections.render.terrain', '1');
    SetConfVal('reflections.render.terrain.tesselationdistance', '0');
    SetConfVal('reflections.render.terrain.detaildistance', '0');
    SetConfVal('reflections.render.terrain.bumpmapdistance', '60');
    SetConfVal('reflections.render.autoplants', '0');
    SetConfVal('reflections.render.objects', '1');
    SetConfVal('reflections.render.particles', '0');
    SetConfVal('reflections.render.distanceoffset', '0');
    SetConfVal('reflections.render.distancefactor', '1');
    SetConfVal('reflections.updateinterval', '4');
    SetConfVal('reflections.environmentmap.interval', '200');
    SetConfVal('ssao', '0');
    SetConfVal('ssao.samples', '100');
    SetConfVal('refractions', '1');
    SetConfVal('shadows', '0');
    SetConfVal('shadows.samples', '1');
    SetConfVal('shadows.blursamples', '2');
    SetConfVal('shadows.maxpasses', '2');
    SetConfVal('bloom', '0.0');
    SetConfVal('focalblur', '0');
    SetConfVal('motionblur', '0');
    SetConfVal('motionblur.strength', '0.05');
    SetConfVal('sunrays', '0');
    SetConfVal('lod.distanceoffset', '0');
    SetConfVal('lod.distancefactor', '1');
    SetConfVal('subdiv.cuts', '0');
    SetConfVal('subdiv.distance', '0');
    SetConfVal('terrain.tesselationdistance', '15');
    SetConfVal('terrain.detaildistance', '60');
    SetConfVal('terrain.bumpmapdistance', '60');
    SetConfVal('autoplants.distance', '20');
    SetConfVal('autoplants.count', '0');
    SetConfVal('lensflare', '0');
    SetConfVal('gamma', '1.0');
    SetConfVal('water.samples', '0.5');
    SetConfVal('water.reflect.terrain', '0');
    SetConfVal('water.reflect.autoplants', '0');
    SetConfVal('water.reflect.sky', '1');
    SetConfVal('water.reflect.objects', '0');
    SetConfVal('water.reflect.particles', '0');
    SetConfVal('water.refract.terrain', '0');
    SetConfVal('water.refract.objects', '0');
    SetConfVal('water.refract.particles', '0');
    SetConfVal('water.refract.autoplants', '0');
    end;
  fFSAASamples := StrToIntWD(GetConfVal('samples'), 1);
  fReflectionSize := StrToIntWD(GetConfVal('reflections.realtime.size'), 128);
  fEnvMapSize := StrToIntWD(GetConfVal('reflections.envmap.size'), 256);
  fReflectionUpdateInterval := StrToIntWD(GetConfVal('reflections.updateinterval'), 4);
  fReflectionRealtimeMinimum := StrToFloatWD(GetConfVal('reflections.realtime.minimum'), 1.0);
  fReflectionRealtimeDistanceExponent := StrToFloatWD(GetConfVal('reflections.realtime.distanceexponent'), 0.05);
  fReflectionRenderAutoplants := GetConfVal('reflections.render.autoplants') = '1';
  fReflectionRenderTerrain := GetConfVal('reflections.render.terrain') = '1';
  fReflectionRenderParticles := GetConfVal('reflections.render.particles') = '1';
  fReflectionRenderObjects := GetConfVal('reflections.render.objects') = '1';
  fReflectionRenderDistanceOffset := StrToFloatWD(GetConfVal('reflections.render.distanceoffset'), 0.0);
  fReflectionRenderDistanceFactor := StrToFloatWD(GetConfVal('reflections.render.distancefactor'), 1.0);
  fReflectionTerrainTesselationDistance := StrToFloatWD(GetConfVal('reflections.render.terrain.tesselationdistance'), 0);
  fReflectionTerrainDetailDistance := StrToFloatWD(GetConfVal('reflections.render.terrain.detaildistance'), 0);
  fReflectionTerrainBumpmapDistance := StrToFloatWD(GetConfVal('reflections.render.terrain.bumpmapdistance'), 60);
  fEnvironmentMapInterval := StrToIntWD(GetConfVal('reflections.environmentmap.interval'), 200);
  fUseSunShadows := GetConfVal('shadows') <> '0';
  fUseLightShadows := GetConfVal('shadows') = '2';
  fBloomFactor := StrToFloatWD(GetConfVal('bloom'), 0.0);
  fUseRefractions := GetConfVal('refractions') = '1';
  fUseMotionBlur := GetConfVal('motionblur') = '1';
  fUseSunRays := GetConfVal('sunrays') = '1';
  fUseFocalBlur := GetConfVal('focalblur') = '1';
  fUseScreenSpaceAmbientOcclusion := GetConfVal('ssao') = '1';
  fUseLensFlare := GetConfVal('lensflare') = '1';
  fShadowBufferSamples := StrToFloatWD(GetConfVal('shadows.samples'), 1);
  fShadowBlurSamples := StrToIntWD(GetConfVal('shadows.blursamples'), 2);
  fMaxShadowPasses := StrToIntWD(GetConfVal('shadows.maxpasses'), 2);
  fMotionBlurStrength := StrToFloatWD(GetConfVal('motionblur.strength'), 0.05);
  fTerrainTesselationDistance := StrToFloatWD(GetConfVal('terrain.tesselationdistance'), 15);
  fTerrainDetailDistance := StrToFloatWD(GetConfVal('terrain.detaildistance'), 60);
  fTerrainBumpmapDistance := StrToFloatWD(GetConfVal('terrain.bumpmapdistance'), 60);
  fWaterReflectionBufferSamples := StrToFloatWD(GetConfVal('water.samples'), 0.5);
  fSSAOSamples := StrToIntWD(GetConfVal('ssao.samples'), 100);
  fLODDistanceOffset := StrToFloatWD(GetConfVal('lod.distanceoffset'), 0.0);
  fLODDistanceFactor := StrToFloatWD(GetConfVal('lod.distancefactor'), 1.0);
  fSubdivisionCuts := StrToIntWD(GetConfVal('subdiv.cuts'), 0);
  fSubdivisionDistance := StrToIntWD(GetConfVal('subdiv.distance'), 0);
  fAutoplantCount := StrToIntWD(GetConfVal('autoplants.count'), 0);
  fAutoplantDistance := StrToFloatWD(GetConfVal('autoplants.distance'), 20);
  fGamma := StrToFloatWD(GetConfVal('gamma'), 1);
  fWaterReflectTerrain := GetConfVal('water.reflect.terrain') = '1';
  fWaterReflectAutoplants := GetConfVal('water.reflect.autoplants') = '1';
  fWaterReflectSky := GetConfVal('water.reflect.sky') = '1';
  fWaterReflectObjects := GetConfVal('water.reflect.objects') = '1';
  fWaterReflectParticles := GetConfVal('water.reflect.particles') = '1';
  fWaterRefractTerrain := GetConfVal('water.refract.terrain') = '1';
  fWaterRefractObjects := GetConfVal('water.refract.objects') = '1';
  fWaterRefractParticles := GetConfVal('water.refract.particles') = '1';
  fWaterRefractAutoplants := GetConfVal('water.refract.autoplants') = '1';
end;

procedure TModuleRendererOWE.InvertFrontFace;
begin
  if fFrontFace = GL_CCW then
    fFrontFace := GL_CW
  else
    fFrontFace := GL_CCW;
  glFrontFace(fFrontFace);
end;

procedure TModuleRendererOWE.ApplyChanges(Event: String; Data, Result: Pointer);
begin
  SetConfVal('samples', Round(fOWEConfigInterface.fSamples.Value));
  SetConfVal('reflections.realtime.size', Round(fOWEConfigInterface.fReflectionRealtimeSize.Value));
  SetConfVal('reflections.envmap.size', Round(fOWEConfigInterface.fReflectionEnvMapSize.Value));
  SetConfVal('reflections.updateinterval', Round(fOWEConfigInterface.fReflectionRealtimeUpdateInterval.Value));
  SetConfVal('reflections.realtime.minimum', fOWEConfigInterface.fReflectionRealtimeMinimum.Value);
  SetConfVal('reflections.realtime.distanceexponent', fOWEConfigInterface.fReflectionRealtimeDistanceExponent.Value);
  SetConfVal('reflections.render.autoplants', fOWEConfigInterface.fReflectionRenderAutoplants.Checked);
  SetConfVal('reflections.render.terrain', fOWEConfigInterface.fReflectionRenderTerrain.Checked);
  SetConfVal('reflections.render.particles', fOWEConfigInterface.fReflectionRenderParticles.Checked);
  SetConfVal('reflections.render.objects', fOWEConfigInterface.fReflectionRenderObjects.Checked);
  SetConfVal('reflections.render.distanceoffset', fOWEConfigInterface.fReflectionRenderDistanceOffset.Value);
  SetConfVal('reflections.render.distancefactor', fOWEConfigInterface.fReflectionRenderDistanceFactor.Value);
  SetConfVal('reflections.render.terrain.tesselationdistance', fOWEConfigInterface.fReflectionRenderTerrainTesselationDistance.Value);
  SetConfVal('reflections.render.terrain.detaildistance', fOWEConfigInterface.fReflectionRenderTerrainDetailDistance.Value);
  SetConfVal('reflections.render.terrain.bumpmapdistance', fOWEConfigInterface.fTerrainBumpmapDistance.Value);
  SetConfVal('reflections.environmentmap.interval', Round(fOWEConfigInterface.fReflectionEnvMapUpdateInterval.Value));
  SetConfVal('shadows', 0);
  if fOWEConfigInterface.fUseSunShadows.Checked then
    begin
    SetConfVal('shadows', 1);
    if fOWEConfigInterface.fUseLightShadows.Checked then
      SetConfVal('shadows', 2);
    end;
  SetConfVal('bloom', fOWEConfigInterface.fBloom.Value);
//     SetConfVal('refractions', fOWEConfigInterface.fUseRefractions) = '1';
  SetConfVal('motionblur', fOWEConfigInterface.fMotionBlur.Checked);
  SetConfVal('sunrays', fOWEConfigInterface.fSunRays.Checked);
  SetConfVal('focalblur', fOWEConfigInterface.fFocalBlur.Checked);
  SetConfVal('ssao', fOWEConfigInterface.fSSAO.Checked);
  SetConfVal('lensflare', fOWEConfigInterface.fLensFlare.Checked);
  SetConfVal('shadows.samples', Round(fOWEConfigInterface.fShadowSamples.Value));
  SetConfVal('shadows.blursamples', Round(fOWEConfigInterface.fShadowBlurSamples.Value));
//     SetConfVal('shadows.maxpasses', fOWEConfigInterface.fMaxShadowPasses);
  SetConfVal('motionblur.strength', fOWEConfigInterface.fMotionBlurStrength.Value);
  SetConfVal('terrain.tesselationdistance', fOWEConfigInterface.fTerrainTesselationDistance.Value);
  SetConfVal('terrain.detaildistance', fOWEConfigInterface.fTerrainDetailDistance.Value);
  SetConfVal('terrain.bumpmapdistance', fOWEConfigInterface.fTerrainBumpmapDistance.Value);
  SetConfVal('water.samples', fOWEConfigInterface.fWaterSamples.Value);
  SetConfVal('ssao.samples', Round(fOWEConfigInterface.fSSAOSamples.Value));
  SetConfVal('lod.distanceoffset', fOWEConfigInterface.fLODDistanceOffset.Value);
  SetConfVal('lod.distancefactor', fOWEConfigInterface.fLODDistanceFactor.Value);
//     SetConfVal('subdiv.cuts', fOWEConfigInterface.fSubdivisionCuts);
//     SetConfVal('subdiv.distance', fOWEConfigInterface.fSubdivisionDistance);
  SetConfVal('autoplants.count', Round(fOWEConfigInterface.fAutoplantCount.Value));
  SetConfVal('autoplants.distance', fOWEConfigInterface.fAutoplantDistance.Value);
  SetConfVal('gamma', fOWEConfigInterface.fGamma.Value);
  SetConfVal('water.reflect.terrain', fOWEConfigInterface.fWaterReflectTerrain.Checked);
  SetConfVal('water.reflect.autoplants', fOWEConfigInterface.fWaterReflectAutoplants.Checked);
  SetConfVal('water.reflect.sky', fOWEConfigInterface.fWaterReflectSky.Checked);
  SetConfVal('water.reflect.objects', fOWEConfigInterface.fWaterReflectObjects.Checked);
  SetConfVal('water.reflect.particles', fOWEConfigInterface.fWaterReflectParticles.Checked);
  SetConfVal('water.refract.terrain', fOWEConfigInterface.fWaterRefractTerrain.Checked);
  SetConfVal('water.refract.objects', fOWEConfigInterface.fWaterRefractObjects.Checked);
  SetConfVal('water.refract.particles', fOWEConfigInterface.fWaterRefractParticles.Checked);
  SetConfVal('water.refract.autoplants', fOWEConfigInterface.fWaterRefractAutoplants.Checked);
  CheckModConf;
end;

procedure TModuleRendererOWE.CreateConfigInterface(Event: String; Data, Result: Pointer);
begin
  fOWEConfigInterface := TOWEConfigInterface.Create(TGUIComponent(Data));
  TConfigurationInterfaceList(Result).Add('Graphics', fOWEConfigInterface.fConfigurationInterface);
end;

procedure TModuleRendererOWE.DestroyConfigInterface(Event: String; Data, Result: Pointer);
begin
  fOWEConfigInterface.Free;
end;

constructor TModuleRendererOWE.Create;
begin
  fModName := 'RendererOWE';
  fModType := 'Renderer';

  EventManager.AddCallback('TSettings.CreateConfigurationInterface', @CreateConfigInterface);
  EventManager.AddCallback('TSettings.DestroyConfigurationInterface', @DestroyConfigInterface);
  EventManager.AddCallback('TSettings.ApplyConfigurationChanges', @ApplyChanges);
end;

destructor TModuleRendererOWE.Free;
begin
  EventManager.RemoveCallback(@CreateConfigInterface);
  EventManager.RemoveCallback(@DestroyConfigInterface);
  EventManager.RemoveCallback(@ApplyChanges);
end;

end.