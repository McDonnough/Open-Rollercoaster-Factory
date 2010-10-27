unit m_renderer_owe;

interface

uses
  Classes, SysUtils, m_renderer_class, DGLOpenGL, g_park, u_math, u_vectors,
  m_renderer_owe_camera, math, m_texmng_class, m_shdmng_class, u_functions, m_renderer_owe_frustum,
  m_renderer_owe_sky, m_renderer_owe_classes, u_scene, m_renderer_owe_lights, m_renderer_owe_terrain;

type
  TModuleRendererOWE = class(TModuleRendererClass)
    protected
      fRendererSky: TRSky;
      fRendererCamera: TRCamera;
      fRendererTerrain: TRTerrain;
      fLightManager: TLightManager;
      fGBuffer, fLightBuffer, fSceneBuffer, fSSAOBuffer, fSunRayBuffer, fBloomBuffer: TFBO;
      fFSAASamples: Integer;
      fReflectionDepth, fReflectionUpdateInterval: Integer;
      fUseSunShadows, fUseLightShadows, fUseSunRays, fUseRefractions: Boolean;
      fUseBloom, fUseScreenSpaceAmbientOcclusion, fUseMotionBlur, fUseFocalBlur: Boolean;
      fLODDistanceOffset, fLODDistanceFactor: Single;
      fShadowBufferSamples: Single;
      fSubdivisionCuts: Integer;
      fSubdivisionDistance: Single;
      fBufferSizeX, fBufferSizeY: Integer;
      fSSAOSamples, fShadowBlurSamples: Integer;
      fTmpShadowBuffer: TFBO;
      fMaxShadowPasses: Integer;
      fTerrainTesselationDistance, fTerrainBumpmapDistance: Single;
      fFullscreenShader, fAAShader: TShader;
    public
      property LightManager: TLightManager read fLightManager;
      property RCamera: TRCamera read fRendererCamera;
      property RSky: TRSky read fRendererSky;
      property RTerrain: TRTerrain read fRendererTerrain;
      property GBuffer: TFBO read fGBuffer;
      property LightBuffer: TFBO read fLightBuffer;
      property SceneBuffer: TFBO read fSceneBuffer;
      property SSAOBuffer: TFBO read fSSAOBuffer;
      property SunRayBuffer: TFBO read fSunRayBuffer;
      property BloomBuffer: TFBO read fBloomBuffer;
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
      property TerrainTesselationDistance: Single read fTerrainTesselationDistance;
      property TerrainBumpmapDistance: Single read fTerrainBumpmapDistance;
      procedure PostInit;
      procedure Unload;
      procedure RenderScene;
      procedure CheckModConf;
      constructor Create;
      destructor Free;
    end;

implementation

uses
  m_varlist, u_events, main;

procedure TModuleRendererOWE.PostInit;
var
  ResX, ResY: Integer;
begin
  ModuleManager.ModGLContext.GetResolution(ResX, ResY);
  fBufferSizeX := ResX * FSAASamples;
  fBufferSizeY := ResY * FSAASamples;

  fGBuffer := TFBO.Create(BufferSizeX, BufferSizeY, true);
  fGBuffer.AddTexture(GL_RGBA32F_ARB, GL_NEAREST, GL_NEAREST);  // Vertex and depth
  fGBuffer.AddTexture(GL_RGB16F_ARB, GL_NEAREST, GL_NEAREST);   // Normals

  fLightBuffer := TFBO.Create(BufferSizeX, BufferSizeY, false);
  fLightBuffer.AddTexture(GL_RGBA, GL_NEAREST, GL_NEAREST);     // Colors, Specular

  fSceneBuffer := TFBO.Create(BufferSizeX, BufferSizeY, true);
  fSceneBuffer.AddTexture(GL_RGB, GL_NEAREST, GL_NEAREST);      // Composed image

  if UseScreenSpaceAmbientOcclusion then
    begin
    fSSAOBuffer := TFBO.Create(BufferSizeX, BufferSizeY, false);
    fSSAOBuffer.AddTexture(GL_RGB, GL_NEAREST, GL_NEAREST);     // Screen Space Ambient Occlusion
    end
  else
    fSSAOBuffer := nil;

  if (UseBloom) or (UseFocalBlur) then
    begin
    fBloomBuffer := TFBO.Create(BufferSizeX, BufferSizeY, false);
    fBloomBuffer.AddTexture(GL_RGB, GL_NEAREST, GL_NEAREST);    // Pseudo-HDR/Color Bleeding
    end
  else
    fBloomBuffer := nil;

  if UseSunRays then
    begin
    fSunRayBuffer := TFBO.Create(BufferSizeX, BufferSizeY, false);
    fSunRayBuffer.AddTexture(GL_RGBA, GL_NEAREST, GL_NEAREST);  // Color overlay
    end
  else
    fSunRayBuffer := nil;

  if UseSunShadows then
    begin
    fTmpShadowBuffer := TFBO.Create(Round(ResX * ShadowBufferSamples), Round(ResY * ShadowBufferSamples), false);
    fTmpShadowBuffer.AddTexture(GL_RGBA16F_ARB, GL_NEAREST, GL_NEAREST);  // Color, Distance
    end
  else
    fTmpShadowBuffer := nil;

  fLightManager := TLightManager.Create;
  fRendererCamera := TRCamera.Create;
  fRendererSky := TRSky.Create;
  fRendererTerrain := TRTerrain.Create;

  fFullscreenShader := TShader.Create('orcf-world-engine/postprocess/fullscreen.vs', 'orcf-world-engine/postprocess/fullscreen.fs');
  fFullscreenShader.UniformI('Texture', 0);
  fAAShader := TShader.Create('orcf-world-engine/postprocess/fullscreen.vs', 'orcf-world-engine/postprocess/fsaa.fs');
  fAAShader.UniformI('Texture', 0);
  fAAShader.UniformI('ScreenSize', ResX, ResY);
  fAAShader.UniformI('Samples', FSAASamples);
end;

procedure TModuleRendererOWE.Unload;
var
  i: Integer;
begin
  fAAShader.Free;
  fFullscreenShader.Free;

  fGBuffer.Free;
  fLightBuffer.Free;
  fSceneBuffer.Free;
  if fSSAOBuffer <> nil then
    fSSAOBuffer.Free;
  if fBloomBuffer <> nil then
    fBloomBuffer.Free;
  if fSunRayBuffer <> nil then
    fSunRayBuffer.Free;
  if fTmpShadowBuffer <> nil then
    fTmpShadowBuffer.Free;

  fRendererTerrain.Free;
  fRendererSky.Free;
  fRendererCamera.Free;
  fLightManager.Free;
end;

procedure TModuleRendererOWE.RenderScene;
begin
  glMatrixMode(GL_PROJECTION);
  ModuleManager.ModGLMng.SetUp3DMatrix;
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;

  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT);

  RCamera.ApplyRotation(Vector(1, 1, 1));
  RCamera.ApplyTransformation(Vector(1, 1, 1));

  // Geometry pass

  GBuffer.Bind;
  GBuffer.Unbind;

  // SSAO pass

  if UseScreenSpaceAmbientOcclusion then
    begin
    SSAOBuffer.Bind;
    SSAOBuffer.Unbind;
    end;

  // Lighting pass

  // Material pass

  // Focal Blur pass

  if UseFocalBlur then
    begin
    BloomBuffer.Bind;
    BloomBuffer.Unbind;
    end;

  // Bloom pass

  if UseBloom then
    begin
    BloomBuffer.Bind;
    BloomBuffer.Unbind;
    end;

  // Sun ray pass

  if UseSunRays then
    begin
    SunRayBuffer.Bind;
    SunRayBuffer.Unbind;
    end;

  // Composition

  fSceneBuffer.Bind;
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT);
  glUseProgram(0);
  glColor4f(1, 1, 1, 1);

  glDisable(GL_TEXTURE_2D);

  RTerrain.CurrentShader := RTerrain.GeometryPassShader;
  RTerrain.Render;

  glEnable(GL_TEXTURE_2D);
  fSceneBuffer.Unbind;

  // Output

  fAAShader.Bind;

  fSceneBuffer.Textures[0].Bind(0);
  glBegin(GL_QUADS);
    glVertex2f(-1, -1);
    glVertex2f( 1, -1);
    glVertex2f( 1,  1);
    glVertex2f(-1,  1);
  glEnd;
  fSceneBuffer.Textures[0].Unbind;

  fAAShader.Unbind;
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
    SetConfVal('shadows.blursamples', '2');
    SetConfVal('shadows.maxpasses', '0');
    SetConfVal('bloom', '1');
    SetConfVal('focalblur', '1');
    SetConfVal('motionblur', '1');
    SetConfVal('sunrays', '1');
    SetConfVal('lod.distanceoffset', '0');
    SetConfVal('lod.distancefactor', '1');
    SetConfVal('subdiv.cuts', '2');
    SetConfVal('subdiv.distance', '10');
    SetConfVal('terrain.tesselationdistance', '25');
    SetConfVal('terrain.bumpmapdistance', '60');
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
  fShadowBufferSamples := StrToFloatWD('shadows.samples', 1);
  fShadowBlurSamples := StrToIntWD('shadows.samples', 2);
  fMaxShadowPasses := StrToIntWD('shadows.maxbuffers', 100);
  fTerrainTesselationDistance := StrToFloatWD(GetConfVal('terrain.tesselationdistance'), 25);
  fTerrainBumpmapDistance := StrToFloatWD(GetConfVal('terrain.bumpmapdistance'), 60);
  fSSAOSamples := StrToIntWD(GetConfVal('ssao.samples'), 100);
  fLODDistanceOffset := StrToIntWD(GetConfVal('lod.distanceoffset'), 0);
  fLODDistanceFactor := StrToIntWD(GetConfVal('lod.distancefactor'), 1);
  fSubdivisionCuts := StrToIntWD(GetConfVal('subdiv.cuts'), 2);
  fSubdivisionDistance := StrToIntWD(GetConfVal('subdiv.distance'), 10);
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