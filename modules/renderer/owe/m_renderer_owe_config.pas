unit m_renderer_owe_config;

interface

uses
  SysUtils, Classes, m_gui_class, m_settings_class, m_gui_label_class, m_gui_checkbox_class, m_gui_button_class, m_gui_slider_class;

type
  TOWEConfigInterface = class
    public
      fReflectionPanel, fWaterPanel, fNormalRenderingPanel, fEffectPanel: TLabel;
      fConfigurationInterface: TConfigurationInterfaceBase;
      fSamples, fReflectionRealtimeMinimum, fReflectionRealtimeDistanceExponent, fReflectionRealtimeSize, fReflectionEnvMapSize: TSlider;
      fReflectionRenderTerrainTesselationDistance, fReflectionRenderTerrainDetailDistance, fReflectionRenderTerrainBumpmapDistance: TSlider;
      fReflectionRenderTerrain, fReflectionRenderAutoplants, fReflectionRenderObjects, fReflectionRenderParticles: TCheckBox;
      fReflectionRenderDistanceFactor, fReflectionRenderDistanceOffset: TSlider;
      fReflectionRealtimeUpdateInterval, fReflectionEnvMapUpdateInterval: TSlider;
      fSSAO: TCheckBox;
      fSSAOSamples: TSlider;
      fUseSunShadows, fUseLightShadows: TCheckBox;
      fShadowSamples, fShadowBlurSamples: TSlider;
      fBloom: TSlider;
      fFocalBlur: TCheckBox;
      fMotionBlur: TCheckBox;
      fMotionBlurStrength: TSlider;
      fSunRays: TCheckBox;
      fLODDistanceFactor, fLODDistanceOffset: TSlider;
      fTerrainTesselationDistance, fTerrainDetailDistance, fTerrainBumpmapDistance: TSlider;
      fAutoplantDistance, fAutoplantCount: TSlider;
      fLensFlare: TCheckBox;
      fGamma: TSlider;
      fWaterSamples: TSlider;
      fWaterReflectTerrain, fWaterReflectParticles, fWaterReflectAutoplants, fWaterReflectSky, fWaterReflectObjects: TCheckBox;
      fWaterRefractTerrain, fWaterRefractParticles, fWaterRefractAutoplants, fWaterRefractObjects: TCheckBox;
      constructor Create(Parent: TGUIComponent);
      destructor Free;
    end;

implementation

uses
  m_varlist;

constructor TOWEConfigInterface.Create(Parent: TGUIComponent);
begin
  fConfigurationInterface := TConfigurationInterfaceBase.Create(Parent);

  fReflectionPanel := TLabel.Create(fConfigurationInterface.Surface);
  with fReflectionPanel do
    begin
    Left := 0;
    Top := 640;
    Height := 248;
    Width := 700 - 16;
    Size := 24;
    Caption := ' Realtime reflection';
    end;
  fWaterPanel := TLabel.Create(fConfigurationInterface.Surface);
  with fWaterPanel do
    begin
    Left := 0;
    Top := 416;
    Height := 192;
    Width := 700 - 16;
    Size := 24;
    Caption := ' Water';
    end;
  fNormalRenderingPanel := TLabel.Create(fConfigurationInterface.Surface);
  with fNormalRenderingPanel do
    begin
    Left := 0;
    Top := 32;
    Height := 224;
    Width := 700 - 16;
    Size := 24;
    Caption := ' Normal rendering';
    end;
  fEffectPanel := TLabel.Create(fConfigurationInterface.Surface);
  with fEffectPanel do
    begin
    Left := 0;
    Top := 256;
    Height := 160;
    Width := 700 - 16;
    Size := 24;
    Caption := ' Effects';
    end;

  // General

  with TLabel.Create(fConfigurationInterface.Surface) do
    begin
    Top := 0;
    Left := 8;
    Width := 200;
    Height := 32;
    Size := 16;
    Caption := 'Antialiasing samples:';
    end;
  fSamples := TSlider.Create(fConfigurationInterface.Surface);
  with fSamples do
    begin
    Top := 0;
    Left := 208;
    Height := 32;
    Width := 122;
    Digits := 0;
    Min := 1;
    Max := 4;
    Value := ModuleManager.ModRenderer.FSAASamples;
    end;
  with TLabel.Create(fConfigurationInterface.Surface) do
    begin
    Top := 0;
    Left := 338;
    Width := 200;
    Height := 32;
    Size := 16;
    Caption := 'Gamma:';
    end;
  fGamma := TSlider.Create(fConfigurationInterface.Surface);
  with fGamma do
    begin
    Top := 0;
    Left := 538;
    Height := 32;
    Width := 122;
    Digits := 1;
    Min := 0.1;
    Max := 4;
    Value := ModuleManager.ModRenderer.Gamma;
    end;

  // Reflections

  with TLabel.Create(fReflectionPanel) do
    begin
    Top := 24;
    Left := 8;
    Width := 200;
    Height := 32;
    Size := 16;
    Caption := 'Minimum reflectivity for realtime reflection:';
    end;
  fReflectionRealtimeMinimum := TSlider.Create(fReflectionPanel);
  with fReflectionRealtimeMinimum do
    begin
    Top := 24;
    Left := 208;
    Width := 122;
    Height := 32;
    Digits := 2;
    Min := 0;
    Max := 1;
    Value := ModuleManager.ModRenderer.ReflectionRealtimeMinimum;
    end;

  with TLabel.Create(fReflectionPanel) do
    begin
    Top := 24;
    Left := 338;
    Width := 200;
    Height := 32;
    Size := 16;
    Caption := 'Influence of distance:';
    end;
  fReflectionRealtimeDistanceExponent := TSlider.Create(fReflectionPanel);
  with fReflectionRealtimeDistanceExponent do
    begin
    Top := 24;
    Left := 538;
    Width := 122;
    Height := 32;
    Digits := 3;
    Min := 0;
    Max := 0.05;
    Value := ModuleManager.ModRenderer.ReflectionRealtimeDistanceExponent;
    end;

  with TLabel.Create(fReflectionPanel) do
    begin
    Top := 56;
    Left := 8;
    Width := 200;
    Height := 32;
    Size := 16;
    Caption := 'Reflection map size:';
    end;
  fReflectionRealtimeSize := TSlider.Create(fReflectionPanel);
  with fReflectionRealtimeSize do
    begin
    top := 56;
    Left := 208;
    Width := 122;
    Height := 32;
    Digits := 0;
    Min := 64;
    Max := 512;
    Value := ModuleManager.ModRenderer.ReflectionSize;
    end;

  with TLabel.Create(fReflectionPanel) do
    begin
    Top := 56;
    Left := 338;
    Width := 200;
    Height := 32;
    Size := 16;
    Caption := 'Environment map size:';
    end;
  fReflectionEnvMapSize := TSlider.Create(fReflectionPanel);
  with fReflectionEnvMapSize do
    begin
    top := 56;
    Left := 538;
    Width := 122;
    Height := 32;
    Digits := 0;
    Min := 64;
    Max := 512;
    Value := ModuleManager.ModRenderer.EnvMapSize;
    end;

  with TLabel.Create(fReflectionPanel) do
    begin
    Top := 96;
    Left := 48;
    Width := 200;
    Height := 32;
    Size := 16;
    Caption := 'Reflect Terrain';
    end;
  fReflectionRenderTerrain := TCheckBox.Create(fReflectionPanel);
  with fReflectionRenderTerrain do
    begin
    Top := 88;
    Left := 8;
    Width := 32;
    Height := 32;
    Checked := ModuleManager.ModRenderer.ReflectionRenderTerrain;
    end;
  
  with TLabel.Create(fReflectionPanel) do
    begin
    Top := 96;
    Left := 378;
    Width := 200;
    Height := 32;
    Size := 16;
    Caption := 'Reflect Autoplants';
    end;
  fReflectionRenderAutoplants := TCheckBox.Create(fReflectionPanel);
  with fReflectionRenderAutoplants do
    begin
    Top := 88;
    Left := 338;
    Width := 32;
    Height := 32;
    Checked := ModuleManager.ModRenderer.ReflectionRenderAutoplants;
    end;

  with TLabel.Create(fReflectionPanel) do
    begin
    Top := 128;
    Left := 48;
    Width := 200;
    Height := 32;
    Size := 16;
    Caption := 'Reflect Objects';
    end;
  fReflectionRenderObjects := TCheckBox.Create(fReflectionPanel);
  with fReflectionRenderObjects do
    begin
    Top := 120;
    Left := 8;
    Width := 32;
    Height := 32;
    Checked := ModuleManager.ModRenderer.ReflectionRenderObjects;
    end;

  with TLabel.Create(fReflectionPanel) do
    begin
    Top := 128;
    Left := 378;
    Width := 200;
    Height := 32;
    Size := 16;
    Caption := 'Reflect Particles';
    end;
  fReflectionRenderParticles := TCheckBox.Create(fReflectionPanel);
  with fReflectionRenderParticles do
    begin
    Top := 120;
    Left := 338;
    Width := 32;
    Height := 32;
    Checked := ModuleManager.ModRenderer.ReflectionRenderParticles;
    end;

  with TLabel.Create(fReflectionPanel) do
    begin
    Top := 152;
    Left := 8;
    Width := 200;
    Height := 32;
    Size := 16;
    Caption := 'Maximum distance for high terrain LOD:';
    end;
  fReflectionRenderTerrainTesselationDistance := TSlider.Create(fReflectionPanel);
  with fReflectionRenderTerrainTesselationDistance do
    begin
    top := 152;
    Left := 208;
    Width := 122;
    Height := 32;
    Digits := 0;
    Min := 0;
    Max := 128;
    Value := ModuleManager.ModRenderer.ReflectionTerrainTesselationDistance;
    end;
  
  with TLabel.Create(fReflectionPanel) do
    begin
    Top := 152;
    Left := 338;
    Width := 200;
    Height := 32;
    Size := 16;
    Caption := 'Maximum distance for medium terrain LOD:';
    end;
  fReflectionRenderTerrainDetailDistance := TSlider.Create(fReflectionPanel);
  with fReflectionRenderTerrainDetailDistance do
    begin
    top := 152;
    Left := 538;
    Width := 122;
    Height := 32;
    Digits := 0;
    Min := 0;
    Max := 512;
    Value := ModuleManager.ModRenderer.ReflectionTerrainDetailDistance;
    end;

  with TLabel.Create(fReflectionPanel) do
    begin
    Top := 184;
    Left := 8;
    Width := 200;
    Height := 32;
    Size := 16;
    Caption := 'Distance factor for object LOD:';
    end;
  fReflectionRenderDistanceFactor := TSlider.Create(fReflectionPanel);
  with fReflectionRenderDistanceFactor do
    begin
    top := 184;
    Left := 208;
    Width := 122;
    Height := 32;
    Digits := 1;
    Min := 0.1;
    Max := 10;
    Value := ModuleManager.ModRenderer.ReflectionLODDistanceFactor;
    end;
    
  with TLabel.Create(fReflectionPanel) do
    begin
    Top := 184;
    Left := 338;
    Width := 200;
    Height := 32;
    Size := 16;
    Caption := 'Distance offset for object LOD:';
    end;
  fReflectionRenderDistanceOffset := TSlider.Create(fReflectionPanel);
  with fReflectionRenderDistanceOffset do
    begin
    top := 184;
    Left := 538;
    Width := 122;
    Height := 32;
    Digits := 1;
    Min := -20;
    Max := 20;
    Value := ModuleManager.ModRenderer.ReflectionLODDistanceOffset;
    end;

  with TLabel.Create(fReflectionPanel) do
    begin
    Top := 216;
    Left := 8;
    Width := 200;
    Height := 32;
    Size := 16;
    Caption := 'Reflection map update interval:';
    end;
  fReflectionRealtimeUpdateInterval := TSlider.Create(fReflectionPanel);
  with fReflectionRealtimeUpdateInterval do
    begin
    top := 216;
    Left := 208;
    Width := 122;
    Height := 32;
    Digits := 0;
    Min := 1;
    Max := 10;
    Value := ModuleManager.ModRenderer.ReflectionUpdateInterval;
    end;
  
  with TLabel.Create(fReflectionPanel) do
    begin
    Top := 216;
    Left := 338;
    Width := 200;
    Height := 32;
    Size := 16;
    Caption := 'Environment map update interval:';
    end;
  fReflectionEnvMapUpdateInterval := TSlider.Create(fReflectionPanel);
  with fReflectionEnvMapUpdateInterval do
    begin
    Top := 216;
    Left := 538;
    Width := 122;
    Height := 32;
    Digits := -1;
    Min := 10;
    Max := 1000;
    Value := ModuleManager.ModRenderer.EnvironmentMapInterval;
    end;

  // Effects
  with TLabel.Create(fEffectPanel) do
    begin
    Top := 24;
    Left := 48;
    Width := 200;
    Height := 32;
    Size := 16;
    Caption := 'Screen Space Ambient Occlusion (SSAO)';
    end;
  fSSAO := TCheckBox.Create(fEffectPanel);
  with fSSAO do
    begin
    Top := 24;
    Left := 8;
    Width := 32;
    Height := 32;
    Checked := ModuleManager.ModRenderer.UseScreenSpaceAmbientOcclusion;
    end;
  with TLabel.Create(fEffectPanel) do
    begin
    Top := 24;
    Left := 338;
    Height := 32;
    Width := 200;
    Size := 16;
    Caption := 'SSAO Samples:';
    end;
  fSSAOSamples := TSlider.Create(fEffectPanel);
  with fSSAOSamples do
    begin
    Top := 24;
    Left := 538;
    Width := 122;
    Height := 32;
    Digits := 0;
    Min := 50;
    Max := 400;
    Value := ModuleManager.ModRenderer.SSAOSamples;
    end;

  with TLabel.Create(fEffectPanel) do
    begin
    Top := 56;
    Left := 8;
    Height := 32;
    Width := 200;
    Size := 16;
    Caption := 'Bloom strength:';
    end;
  fBloom := TSlider.Create(fEffectPanel);
  with fBloom do
    begin
    Top := 56;
    Left := 208;
    Width := 122;
    Height := 32;
    Digits := 2;
    Min := 0;
    Max := 1;
    Value := ModuleManager.ModRenderer.BloomFactor;
    end;

  with TLabel.Create(fEffectPanel) do
    begin
    Top := 96;
    Left := 48;
    Height := 16;
    Width := 200;
    Size := 16;
    Caption := 'Depth of field';
    end;
  fFocalBlur := TCheckBox.Create(fEffectPanel);
  with fFocalBlur do
    begin
    Top := 88;
    Left := 8;
    Width := 32;
    Height := 32;
    Checked := ModuleManager.ModRenderer.UseFocalBlur;
    end;
  with TLabel.Create(fEffectPanel) do
    begin
    Top := 96;
    Left := 278;
    Height := 32;
    Width := 200;
    Size := 16;
    Caption := 'Sun rays';
    end;
  fSunRays := TCheckBox.Create(fEffectPanel);
  with fSunRays do
    begin
    Top := 88;
    Left := 238;
    Width := 32;
    Height := 32;
    Checked := ModuleManager.ModRenderer.UseSunRays;
    end;
  with TLabel.Create(fEffectPanel) do
    begin
    Top := 96;
    Left := 508;
    Height := 32;
    Width := 200;
    Size := 16;
    Caption := 'Lens flare';
    end;
  fLensFlare := TCheckBox.Create(fEffectPanel);
  with fLensFlare do
    begin
    Top := 88;
    Left := 468;
    Width := 32;
    Height := 32;
    Checked := ModuleManager.ModRenderer.UseLensFlare;
    end;
  
  with TLabel.Create(fEffectPanel) do
    begin
    Top := 128;
    Left := 48;
    Width := 200;
    Height := 32;
    Size := 16;
    Caption := 'Motion blur';
    end;
  fMotionBlur := TCheckBox.Create(fEffectPanel);
  with fMotionBlur do
    begin
    Top := 120;
    Left := 8;
    Width := 32;
    Height := 32;
    Checked := ModuleManager.ModRenderer.UseMotionBlur;
    end;
  with TLabel.Create(fEffectPanel) do
    begin
    Top := 120;
    Left := 338;
    Height := 32;
    Width := 200;
    Size := 16;
    Caption := 'Motion blur strength:';
    end;
  fMotionBlurStrength := TSlider.Create(fEffectPanel);
  with fMotionBlurStrength do
    begin
    Top := 120;
    Left := 538;
    Width := 122;
    Height := 32;
    Digits := 3;
    Min := 0;
    Max := 0.1;
    Value := ModuleManager.ModRenderer.MotionBlurStrength;
    end;

  // Normal
  with TLabel.Create(fNormalRenderingPanel) do
    begin
    Top := 24;
    Left := 48;
    Size := 16;
    Height := 32;
    Width := 200;
    Caption := 'Sun shadows';
    end;
  fUseSunShadows := TCheckBox.Create(fNormalRenderingPanel);
  with fUseSunShadows do
    begin
    Top := 24;
    Left := 8;
    Width := 32;
    Height := 32;
    Checked := ModuleManager.ModRenderer.UseSunShadows;
    end;
  with TLabel.Create(fNormalRenderingPanel) do
    begin
    Top := 24;
    Left := 378;
    Size := 16;
    Height := 32;
    Width := 200;
    Caption := 'Other shadows';
    end;
  fUseLightShadows := TCheckBox.Create(fNormalRenderingPanel);
  with fUseLightShadows do
    begin
    Top := 24;
    Left := 338;
    Width := 32;
    Height := 32;
    Checked := ModuleManager.ModRenderer.UseLightShadows;
    end;

  with TLabel.Create(fNormalRenderingPanel) do
    begin
    Top := 56;
    Left := 8;
    Width := 200;
    Height := 32;
    Size := 16;
    Caption := 'Shadow size factor:';
    end;
  fShadowSamples := TSlider.Create(fNormalRenderingPanel);
  with fShadowSamples do
    begin
    Top := 56;
    Left := 208;
    Width := 122;
    Height := 32;
    Digits := 0;
    Min := 1;
    Max := 5;
    Value := ModuleManager.ModRenderer.ShadowBufferSamples;
    end;
  with TLabel.Create(fNormalRenderingPanel) do
    begin
    Top := 56;
    Left := 338;
    Width := 200;
    Height := 32;
    Size := 16;
    Caption := 'Shadow blur strength:';
    end;
  fShadowBlurSamples := TSlider.Create(fNormalRenderingPanel);
  with fShadowBlurSamples do
    begin
    Top := 56;
    Left := 538;
    Width := 122;
    Height := 32;
    Digits := 0;
    Min := 1;
    Max := 10;
    Value := ModuleManager.ModRenderer.ShadowBlurSamples;
    end;

  with TLabel.Create(fNormalRenderingPanel) do
    begin
    Top := 88;
    Left := 8;
    Width := 200;
    Height := 32;
    Size := 16;
    Caption := 'Distance factor for object LOD:';
    end;
  fLODDistanceFactor := TSlider.Create(fNormalRenderingPanel);
  with fLODDistanceFactor do
    begin
    Top := 88;
    Left := 208;
    Width := 122;
    Height := 32;
    Digits := 1;
    Min := 0.1;
    Max := 10;
    Value := ModuleManager.ModRenderer.LODDistanceFactor;
    end;
  with TLabel.Create(fNormalRenderingPanel) do
    begin
    Top := 88;
    Left := 338;
    Width := 200;
    Height := 32;
    Size := 16;
    Caption := 'Distance offset for object LOD:';
    end;
  fLODDistanceOffset := TSlider.Create(fNormalRenderingPanel);
  with fLODDistanceOffset do
    begin
    Top := 88;
    Left := 538;
    Width := 122;
    Height := 32;
    Digits := 1;
    Min := -20;
    Max := 20;
    Value := ModuleManager.ModRenderer.LODDistanceOffset;
    end;

  with TLabel.Create(fNormalRenderingPanel) do
    begin
    Top := 120;
    Left := 8;
    Width := 200;
    Height := 32;
    Size := 16;
    Caption := 'Maximum distance for high terrain LOD:';
    end;
  fTerrainTesselationDistance := TSlider.Create(fNormalRenderingPanel);
  with fTerrainTesselationDistance do
    begin
    Top := 120;
    Left := 208;
    Width := 122;
    Height := 32;
    Digits := 0;
    Min := 0;
    Max := 128;
    Value := ModuleManager.ModRenderer.TerrainTesselationDistance;
    end;
  with TLabel.Create(fNormalRenderingPanel) do
    begin
    Top := 120;
    Left := 338;
    Width := 200;
    Height := 32;
    Size := 16;
    Caption := 'Maximum distance for medium terrain LOD:';
    end;
  fTerrainDetailDistance := TSlider.Create(fNormalRenderingPanel);
  with fTerrainDetailDistance do
    begin
    Top := 120;
    Left := 538;
    Width := 122;
    Height := 32;
    Digits := 0;
    Min := 0;
    Max := 512;
    Value := ModuleManager.ModRenderer.TerrainDetailDistance;
    end;

  with TLabel.Create(fNormalRenderingPanel) do
    begin
    Top := 152;
    Left := 8;
    Width := 200;
    Height := 32;
    Size := 16;
    Caption := 'Maximum bumpmap distance:';
    end;
  fTerrainBumpmapDistance := TSlider.Create(fNormalRenderingPanel);
  with fTerrainBumpmapDistance do
    begin
    Top := 152;
    Left := 208;
    Width := 122;
    Height := 32;
    Digits := 0;
    Min := 0;
    Max := 256;
    Value := ModuleManager.ModRenderer.TerrainBumpmapDistance;
    end;

  with TLabel.Create(fNormalRenderingPanel) do
    begin
    Top := 184;
    Left := 8;
    Width := 200;
    Height := 32;
    Size := 16;
    Caption := 'Number of Autoplants:';
    end;
  fAutoplantCount := TSlider.Create(fNormalRenderingPanel);
  with fAutoplantCount do
    begin
    Top := 184;
    Left := 208;
    Width := 122;
    Height := 32;
    Digits := -2;
    Min := 0;
    Max := 45000;
    Value := ModuleManager.ModRenderer.AutoplantCount;
    end;
  with TLabel.Create(fNormalRenderingPanel) do
    begin
    Top := 184;
    Left := 338;
    Width := 200;
    Height := 32;
    Size := 16;
    Caption := 'Maximum distance to Autoplants:';
    end;
  fAutoplantDistance := TSlider.Create(fNormalRenderingPanel);
  with fAutoplantDistance do
    begin
    Top := 184;
    Left := 538;
    Width := 122;
    Height := 32;
    Digits := 0;
    Min := 0;
    Max := 256;
    Value := ModuleManager.ModRenderer.AutoplantDistance;
    end;

  // Water
  with TLabel.Create(fWaterPanel) do
    begin
    Top := 24;
    Left := 8;
    Width := 200;
    Height := 32;
    Size := 16;
    Caption := 'Number of water reflection samples:';
    end;
  fWaterSamples := TSlider.Create(fWaterPanel);
  with fWaterSamples do
    begin
    Top := 24;
    Left := 208;
    Width := 122;
    Height := 32;
    Digits := 1;
    Min := 0;
    Max := 4;
    Value := ModuleManager.ModRenderer.WaterReflectionBufferSamples;
    end;

  with TLabel.Create(fWaterPanel) do
    begin
    Top := 64;
    Left := 48;
    Width := 200;
    Height := 32;
    Size := 16;
    Caption := 'Reflect sky';
    end;
  fWaterReflectSky := TCheckBox.Create(fWaterPanel);
  with fWaterReflectSky do
    begin
    Top := 56;
    Left := 8;
    Width := 32;
    Height := 32;
    Checked := ModuleManager.ModRenderer.WaterReflectSky;
    end;
  with TLabel.Create(fWaterPanel) do
    begin
    Top := 64;
    Left := 278;
    Width := 200;
    Height := 32;
    Size := 16;
    Caption := 'Reflect terrain';
    end;
  fWaterReflectTerrain := TCheckBox.Create(fWaterPanel);
  with fWaterReflectTerrain do
    begin
    Top := 56;
    Left := 238;
    Width := 32;
    Height := 32;
    Checked := ModuleManager.ModRenderer.WaterReflectTerrain;
    end;
  with TLabel.Create(fWaterPanel) do
    begin
    Top := 64;
    Left := 508;
    Width := 200;
    Height := 32;
    Size := 16;
    Caption := 'Reflect Autoplants';
    end;
  fWaterReflectAutoplants := TCheckBox.Create(fWaterPanel);
  with fWaterReflectAutoplants do
    begin
    Top := 56;
    Left := 468;
    Width := 32;
    Height := 32;
    Checked := ModuleManager.ModRenderer.WaterReflectAutoplants;
    end;

  with TLabel.Create(fWaterPanel) do
    begin
    Top := 96;
    Left := 48;
    Width := 200;
    Height := 32;
    Size := 16;
    Caption := 'Reflect objects';
    end;
  fWaterReflectObjects := TCheckBox.Create(fWaterPanel);
  with fWaterReflectObjects do
    begin
    Top := 88;
    Left := 8;
    Width := 32;
    Height := 32;
    Checked := ModuleManager.ModRenderer.WaterReflectObjects;
    end;
  with TLabel.Create(fWaterPanel) do
    begin
    Top := 96;
    Left := 278;
    Width := 200;
    Height := 32;
    Size := 16;
    Caption := 'Reflect particles';
    end;
  fWaterReflectParticles := TCheckBox.Create(fWaterPanel);
  with fWaterReflectParticles do
    begin
    Top := 88;
    Left := 238;
    Width := 32;
    Height := 32;
    Checked := ModuleManager.ModRenderer.WaterReflectParticles;
    end;

  with TLabel.Create(fWaterPanel) do
    begin
    Top := 128;
    Left := 48;
    Width := 200;
    Height := 32;
    Size := 16;
    Caption := 'Refract particles';
    end;
  fWaterRefractParticles := TCheckBox.Create(fWaterPanel);
  with fWaterRefractParticles do
    begin
    Top := 120;
    Left := 8;
    Width := 32;
    Height := 32;
    Checked := ModuleManager.ModRenderer.WaterRefractParticles;
    end;
  with TLabel.Create(fWaterPanel) do
    begin
    Top := 128;
    Left := 278;
    Width := 200;
    Height := 32;
    Size := 16;
    Caption := 'Refract terrain';
    end;
  fWaterRefractTerrain := TCheckBox.Create(fWaterPanel);
  with fWaterRefractTerrain do
    begin
    Top := 120;
    Left := 238;
    Width := 32;
    Height := 32;
    Checked := ModuleManager.ModRenderer.WaterRefractTerrain;
    end;
  with TLabel.Create(fWaterPanel) do
    begin
    Top := 128;
    Left := 508;
    Width := 200;
    Height := 32;
    Size := 16;
    Caption := 'Refract Autoplants';
    end;
  fWaterRefractAutoplants := TCheckBox.Create(fWaterPanel);
  with fWaterRefractAutoplants do
    begin
    Top := 120;
    Left := 468;
    Width := 32;
    Height := 32;
    Checked := ModuleManager.ModRenderer.WaterRefractAutoplants;
    end;

  with TLabel.Create(fWaterPanel) do
    begin
    Top := 160;
    Left := 48;
    Width := 200;
    Height := 32;
    Size := 16;
    Caption := 'Refract objects';
    end;
  fWaterRefractObjects := TCheckBox.Create(fWaterPanel);
  with fWaterRefractObjects do
    begin
    Top := 152;
    Left := 8;
    Width := 32;
    Height := 32;
    Checked := ModuleManager.ModRenderer.WaterRefractObjects;
    end;
end;

destructor TOWEConfigInterface.Free;
begin
  fConfigurationInterface.Free;
end;

end.