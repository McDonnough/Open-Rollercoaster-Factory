unit m_renderer_owe;

interface

uses
  Classes, SysUtils, m_renderer_class, DGLOpenGL, g_park, u_math, u_vectors, m_renderer_owe_particles,
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
      fRendererParticles: TRParticles;
      fLightManager: TLightManager;
      fGBuffer, fHDRBuffer, fHDRBuffer2, fLightBuffer, fSceneBuffer, fSSAOBuffer, fSunRayBuffer, fBloomBuffer, fFocalBlurBuffer, fMotionBlurBuffer, fSpareBuffer, fSunShadowBuffer: TFBO;
      fFSAASamples: Integer;
      fReflectionRealtimeMinimum, fReflectionRealtimeDistanceExponent: Single;
      fReflectionRenderTerrain, fReflectionRenderAutoplants, fReflectionRenderObjects, fReflectionRenderParticles: Boolean;
      fReflectionUpdateInterval: Integer;
      fReflectionSize, fEnvMapSize: Integer;
      fUseSunShadows, fUseLightShadows, fUseSunRays, fUseRefractions: Boolean;
      fUseScreenSpaceAmbientOcclusion, fUseMotionBlur, fUseFocalBlur, fUseScreenSpaceIndirectLighting: Boolean;
      fBloomFactor: Single;
      fLODDistanceOffset, fLODDistanceFactor, fMotionBlurStrength: Single;
      fReflectionRenderDistanceOffset, fReflectionRenderDistanceFactor: Single;
      fReflectionTerrainDetailDistance, fReflectionTerrainTesselationDistance, fReflectionTerrainBumpmapDistance: Single;
      fShadowBufferSamples, fLightShadowBufferSamples: Single;
      fSubdivisionCuts: Integer;
      fSubdivisionDistance: Single;
      fBufferSizeX, fBufferSizeY: Integer;
      fSSAOSamples, fShadowBlurSamples, fLightShadowBlurSamples, fSSAORings: Integer;
      fSSAOSize: Single;
      fTmpBloomBuffer: TFBO;
      fMaxShadowPasses: Integer;
      fAutoplantCount: Integer;
      fAutoplantDistance: Single;
      fTerrainDetailDistance, fTerrainTesselationDistance, fTerrainBumpmapDistance: Single;
      fFullscreenShader, fBlackShader, fAAShader, fSunRayShader, fCausticShader, fSunShader, fLightShader, fLightShaderWithShadow, fCompositionShader, fBloomShader, fBloomBlurShader, fFocalBlurShader, fShadowDepthShader, fLensFlareShader, fHDRAverageShader, fSSAOShader, fGridShader: TShader;
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
      fEnableS3D: Boolean;
      fEnablePOM, fEnablePOMSelfShadow: Boolean;
      fS3DMode: Integer;
      fS3DInvert: Boolean;
      fS3DStrength: Single;
    public
      CurrentTerrainBumpmapDistance, CurrentTerrainDetailDistance, CurrentTerrainTesselationDistance: Single;
      CurrentLODDistanceFactor, CurrentLODDistanceOffset: Single;
      ViewPoint: TVector3D;
      MaxRenderDistance: Single;
      FogStrength, FogRefractMode: Single;
      FogColor: TVector3D;
      RenderParticles: Boolean;
      Uniforms: Array[0..24] of GLUInt;
      property LightManager: TLightManager read fLightManager;
      property RCamera: TRCamera read fRendererCamera;
      property RSky: TRSky read fRendererSky;
      property RTerrain: TRTerrain read fRendererTerrain;
      property RAutoplants: TRAutoplants read fRendererAutoplants;
      property RObjects: TRObjects read fRendererObjects;
      property RWater: TRWater read fRendererWater;
      property RParticles: TRParticles read fRendererParticles;
      property FullscreenShader: TShader read fFullscreenShader;
      property LightShader: TShader read fLightShader;
      property LightShaderWithShadow: TShader read fLightShaderWithShadow;
      property SunShader: TShader read fSunShader;
      property CompositionShader: TShader read fCompositionShader;
      property GridShader: TShader read fGridShader;
      property MotionBlurBuffer: TFBO read fMotionBlurBuffer;
      property FocalBlurBuffer: TFBO read fFocalBlurBuffer;
      property HDRAverageShader: TShader read fHDRAverageShader;
      property SimpleShader: TShader read fSimpleShader;
      property SSAOShader: TShader read fSSAOShader;
      property CausticShader: TShader read fCausticShader;
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
      property UseScreenSpaceIndirectLighting: Boolean read fUseScreenSpaceIndirectLighting;
      property UseLensFlare: Boolean read fUseLensFlare;
      property WaterReflectionBufferSamples: Single read fWaterReflectionBufferSamples;
      property ShadowBufferSamples: Single read fShadowBufferSamples;
      property ShadowBlurSamples: Integer read fShadowBlurSamples;
      property LightShadowBufferSamples: Single read fLightShadowBufferSamples;
      property LightShadowBlurSamples: Integer read fLightShadowBlurSamples;
      property SSAOSamples: Integer read fSSAOSamples;
      property SSAORings: Integer read fSSAORings;
      property SSAOSize: Single read fSSAOSize;
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
      property EnableS3D: Boolean read fEnableS3D;
      property S3DMode : Integer read fS3DMode;
      property S3DStrength: Single read fS3DStrength;
      property S3DInvert: Boolean read fS3DInvert;
      property EnablePOM: Boolean read fEnablePOM;
      property EnablePOMSelfShadow: Boolean read fEnablePOMSelfShadow;
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
      function Capture: TByteStream;
      constructor Create;
      destructor Free;
    end;

const
  UNIFORM_SSAO_RANDOMOFFSET = 0;
  UNIFORM_SUN_USESSAO = 1;
  UNIFORM_SUN_TERRAINSIZE = 2;
  UNIFORM_SUN_SHADOWSIZE = 3;
  UNIFORM_SUN_SHADOWOFFSET = 4;
  UNIFORM_SUN_BUMPOFFSET = 5;
  UNIFORM_SUNRAY_VECTOFRONT = 6;
  UNIFORM_COMPOSITION_FOGCOLOR = 7;
  UNIFORM_COMPOSITION_FOGSTRENGTH = 8;
  UNIFORM_COMPOSITION_WATERHEIGHT = 9;
  UNIFORM_COMPOSITION_WATERREFRACTIONMODE = 10;
  UNIFORM_GRID_OFFSET = 11;
  UNIFORM_GRID_SIZE = 12;
  UNIFORM_GRID_ROTMAT = 13;
  UNIFORM_UNDERWATER_HEIGHT = 14;
  UNIFORM_UNDERWATER_VIEWPOINT = 15;
  UNIFORM_UNDERWATER_BUMPOFFSET = 16;
  UNIFORM_FOCALBLUR_FOCUSDISTANCE = 17;
  UNIFORM_FOCALBLUR_SCREEN = 18;
  UNIFORM_FOCALBLUR_STRENGTH = 19;
  UNIFORM_HDRAVERAGE_SIZE = 20;
  UNIFORM_HDRAVERAGE_DIR = 21;
  UNIFORM_BLOOMBLUR_BLURDIRECTION = 22;
  UNIFORM_CAUSTIC_TERRAINSIZE = 23;
  UNIFORM_CAUSTIC_BUMPOFFSET = 24;

implementation

uses
  m_varlist, u_events, main, g_parkui, g_object_builder;

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
  fSelectedMaterialID := 0;
  CaptureNextFrame := False;

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

  if fS3DMode = 0 then
    begin
    fBufferSizeX := fBufferSizeX div 2;
    fBufferSizeY := fBufferSizeY div 2;
    end;

  fGBuffer := TFBO.Create(BufferSizeX, BufferSizeY, true);
  fGBuffer.AddTexture(GL_RGBA16F_ARB, GL_NEAREST, GL_NEAREST);  // Materials (opaque only) and specularity
  fGBuffer.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);
  fGBuffer.AddTexture(GL_RGBA16F_ARB, GL_NEAREST, GL_NEAREST);  // Normals and specular hardness
  fGBuffer.Textures[1].SetClamp(GL_CLAMP, GL_CLAMP);
  fGBuffer.AddTexture(GL_RGBA32F_ARB, GL_NEAREST, GL_NEAREST);  // Vertex and depth
  fGBuffer.Textures[2].SetClamp(GL_CLAMP, GL_CLAMP);
  fGBuffer.AddTexture(GL_RGBA, GL_NEAREST, GL_NEAREST);         // Transparency Material ID
  fGBuffer.Textures[3].SetClamp(GL_CLAMP, GL_CLAMP);
  fGBuffer.AddTexture(GL_RGBA16F_ARB, GL_NEAREST, GL_NEAREST);  // Reflection and reflectivity
  fGBuffer.Textures[4].SetClamp(GL_CLAMP, GL_CLAMP);
  fGBuffer.AddTexture(GL_RGBA16F_ARB, GL_NEAREST, GL_NEAREST);  // Emission
  fGBuffer.Textures[5].SetClamp(GL_CLAMP, GL_CLAMP);
  fGBuffer.Unbind;

  fSpareBuffer := TFBO.Create(BufferSizeX, BufferSizeY, false);
  fSpareBuffer.AddTexture(GL_RGBA16F_ARB, GL_NEAREST, GL_NEAREST);     // Materials (opaque only) and specularity
  fSpareBuffer.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);
  fSpareBuffer.Unbind;

  fLightBuffer := TFBO.Create(BufferSizeX, BufferSizeY, true);         // Depth buffer for selection hack
  fLightBuffer.AddTexture(GL_RGBA16F_ARB, GL_NEAREST, GL_NEAREST);     // Colors
  fLightBuffer.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);
  fLightBuffer.AddTexture(GL_RGB16F_ARB, GL_NEAREST, GL_NEAREST);      // Specular
  fLightBuffer.Textures[1].SetClamp(GL_CLAMP, GL_CLAMP);
  fLightBuffer.Unbind;

  fSceneBuffer := TFBO.Create(BufferSizeX, BufferSizeY, true);
  fSceneBuffer.AddTexture(GL_RGB16F_ARB, GL_NEAREST, GL_NEAREST);      // Composed image
  fSceneBuffer.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);
  fSceneBuffer.Unbind;

  fHDRBuffer := TFBO.Create(BufferSizeX, 1, false);
  fHDRBuffer.AddTexture(GL_RGB16F_ARB, GL_NEAREST, GL_NEAREST);
  fHDRBuffer.Unbind;

  fHDRBuffer2 := TFBO.Create(1, 1, false);
  fHDRBuffer2.AddTexture(GL_RGB16F_ARB, GL_NEAREST, GL_NEAREST);
  fHDRBuffer2.Unbind;

  if UseScreenSpaceAmbientOcclusion then
    begin
    fSSAOBuffer := TFBO.Create(Round(ResX * SSAOSize), Round(ResY * SSAOSize), false);
    fSSAOBuffer.AddTexture(GL_RGBA16F_ARB, GL_LINEAR, GL_LINEAR);     // Screen Space Ambient Occlusion
    fSSAOBuffer.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);
    fSSAOBuffer.Unbind;
    end
  else
    fSSAOBuffer := nil;

  if BloomFactor > 0 then
    begin
    fBloomBuffer := TFBO.Create(Round(ResX * SSAOSize), Round(ResY * SSAOSize), false);
    fBloomBuffer.AddTexture(GL_RGB, GL_LINEAR, GL_LINEAR);    // Pseudo-HDR/Color Bleeding
    fBloomBuffer.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);
    fBloomBuffer.Unbind;
    end
  else
    fBloomBuffer := nil;

  if UseFocalBlur then
    begin
    fFocalBlurBuffer := TFBO.Create(BufferSizeX, BufferSizeY, false);
    fFocalBlurBuffer.AddTexture(GL_RGB, GL_LINEAR, GL_LINEAR); // Focal blur
    fFocalBlurBuffer.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);
    fFocalBlurBuffer.Unbind;
    end
  else
    fFocalBlurBuffer := nil;

  if UseSunRays then
    begin
    fSunRayBuffer := TFBO.Create(Round(ResX * SSAOSize * 0.5), Round(ResY * SSAOSize * 0.5), false);
    fSunRayBuffer.AddTexture(GL_RGBA, GL_LINEAR, GL_LINEAR);  // Color overlay
    fSunRayBuffer.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);
    fSunRayBuffer.Unbind;
    end
  else
    fSunRayBuffer := nil;

  if BloomFactor > 0 then
    begin
    fTmpBloomBuffer := TFBO.Create(Round(ResX * SSAOSize), Round(ResY * SSAOSize), true);
    fTmpBloomBuffer.AddTexture(GL_RGB, GL_LINEAR, GL_LINEAR);
    fTmpBloomBuffer.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);
    fTmpBloomBuffer.Unbind;
    end
  else
    fTmpBloomBuffer := nil;

  if UseMotionBlur then
    begin
    fMotionBlurBuffer := TFBO.Create(ResX, ResY, false);
    fMotionBlurBuffer.AddTexture(GL_RGBA, GL_NEAREST, GL_NEAREST);
    fMotionBlurBuffer.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);
    fMotionBlurBuffer.Unbind;
    end
  else
    fMotionBlurBuffer := nil;

  if UseSunShadows then
    begin
    fSunShadowBuffer := TFBO.Create(Round(1024 * ShadowBufferSamples), Round(1024 * ShadowBufferSamples), true);
    fSunShadowBuffer.AddTexture(GL_RGBA32F_ARB, GL_LINEAR, GL_LINEAR);
    fSunShadowBuffer.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);
    fSunShadowBuffer.Unbind;
    end
  else
    fSunShadowBuffer := nil;

  fLightManager := TLightManager.Create;
  fRendererCamera := TRCamera.Create;
  fRendererObjects := TRObjects.Create;
  fRendererParticles := TRParticles.Create;
  fRendererSky := TRSky.Create;
  fRendererTerrain := TRTerrain.Create;
  fRendererAutoplants := TRAutoplants.Create;
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
  Uniforms[UNIFORM_HDRAVERAGE_DIR] := fHDRAverageShader.GetUniformLocation('Dir');
  Uniforms[UNIFORM_HDRAVERAGE_SIZE] := fHDRAverageShader.GetUniformLocation('Size');

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
  Uniforms[UNIFORM_SUNRAY_VECTOFRONT] := fSunRayShader.GetUniformLocation('VecToFront');

  fSunShader := TShader.Create('orcf-world-engine/postprocess/fullscreen.vs', 'orcf-world-engine/inferred/sun.fs');
  fSunShader.UniformI('GeometryTexture', 0);
  fSunShader.UniformI('NormalTexture', 1);
  fSunShader.UniformI('ShadowTexture', 2);
  fSunShader.UniformI('MaterialTexture', 3);
  fSunShader.UniformI('HeightMap', 4);
  fSunShader.UniformI('SSAOTexture', 5);
  fSunShader.UniformI('EmissionTexture', 6);
  fSunShader.UniformI('MaterialMap', 7);
  Uniforms[UNIFORM_SUN_TERRAINSIZE] := fSunShader.GetUniformLocation('TerrainSize');
  Uniforms[UNIFORM_SUN_BUMPOFFSET] := fSunShader.GetUniformLocation('BumpOffset');
  Uniforms[UNIFORM_SUN_SHADOWOFFSET] := fSunShader.GetUniformLocation('ShadowOffset');
  Uniforms[UNIFORM_SUN_SHADOWSIZE] := fSunShader.GetUniformLocation('ShadowSize');
  Uniforms[UNIFORM_SUN_USESSAO] := fSunShader.GetUniformLocation('UseSSAO');

  fSSAOShader := TShader.Create('orcf-world-engine/postprocess/fullscreen.vs', 'orcf-world-engine/inferred/ssao.fs');
  fSSAOShader.UniformI('GeometryTexture', 0);
  fSSAOShader.UniformI('NormalTexture', 1);
  fSSAOShader.UniformI('EmissionTexture', 2);
  fSSAOShader.UniformI('ScreenSize', ResX, ResY);
  Uniforms[UNIFORM_SSAO_RANDOMOFFSET] := fSSAOShader.GetUniformLocation('RandomOffset');

  fLightShader := TShader.Create('orcf-world-engine/inferred/lightcube.vs', 'orcf-world-engine/inferred/light.fs');
  fLightShader.UniformI('GeometryTexture', 0);
  fLightShader.UniformI('NormalTexture', 1);
  fLightShader.UniformI('ShadowTexture', 2);
  fLightShader.UniformI('MaterialTexture', 3);

  fLightShaderWithShadow := TShader.Create('orcf-world-engine/inferred/lightcube.vs', 'orcf-world-engine/inferred/lightws.fs');
  fLightShaderWithShadow.UniformI('GeometryTexture', 0);
  fLightShaderWithShadow.UniformI('NormalTexture', 1);
  fLightShaderWithShadow.UniformI('ShadowTexture', 2);
  fLightShaderWithShadow.UniformI('MaterialTexture', 3);

  fCompositionShader := TShader.Create('orcf-world-engine/postprocess/fullscreen.vs', 'orcf-world-engine/postprocess/composition.fs');
  fCompositionShader.UniformI('MaterialTexture', 0);
  fCompositionShader.UniformI('GTexture', 2);
  fCompositionShader.UniformI('ReflectionTexture', 3);
  fCompositionShader.UniformI('MaterialMap', 4);
  fCompositionShader.UniformI('SpecularTexture', 6);
  fCompositionShader.UniformI('LightTexture', 7);
  Uniforms[UNIFORM_COMPOSITION_FOGCOLOR] := fCompositionShader.GetUniformLocation('FogColor');
  Uniforms[UNIFORM_COMPOSITION_FOGSTRENGTH] := fCompositionShader.GetUniformLocation('FogStrength');
  Uniforms[UNIFORM_COMPOSITION_WATERHEIGHT] := fCompositionShader.GetUniformLocation('WaterHeight');
  Uniforms[UNIFORM_COMPOSITION_WATERREFRACTIONMODE] := fCompositionShader.GetUniformLocation('WaterRefractionMode');

  fGridShader := TShader.Create('orcf-world-engine/postprocess/fullscreen.vs', 'orcf-world-engine/postprocess/grid.fs');
  fGridShader.UniformI('GeometryTex', 2);
  Uniforms[UNIFORM_GRID_OFFSET] := fGridShader.GetUniformLocation('Offset');
  Uniforms[UNIFORM_GRID_SIZE] := fGridShader.GetUniformLocation('Size');
  Uniforms[UNIFORM_GRID_ROTMAT] := fGridShader.GetUniformLocation('RotMat');

  fLensFlareShader := TShader.Create('orcf-world-engine/postprocess/lensflare.vs', 'orcf-world-engine/postprocess/lensflare.fs');
  fLensFlareShader.UniformI('Texture', 0);
  fLensFlareShader.UniformI('GeometryTexture', 1);
  fLensFlareShader.UniformF('AspectRatio', ResY / ResX, 1);

  fBloomShader := TShader.Create('orcf-world-engine/postprocess/fullscreen.vs', 'orcf-world-engine/postprocess/bloom.fs');
  fBloomShader.UniformI('Tex', 0);
  fBloomShader.UniformI('HDRColor', 1);

  fBloomBlurShader := TShader.Create('orcf-world-engine/postprocess/fullscreen.vs', 'orcf-world-engine/postprocess/blur.fs');
  fBloomBlurShader.UniformI('Tex', 0);
  Uniforms[UNIFORM_BLOOMBLUR_BLURDIRECTION] := fBloomBlurShader.GetUniformLocation('BlurDirection');

  fFocalBlurShader := TShader.Create('orcf-world-engine/postprocess/fullscreen.vs', 'orcf-world-engine/postprocess/focalblur.fs');
  fFocalBlurShader.UniformI('SceneTexture', 0);
  fFocalBlurShader.UniformI('GeometryTexture', 1);
  Uniforms[UNIFORM_FOCALBLUR_FOCUSDISTANCE] := fFocalBlurShader.GetUniformLocation('FocusDistance');
  Uniforms[UNIFORM_FOCALBLUR_SCREEN] := fFocalBlurShader.GetUniformLocation('Screen');
  Uniforms[UNIFORM_FOCALBLUR_STRENGTH] := fFocalBlurShader.GetUniformLocation('Strength');

  fShadowDepthShader := TShader.Create('orcf-world-engine/postprocess/fullscreen.vs', 'orcf-world-engine/inferred/shadowDepth.fs');
  fShadowDepthShader.UniformI('AdvanceSamples', Round(FSAASamples / ShadowBufferSamples));
  fShadowDepthShader.UniformI('GeometryTexture', 0);

  fBlackShader := TShader.Create('orcf-world-engine/postprocess/fullscreen.vs', 'orcf-world-engine/inferred/black.fs');

  fUnderWaterShader := TShader.Create('orcf-world-engine/postprocess/underWater.vs', 'orcf-world-engine/postprocess/underWater.fs');
  fUnderWaterShader.UniformI('GeometryMap', 0);
  fUnderWaterShader.UniformI('RenderedScene', 1);
  Uniforms[UNIFORM_UNDERWATER_HEIGHT] := fUnderWaterShader.GetUniformLocation('Height');
  Uniforms[UNIFORM_UNDERWATER_BUMPOFFSET] := fUnderWaterShader.GetUniformLocation('BumpOffset');
  Uniforms[UNIFORM_UNDERWATER_VIEWPOINT] := fUnderWaterShader.GetUniformLocation('ViewPoint');

  fCausticShader := TShader.Create('orcf-world-engine/postprocess/fullscreen.vs', 'orcf-world-engine/postprocess/caustics.fs');
  fCausticShader.UniformI('GeometryTexture', 0);
  fCausticShader.UniformI('NormalTexture', 1);
  fCausticShader.UniformI('HeightMap', 4);
  Uniforms[UNIFORM_CAUSTIC_TERRAINSIZE] := fCausticShader.GetUniformLocation('TerrainSize');
  Uniforms[UNIFORM_CAUSTIC_BUMPOFFSET] := fCausticShader.GetUniformLocation('BumpOffset');

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
  fCausticShader.Free;
  fUnderWaterShader.Free;
  fBlackShader.Free;
  fShadowDepthShader.Free;
  fFocalBlurShader.Free;
  fBloomBlurShader.Free;
  fBloomShader.Free;
  fLensFlareShader.Free;
  fGridShader.Free;
  fCompositionShader.Free;
  fLightShaderWithShadow.Free;
  fLightShader.Free;
  fSSAOShader.Free;
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
  fHDRBuffer.Free;
  fHDRBuffer2.Free;

  fRendererWater.Free;
  fRendererAutoplants.Free;
  fRendererTerrain.Clear;
  fRendererTerrain.Free;
  fRendererSky.Free;
  fRendererParticles.Free;
  fRendererObjects.Clear;
  fRendererObjects.Free;
  fRendererCamera.Free;
  fLightManager.Clear;
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
  Matrix: Array[0..15] of Single;

  procedure DrawFullscreenQuad;
  begin
    glBegin(GL_QUADS);
      glTexCoord2d(0, 0); glVertex2f(-1, -1);
      glTexCoord2d(1, 0); glVertex2f( 1, -1);
      glTexCoord2d(1, 1); glVertex2f( 1,  1);
      glTexCoord2d(0, 1); glVertex2f(-1,  1);
    glEnd;
  end;

  procedure DrawFullscreenQuad(Offset: TVector2D; Scale: TVector2D);
  begin
    glBegin(GL_QUADS);
      glTexCoord2d(0, 0); glVertex2f(-1 + Offset.X, -1 + Offset.Y);
      glTexCoord2d(1, 0); glVertex2f(-1 + Offset.X + 2.0 * Scale.X, -1 + Offset.Y);
      glTexCoord2d(1, 1); glVertex2f(-1 + Offset.X + 2.0 * Scale.X, -1 + Offset.Y + 2.0 * Scale.Y);
      glTexCoord2d(0, 1); glVertex2f(-1 + Offset.X, -1 + Offset.Y + 2.0 * Scale.Y);
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
  MX, MY, hdiff: Single;
  i, ResX, ResY: Integer;
  Coord: TVector4D;
  AMatrix: TMatrix4D;
  OrigCamPos, VecX: TVector3D;
  Passes, Pass: Integer;
begin
  glGetError();

  RParticles.UpdateVBOs;

  ModuleManager.ModGLContext.GetResolution(ResX, ResY);
  FogStrength := RSky.FogStrength;
  FogRefractMode := 0;
  fMaxFogDistance := Log10(0.003) / (Log10(0.5) * FogStrength);
  
  MaxRenderDistance := MaxFogDistance;

  ViewPoint := ModuleManager.ModCamera.ActiveCamera.Position;
  AMatrix := RotationMatrix(ModuleManager.ModCamera.ActiveCamera.Rotation.Z, Vector(0, 0, -1));
  AMatrix := RotationMatrix(ModuleManager.ModCamera.ActiveCamera.Rotation.Y, Vector(0, -1, 0));
  VecX := Normalize(Vector3D(Vector(1, 0, 0, 0) * AMatrix)) * fS3DStrength * 0.1;

  fIsUnderWater := False;

  fWaterHeight := Park.pTerrain.WaterMap[ModuleManager.ModRenderer.ViewPoint.X, ModuleManager.ModRenderer.ViewPoint.Z];
  if ModuleManager.ModRenderer.ViewPoint.Y < fWaterHeight then
    begin
    fIsUnderWater := True;
    MaxRenderDistance := 55;
    end;

  RTerrain.CheckForHDVBO;

  // Set up camera

  glMatrixMode(GL_PROJECTION);
  ModuleManager.ModGLMng.SetUp3DMatrix;
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;

  RSky.Advance;
  RSky.Sun.Bind(0);

  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);

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
  RObjects.Working := True;

  if fIsUnderWater then
    MaxRenderDistance := 55
  else
    MaxRenderDistance := MaxFogDistance;

  if EnableS3D then
    Passes := 1
  else
    Passes := 0;

  for Pass := 0 to Passes do
    begin
    OrigCamPos := ModuleManager.ModCamera.ActiveCamera.Position;
    if EnableS3D then
      begin
      case Pass of
        0: ModuleManager.ModCamera.ActiveCamera.Position := ModuleManager.ModCamera.ActiveCamera.Position - VecX;
        1: ModuleManager.ModCamera.ActiveCamera.Position := ModuleManager.ModCamera.ActiveCamera.Position + VecX;
        end;
      glLoadIdentity;
      RCamera.ApplyRotation(Vector(1, 1, 1));
      RCamera.ApplyTransformation(Vector(1, 1, 1));

      ViewPoint := ModuleManager.ModCamera.ActiveCamera.Position;
      end;

    // Do water renderpasses
    RWater.RenderBuffers;

    // Render final scene

    // Check some visibilities
    Frustum.Calculate;
    RTerrain.CheckVisibility;
    RObjects.CheckVisibility;
    RenderParticles := True;

    // Run some threads
    if UseLightShadows then
      LightManager.Working := True;

    glDisable(GL_BLEND);
    glDisable(GL_ALPHA_TEST);
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LESS);
    glDisable(GL_CULL_FACE);
    glDepthMask(true);

    Coord := Vector(0, 0, 0, 0);

    // Selection pass - abuse the light buffer for that because it consists of two buffers
    if (Pass = 0) then
      begin
      fSelectionStart := ModuleManager.ModCamera.ActiveCamera.Position;
      fSelectionRay := Vector(0, 0, 0);
      end;
    if (Park.SelectionEngine <> nil) and (Pass = 0) then
      begin
      LightBuffer.Bind;
      glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);

      if Park.SelectionEngine.RenderTerrain then
        RTerrain.RenderSelectable($000001);

      if Park.SelectionEngine.RenderObjects then
        RObjects.RenderSelectable;

      LightBuffer.Unbind;

      // Finally get intersection point and selected object ID
      glColor4f(1, 1, 1, 1);
      SpareBuffer.Bind;
        fFullscreenShader.Bind;
        LightBuffer.Textures[0].Bind(0);
        DrawFullscreenQuad;
        if fS3DMode = 0 then
          glReadPixels(ModuleManager.ModInputHandler.MouseX * FSAASamples mod (ResX div 2), (ResY - ModuleManager.ModInputHandler.MouseY) * FSAASamples - (ResY div 4), 1, 1, GL_RGBA, GL_FLOAT, @Coord.X)
        else
          glReadPixels(ModuleManager.ModInputHandler.MouseX * FSAASamples, (ResY - ModuleManager.ModInputHandler.MouseY) * FSAASamples, 1, 1, GL_RGBA, GL_FLOAT, @Coord.X);

        fSelectionStart := ModuleManager.ModCamera.ActiveCamera.Position;
        fSelectionRay := Vector3D(Coord) - fSelectionStart;

        LightBuffer.Textures[1].Bind(0);
        DrawFullscreenQuad;

        if fS3DMode = 0 then
          glReadPixels(ModuleManager.ModInputHandler.MouseX * FSAASamples mod (ResX div 2), (ResY - ModuleManager.ModInputHandler.MouseY) * FSAASamples - (ResY div 4), 1, 1, GL_RGBA, GL_FLOAT, @Coord.X)
        else
          glReadPixels(ModuleManager.ModInputHandler.MouseX * FSAASamples, (ResY - ModuleManager.ModInputHandler.MouseY) * FSAASamples, 1, 1, GL_RGBA, GL_FLOAT, @Coord.X);
        fFullscreenShader.Unbind;
        fSelectedMaterialID := (Round(Coord.X) shl 16) or (Round(Coord.Y) shl 8) or (Round(Coord.Z));

        LightBuffer.Textures[1].Unbind;
      SpareBuffer.Unbind;
      end;

    // Geometry pass

    // Opaque parts only
    GBuffer.Bind;
      glDisable(GL_BLEND);
      glDepthMask(true);
      glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
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
      glDisable(GL_CULL_FACE);

      glColorMask(false, false, false, false);
      glDepthMask(false);
      RWater.Check;
      glDepthMask(true);
      glColorMask(true, true, true, true);

      RWater.Render;

    GBuffer.Unbind;

    // Save material buffer
    SpareBuffer.Bind;
      GBuffer.Textures[0].Bind(0);
      fFullscreenShader.Bind;
      DrawFullscreenQuad;
      fFullscreenShader.Unbind;
      GBuffer.Textures[0].UnBind;
    SpareBuffer.Unbind;

    // SSAO pass

    if UseScreenSpaceAmbientOcclusion then
      begin
      glDisable(GL_CULL_FACE);

      SSAOBuffer.Bind;

      glDisable(GL_BLEND);
      glDisable(GL_ALPHA_TEST);
      glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);

      fSSAOShader.Bind;
      fSSAOShader.UniformF(Uniforms[UNIFORM_SSAO_RANDOMOFFSET], 100 * Random);
      GBuffer.Textures[5].Bind(2);
      GBuffer.Textures[1].Bind(1);
      GBuffer.Textures[2].Bind(0);

      DrawFullscreenQuad;

      GBuffer.Textures[5].Unbind;
      GBuffer.Textures[1].Unbind;
      GBuffer.Textures[2].Unbind;
      fSSAOShader.Unbind;

      SSAOBuffer.Unbind;

      glEnable(GL_CULL_FACE);
      end;

    // Transparent parts, fuck up the material buffer
    GBuffer.Bind;
      fTransparencyMask.Bind(7);

      glDisable(GL_ALPHA_TEST);
  //     glColorMask(true, true, true, false);

      // Autoplants
      glDisable(GL_CULL_FACE);
      RAutoplants.CurrentShader := RAutoplants.GeometryPassShader;
      RAutoplants.Render;

      // Objects and particles
      glEnable(GL_CULL_FACE);
      RParticles.CurrentShader := RParticles.GeometryShader;
      RObjects.MaterialMode := False;
      RObjects.RenderTransparent;

      // End

  //     glColorMask(true, true, true, true);
      glDisable(GL_DEPTH_TEST);
      glDepthMask(false);
      glDisable(GL_ALPHA_TEST);

    GBuffer.Unbind;

    // Shadow pass
    
    if (UseSunShadows) and (Pass = 0) then
      begin
      glDisable(GL_CULL_FACE);
      fShadowOffset := ModuleManager.ModCamera.ActiveCamera.Position;
      hdiff := fShadowOffset.Y - RTerrain.GetBlock(fShadowOffset.X, fShadowOffset.Z).MinHeight;
      fShadowSize := 50 * Power(0.9, hdiff) + (3 - abs(dotProduct(Vector(0, 1, 0), Normalize(Vector3D(RSky.Sun.Position))))) * hdiff;
      fShadowOffset := fShadowOffset + Normalize(ModuleManager.ModCamera.ActiveCamera.Position - Vector3D(RSky.Sun.Position)) * 20 * DotProduct(Normalize(fVecToFront), Normalize(ModuleManager.ModCamera.ActiveCamera.Position - Vector3D(RSky.Sun.Position)));
      fShadowOffset.Y := 0.5 * (fShadowOffset.Y + RTerrain.GetBlock(fShadowOffset.X, fShadowOffset.Z).MinHeight);

      fSunShadowBuffer.Bind;
      glDepthMask(true);
      glClearColor(0.0, 0.0, 0.0, 0.0);
      glClear(GL_DEPTH_BUFFER_BIT or GL_COLOR_BUFFER_BIT);
      glClearColor(1.0, 1.0, 1.0, 1.0);

      glEnable(GL_DEPTH_TEST);
      glEnable(GL_ALPHA_TEST);
      glAlphaFunc(GL_NOTEQUAL, 0.0);
      glDepthFunc(GL_LESS);
      glDisable(GL_BLEND);

      RTerrain.CurrentShader := RTerrain.ShadowPassShader;
      RTerrain.CurrentShader.Bind;
      RTerrain.CurrentShader.UniformF(RTerrain.Uniforms[RTerrain.CurrentShader.Tag, UNIFORM_TERRAIN_ANY_SHADOWSIZE], ShadowSize);
      RTerrain.CurrentShader.UniformF(RTerrain.Uniforms[RTerrain.CurrentShader.Tag, UNIFORM_TERRAIN_ANY_SHADOWOFFSET], ShadowOffset);
      RTerrain.BorderEnabled := false;
      RTerrain.Render;

      RObjects.ShadowMode := True;
      RObjects.RenderOpaque;
      RObjects.RenderTransparent;
      RObjects.ShadowMode := False;

      fSunShadowBuffer.Unbind;
      glEnable(GL_CULL_FACE);
      end;

    if (UseLightShadows) and (Pass = 0) then
      begin
      glDisable(GL_CULL_FACE);
      glClearColor(0.0, 0.0, 0.0, 500.0);
      glClearDepth(1.0);
      glEnable(GL_DEPTH_TEST);
      glEnable(GL_ALPHA_TEST);
      glAlphaFunc(GL_GREATER, 0.3);
      glAlphaFunc(GL_NOTEQUAL, 0.0);
      glDisable(GL_BLEND);
      glDepthFunc(GL_LEQUAL);
      LightManager.Sync;
      LightManager.CreateShadows;
      glEnable(GL_CULL_FACE);
      end;

    // Lighting pass

    LightBuffer.Bind;
      glDepthMask(true);
      glDisable(GL_DEPTH_TEST);
      glDisable(GL_CULL_FACE);
      glDisable(GL_ALPHA_TEST);
      glDisable(GL_BLEND);

      glClearColor(0.0, 0.0, 0.0, 0.0);
      glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);

      GBuffer.Textures[5].Bind(6);

      if UseScreenSpaceAmbientOcclusion then
        fSSAOBuffer.Textures[0].Bind(5);

      RTerrain.TerrainMap.Bind(4);
      RTerrain.TerrainMap.SetFilter(GL_LINEAR, GL_LINEAR);

      if UseSunShadows then
        fSunShadowBuffer.Textures[0].Bind(2);

      GBuffer.Textures[0].Bind(3);
      GBuffer.Textures[1].Bind(1);
      GBuffer.Textures[2].Bind(0);
      GBuffer.Textures[3].Bind(7);

      SunShader.Bind;
      if UseScreenSpaceAmbientOcclusion then
        SunShader.UniformI(Uniforms[UNIFORM_SUN_USESSAO], 1)
      else
        SunShader.UniformI(Uniforms[UNIFORM_SUN_USESSAO], 0);
      SunShader.UniformF(Uniforms[UNIFORM_SUN_TERRAINSIZE], Park.pTerrain.SizeX / 5, Park.pTerrain.SizeY / 5);
      SunShader.UniformF(Uniforms[UNIFORM_SUN_SHADOWSIZE], ShadowSize);
      SunShader.UniformF(Uniforms[UNIFORM_SUN_SHADOWOFFSET], ShadowOffset);
      SunShader.UniformF(Uniforms[UNIFORM_SUN_BUMPOFFSET], RWater.BumpOffset.X, RWater.BumpOffset.Y);
      DrawFullscreenQuad;
      SunShader.Unbind;

      ModuleManager.ModTexMng.ActivateTexUnit(5);
      ModuleManager.ModTexMng.BindTexture(-1);
      ModuleManager.ModTexMng.ActivateTexUnit(0);


      glEnable(GL_BLEND);
      glBlendFunc(GL_ONE, GL_ONE);
      glEnable(GL_CULL_FACE);

      for i := 0 to high(fLightManager.fRegisteredLights) do
        if fLightManager.fRegisteredLights[i].IsVisible(fFrustum) then
          begin
          fLightManager.fRegisteredLights[i].Bind(1);
          if fLightManager.fRegisteredLights[i].ShadowMap <> nil then
            begin
            fLightManager.fRegisteredLights[i].ShadowMap.Map.Textures[0].Bind(2);
            fLightShaderWithShadow.Bind;
            end
          else
            fLightShader.Bind;
  //         DrawFullscreenQuad;
          fLightManager.fRegisteredLights[i].RenderBoundingCube;
          ModuleManager.ModTexMng.ActivateTexUnit(2);
          ModuleManager.ModTexMng.BindTexture(-1);
          ModuleManager.ModTexMng.ActivateTexUnit(0);
          fLightManager.fRegisteredLights[i].UnBind(1);
          end;
      fLightShader.UnBind;

      glDisable(GL_CULL_FACE);

      glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

      if fIsUnderWater then
        begin
        fCausticShader.Bind;
        fCausticShader.UniformF(Uniforms[UNIFORM_CAUSTIC_TERRAINSIZE], Park.pTerrain.SizeX / 5, Park.pTerrain.SizeY / 5);
        fCausticShader.UniformF(Uniforms[UNIFORM_CAUSTIC_BUMPOFFSET], RWater.BumpOffset.X, RWater.BumpOffset.Y);
        DrawFullscreenQuad;
        fCausticShader.Unbind;
        end;
      
      RTerrain.TerrainMap.UnBind;
      GBuffer.Textures[0].UnBind;
      GBuffer.Textures[1].UnBind;
      GBuffer.Textures[2].UnBind;
      GBuffer.Textures[3].UnBind;

      glDisable(GL_BLEND);

    LightBuffer.Unbind;

    // Sun ray pass

    if UseSunRays then
      begin
      glDisable(GL_BLEND);
      SunRayBuffer.Bind;
      glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);

      GBuffer.Textures[1].Bind(1);
      SpareBuffer.Textures[0].Bind(0);

      fSunRayShader.Bind;
      fSunRayShader.UniformF(Uniforms[UNIFORM_SUNRAY_VECTOFRONT], fVecToFront.X, fVecToFront.Y, fVecToFront.Z);;
      DrawFullscreenQuad;
      fSunRayShader.Unbind;

      SunRayBuffer.Unbind;
      end;

    // Composition

    fSceneBuffer.Bind;
      glDepthMask(true);
      glEnable(GL_DEPTH_TEST);
      glDepthFunc(GL_LEQUAL);
      glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);

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
      CompositionShader.UniformF(Uniforms[UNIFORM_COMPOSITION_FOGCOLOR], FogColor);
      CompositionShader.UniformF(Uniforms[UNIFORM_COMPOSITION_FOGSTRENGTH], FogStrength);
      CompositionShader.UniformF(Uniforms[UNIFORM_COMPOSITION_WATERHEIGHT], 0);
      CompositionShader.UniformF(Uniforms[UNIFORM_COMPOSITION_WATERREFRACTIONMODE], 0);

      GBuffer.Textures[4].Bind(3);
      GBuffer.Textures[3].Bind(4);
      GBuffer.Textures[2].Bind(2);
      SpareBuffer.Textures[0].Bind(0);
      LightBuffer.Textures[0].Bind(7);
      LightBuffer.Textures[1].Bind(6);

      DrawFullscreenQuad;

      CompositionShader.Unbind;

      // Transparent parts only

      LightBuffer.Textures[1].Bind(4);


      glEnable(GL_BLEND);
      glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

      // Autoplants
      glDisable(GL_CULL_FACE);
      glEnable(GL_ALPHA_TEST);
      glAlphaFunc(GL_GREATER, 0.1);
      RAutoplants.CurrentShader := RAutoplants.MaterialPassShader;
      RAutoplants.Render;

      // Objects and particles
      glEnable(GL_CULL_FACE);
      glAlphaFunc(GL_GREATER, 0.0);
      RParticles.CurrentShader := RParticles.MaterialShader;
      RObjects.MaterialMode := True;
      glEnable(GL_CULL_FACE);
      RObjects.RenderTransparent;
      glDisable(GL_CULL_FACE);

      glDisable(GL_BLEND);

      glDisable(GL_DEPTH_TEST);
      glDepthMask(false);

      // Draw grid if required
      if (TGameObjectBuilder(ParkUI.GetWindowByName('object_builder')).Open) and (TGameObjectBuilder(ParkUI.GetWindowByName('object_builder')).GridEnabled) then
        begin
        GBuffer.Textures[2].Bind(2);
        glEnable(GL_BLEND);
        glBlendFunc(GL_ONE, GL_ONE);

        MakeOGLCompatibleMatrix(RotationMatrix(TGameObjectBuilder(ParkUI.GetWindowByName('object_builder')).GridRotation, Vector(0, -1, 0)), @Matrix[0]);

        fGridShader.Bind;
        fGridShader.UniformF(Uniforms[UNIFORM_GRID_OFFSET], TGameObjectBuilder(ParkUI.GetWindowByName('object_builder')).GridOffset);
        fGridShader.UniformF(Uniforms[UNIFORM_GRID_SIZE], TGameObjectBuilder(ParkUI.GetWindowByName('object_builder')).GridSize);
        fGridShader.UniformMatrix4D(Uniforms[UNIFORM_GRID_ROTMAT], @Matrix[0]);

        DrawFullscreenQuad;

        fGridShader.Unbind;

        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glDisable(GL_BLEND);
        GBuffer.Textures[2].Unbind;
        end;
    fSceneBuffer.Unbind;

    if Pass = 0 then
      begin
      SpareBuffer.Bind;
        // Get depth under mouse
        fFullscreenShader.Bind;
        GBuffer.Textures[2].Bind(0);
        DrawFullscreenQuad;
        if fS3DMode = 0 then
          glReadPixels(ModuleManager.ModInputHandler.MouseX * FSAASamples mod (ResX div 2), (ResY - ModuleManager.ModInputHandler.MouseY) * FSAASamples - (ResY div 4), 1, 1, GL_RGBA, GL_FLOAT, @Coord.X)
        else
          glReadPixels(ModuleManager.ModInputHandler.MouseX * FSAASamples, (ResY - ModuleManager.ModInputHandler.MouseY) * FSAASamples, 1, 1, GL_RGBA, GL_FLOAT, @Coord.X);
        if VecLengthNoRoot(fSelectionRay + fSelectionStart) < 0.01 then
          fSelectionRay := Vector3D(Coord) - fSelectionStart;
        fFullscreenShader.Unbind;

      SpareBuffer.Unbind;
      end;

    // Under-water view
    if fIsUnderWater then
      begin
      fSpareBuffer.Bind;
      glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
      fUnderWaterShader.Bind;
      fUnderWaterShader.UniformF(Uniforms[UNIFORM_UNDERWATER_HEIGHT], fWaterHeight);
      fUnderWaterShader.UniformF(Uniforms[UNIFORM_UNDERWATER_VIEWPOINT], ViewPoint.X, ViewPoint.Y, ViewPoint.Z);
      fUnderWaterShader.UniformF(Uniforms[UNIFORM_UNDERWATER_BUMPOFFSET], RWater.BumpOffset.X, RWater.BumpOffset.Y);

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

    // Set up focal blur
    with ModuleManager.ModCamera do
      fVecToFront := Normalize(Vector(Sin(DegToRad(ActiveCamera.Rotation.Y)) * Cos(DegToRad(ActiveCamera.Rotation.X)),
                                    -Sin(DegToRad(ActiveCamera.Rotation.X)),
                                    -Cos(DegToRad(ActiveCamera.Rotation.Y)) * Cos(DegToRad(ActiveCamera.Rotation.X))));

    fFocusDistance := Coord.W;

    // Focal Blur pass
    if UseFocalBlur then
      begin
      glDisable(GL_BLEND);

      FocalBlurBuffer.Bind;
      glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);

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
      fFocalBlurShader.UniformF(Uniforms[UNIFORM_FOCALBLUR_FOCUSDISTANCE], FocusDistance);
      fFocalBlurShader.UniformF(Uniforms[UNIFORM_FOCALBLUR_SCREEN], ResX, ResY);
      fFocalBlurShader.UniformF(Uniforms[UNIFORM_FOCALBLUR_STRENGTH], 1.0);
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
      fHDRAverageShader.UniformI(Uniforms[UNIFORM_HDRAVERAGE_SIZE], BufferSizeY);
      fHDRAverageShader.UniformI(Uniforms[UNIFORM_HDRAVERAGE_DIR], 0, 1);
      DrawFullscreenQuad;
    fHDRBuffer.Unbind;

    fHDRBuffer2.Bind;
      fHDRBuffer.Textures[0].Bind(0);
      fHDRAverageShader.UniformI(Uniforms[UNIFORM_HDRAVERAGE_SIZE], BufferSizeX);
      fHDRAverageShader.UniformI(Uniforms[UNIFORM_HDRAVERAGE_DIR], 1, 0);
      DrawFullscreenQuad;
    fHDRBuffer2.Unbind;

    fHDRAverageShader.Unbind;

    // Bloom pass

    if BloomFactor > 0 then
      begin
      glDisable(GL_BLEND);

      BloomBuffer.Bind;

      glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);

      fBloomShader.Bind;
      fHDRBuffer2.Textures[0].Bind(1);
      fSceneBuffer.Textures[0].Bind(0);
      DrawFullscreenQuad;
      fBloomShader.Unbind;

      BloomBuffer.Unbind;

      fBloomBlurShader.Bind;

      fBloomBlurShader.UniformF(Uniforms[UNIFORM_BLOOMBLUR_BLURDIRECTION], 1.0 / BloomBuffer.Width * SSAOSize, 0.0);
      BloomBuffer.Textures[0].Bind(0);

      fTmpBloomBuffer.Bind;
      DrawFullscreenQuad;
      fTmpBloomBuffer.Unbind;

      fBloomBlurShader.UniformF(Uniforms[UNIFORM_BLOOMBLUR_BLURDIRECTION], 0.0, 1.0 / BloomBuffer.Height * SSAOSize);
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

    if (EnableS3D) and (fS3DMode = 1) then
      case Pass of
        0: glColorMask(true, false, false, true);
        1: glColorMask(false, true, true, true);
        end;
    if (UseMotionBlur) and (not CaptureNextFrame) then
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
      if (EnableS3D) and (fS3DMode = 0) then
        begin
        if fS3DInvert then
          DrawFullscreenQuad(Vector(1 - Pass, 0.5), Vector(0.5, 0.5))
        else
          DrawFullscreenQuad(Vector(Pass, 0.5), Vector(0.5, 0.5));
        end
      else
        DrawFullscreenQuad;
      MotionBlurBuffer.Textures[0].Unbind;

      fFullscreenShader.Unbind;
      end
    else
      begin
      fAAShader.Bind;

      glColor4f(1, 1, 1, 1);

      fHDRBuffer2.Textures[0].Bind(1);
      fSceneBuffer.Textures[0].Bind(0);
      if (EnableS3D) and (fS3DMode = 0) then
        DrawFullscreenQuad(Vector(1 - Pass, 0.5), Vector(0.5, 0.5))
      else
        DrawFullscreenQuad;

      fAAShader.Unbind;
      end;

    if (UseLensFlare) and (not fEnableS3D) then
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

    glColorMask(true, true, true, true);

    glDisable(GL_BLEND);

    ModuleManager.ModCamera.ActiveCamera.Position := OrigCamPos;
    end;


  inc(fFrameID);
//   writeln(glGetError());

  if (CaptureNextFrame) and not (Park.ScreenCaptureTool.WithUI) then
    begin
    CaptureNextFrame := False;
    EventManager.CallEvent('TRenderer.CaptureNow', self, nil);
    end;
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
    SetConfVal('ssao.indirectlighting', '0');
    SetConfVal('ssao.samples', '5');
    SetConfVal('ssao.rings', '6');
    SetConfVal('ssao.size', '0.25');
    SetConfVal('refractions', '1');
    SetConfVal('shadows', '0');
    SetConfVal('shadows.samples', '1');
    SetConfVal('shadows.blursamples', '2');
    SetConfVal('shadows.lights.samples', '1');
    SetConfVal('shadows.lights.blursamples', '2');
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
    SetConfVal('s3d', '0');
    SetConfVal('s3d.invert', '0');
    SetConfVal('s3d.mode', '0');
    SetConfVal('s3d.strength', '1');
    SetConfVal('pom', '0');
    SetConfVal('pom.shadows', '0');
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
  fUseScreenSpaceIndirectLighting := GetConfVal('ssao.indirectlighting') = '1';
  fUseLensFlare := GetConfVal('lensflare') = '1';
  fShadowBufferSamples := StrToFloatWD(GetConfVal('shadows.samples'), 1);
  fShadowBlurSamples := StrToIntWD(GetConfVal('shadows.blursamples'), 2);
  fMaxShadowPasses := StrToIntWD(GetConfVal('shadows.maxpasses'), 2);
  fLightShadowBufferSamples := StrToFloatWD(GetConfVal('shadows.lights.samples'), 1);
  fLightShadowBlurSamples := StrToIntWD(GetConfVal('shadows.lights.blursamples'), 2);
  fMotionBlurStrength := StrToFloatWD(GetConfVal('motionblur.strength'), 0.05);
  fTerrainTesselationDistance := StrToFloatWD(GetConfVal('terrain.tesselationdistance'), 15);
  fTerrainDetailDistance := StrToFloatWD(GetConfVal('terrain.detaildistance'), 60);
  fTerrainBumpmapDistance := StrToFloatWD(GetConfVal('terrain.bumpmapdistance'), 60);
  fWaterReflectionBufferSamples := StrToFloatWD(GetConfVal('water.samples'), 0.5);
  fSSAOSamples := StrToIntWD(GetConfVal('ssao.samples'), 5);
  fSSAORings := StrToIntWD(GetConfVal('ssao.rings'), 6);
  fSSAOSize := StrToFloatWD(GetConfVal('ssao.size'), 0.25);
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
  fEnableS3D := GetConfVal('s3d') = '1';
  fEnablePOM := GetConfVal('pom') = '1';
  fEnablePOMSelfShadow := GetConfVal('pom.shadows') = '1';
  fS3DMode := -1;
  if fEnableS3D then
    fS3DMode := StrToIntWD(GetConfVal('s3d.mode'), 0);
  fS3DInvert := GetConfVal('s3d.invert') = '1';
  fS3DStrength := StrToFloatWD(GetConfVal('s3d.strength'), 1.0);

  ModuleManager.ModShdMng.SetVar('owe.samples', fFSAASamples);
  ModuleManager.ModShdMng.SetVar('owe.shadows.blur', fShadowBlurSamples);
  ModuleManager.ModShdMng.SetVar('owe.shadows.light.blur', fLightShadowBlurSamples);
  ModuleManager.ModShdMng.SetVar('owe.ssao.rings', fSSAORings);
  ModuleManager.ModShdMng.SetVar('owe.ssao.ringsamples', fSSAOSamples);
  ModuleManager.ModShdMng.SetVar('owe.shadows.sun', 0);
  ModuleManager.ModShdMng.SetVar('owe.shadows.light', 0);
  ModuleManager.ModShdMng.SetVar('owe.ssao', 0);
  ModuleManager.ModShdMng.SetVar('owe.ssao.indirectlighting', 0);
  ModuleManager.ModShdMng.SetVar('owe.terrain.tesselation', 0);
  ModuleManager.ModShdMng.SetVar('owe.terrain.bumpmap', 0);
  ModuleManager.ModShdMng.SetVar('owe.gamma', 0);
  ModuleManager.ModShdMng.SetVar('owe.pom', 0);
  ModuleManager.ModShdMng.SetVar('owe.pom.shadows', 0);
  ModuleManager.ModShdMng.SetVar('owe.s3d', 0);
  ModuleManager.ModShdMng.SetVar('owe.s3d.mode', fS3DMode);
  if fUseSunShadows then
    ModuleManager.ModShdMng.SetVar('owe.shadows.sun', 1);
  if fUseLightShadows then
    ModuleManager.ModShdMng.SetVar('owe.shadows.light', 1);
  if fUseScreenSpaceAmbientOcclusion then
    begin
    ModuleManager.ModShdMng.SetVar('owe.ssao', 1);
    if fUseScreenSpaceIndirectLighting then
      ModuleManager.ModShdMng.SetVar('owe.ssao.indirectlighting', 1);
    end;
  if fTerrainTesselationDistance > 0 then
    ModuleManager.ModShdMng.SetVar('owe.terrain.tesselation', 1);
  if fTerrainBumpmapDistance > 0 then
    ModuleManager.ModShdMng.SetVar('owe.terrain.bumpmap', 1);
  if fGamma <> 1 then
    ModuleManager.ModShdMng.SetVar('owe.gamma', 1);
  if fEnableS3D then
    ModuleManager.ModShdMng.SetVar('owe.s3d', 1);
  if fEnablePOM then
    ModuleManager.ModShdMng.SetVar('owe.pom', 1);
  if fEnablePOMSelfShadow then
    ModuleManager.ModShdMng.SetVar('owe.pom.shadows', 1);
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
  SetConfVal('ssao.indirectlighting', fOWEConfigInterface.fSSAOIL.Checked);
  SetConfVal('lensflare', fOWEConfigInterface.fLensFlare.Checked);
  SetConfVal('shadows.samples', Round(fOWEConfigInterface.fShadowSamples.Value));
  SetConfVal('shadows.blursamples', Round(fOWEConfigInterface.fShadowBlurSamples.Value));
  SetConfVal('shadows.lights.samples', Round(fOWEConfigInterface.fLightShadowSamples.Value));
  SetConfVal('shadows.lights.blursamples', Round(fOWEConfigInterface.fLightShadowBlurSamples.Value));
  SetConfVal('shadows.maxpasses', fOWEConfigInterface.fShadowMaxPasses.Value);
  SetConfVal('motionblur.strength', fOWEConfigInterface.fMotionBlurStrength.Value);
  SetConfVal('terrain.tesselationdistance', fOWEConfigInterface.fTerrainTesselationDistance.Value);
  SetConfVal('terrain.detaildistance', fOWEConfigInterface.fTerrainDetailDistance.Value);
  SetConfVal('terrain.bumpmapdistance', fOWEConfigInterface.fTerrainBumpmapDistance.Value);
  SetConfVal('water.samples', fOWEConfigInterface.fWaterSamples.Value);
  SetConfVal('ssao.samples', Round(fOWEConfigInterface.fSSAOSamples.Value));
  SetConfVal('ssao.rings', Round(fOWEConfigInterface.fSSAORings.Value));
  SetConfVal('ssao.size', fOWEConfigInterface.fSSAOSize.Value);
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
  SetConfVal('pom', fOWEConfigInterface.fPOM.Checked);
  SetConfVal('pom.shadows', fOWEConfigInterface.fPOMShadows.Checked);
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

function TModuleRendererOWE.Capture: TByteStream;
var
  ResX, ResY: Integer;
  A: Byte;
  B, C: PByte;
  i, j: Integer;
  Tex: TTexImage;
  ByPP: Integer;
begin
  ModuleManager.ModGLContext.GetResolution(ResX, ResY);

  ByPP := 4;
  SetLength(Result.Data, 18 + ResX * ResY * ByPP + 26);
  Result.Data[0] := 0;
  Result.Data[1] := 0;
  Result.Data[2] := 2;
  Word((@Result.Data[3])^) := 0;
  Word((@Result.Data[5])^) := 0;
  Result.Data[7] := 32;
  Word((@Result.Data[8])^) := 0;
  Word((@Result.Data[10])^) := 0;
  Word((@Result.Data[12])^) := ResX;
  Word((@Result.Data[14])^) := ResY;
  Result.Data[16] := 32;
  Result.Data[17] := 0;
  
  glFlush;
  glReadPixels(0, 0, ResX, ResY, GL_BGRA, GL_UNSIGNED_BYTE, @Result.Data[18]);
  
  DWord((@Result.Data[Length(Result.Data) - 26])^) := 0;
  DWord((@Result.Data[Length(Result.Data) - 22])^) := 0;
  Result.Data[Length(Result.Data) - 18] := Ord('T');
  Result.Data[Length(Result.Data) - 17] := Ord('R');
  Result.Data[Length(Result.Data) - 16] := Ord('U');
  Result.Data[Length(Result.Data) - 15] := Ord('E');
  Result.Data[Length(Result.Data) - 14] := Ord('V');
  Result.Data[Length(Result.Data) - 13] := Ord('I');
  Result.Data[Length(Result.Data) - 12] := Ord('S');
  Result.Data[Length(Result.Data) - 11] := Ord('I');
  Result.Data[Length(Result.Data) - 10] := Ord('O');
  Result.Data[Length(Result.Data) - 09] := Ord('N');
  Result.Data[Length(Result.Data) - 08] := Ord('-');
  Result.Data[Length(Result.Data) - 07] := Ord('X');
  Result.Data[Length(Result.Data) - 06] := Ord('F');
  Result.Data[Length(Result.Data) - 05] := Ord('I');
  Result.Data[Length(Result.Data) - 04] := Ord('L');
  Result.Data[Length(Result.Data) - 03] := Ord('E');
  Result.Data[Length(Result.Data) - 02] := Ord('.');
  Result.Data[Length(Result.Data) - 01] := 0;
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