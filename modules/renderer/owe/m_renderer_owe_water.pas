unit m_renderer_owe_water;

interface

uses
  SysUtils, Classes, m_renderer_owe_renderpass, m_renderer_owe_classes, u_arrays, m_shdmng_class, m_texmng_class, u_vectors, DGLOpenGL, math;

type
  TWaterLayer = class
    protected
      fHeight: Word;
      fRefractionPass, fRefractionGeo, fReflectionPass: TFBO;
      fQuery: TOcclusionQuery;
      fVisible: Boolean;
    private
      fCount: Integer;
    public
      property Height: Word read fHeight;
      function Visible: Boolean;
      procedure CheckVisibility;
      procedure Render;
      procedure RenderSimple;
      procedure RenderBuffers;
      constructor Create(H: Word);
      destructor Free;
    end;

  TRWater = class
    protected
      fWaterMap: TTable;
      fCheckShader, fSimpleShader, fRenderShader: TShader;
      fWaterLayers: Array of TWaterLayer;
      fBumpMap: TTexture;
      fBumpOffset: TVector2D;
      fWaterVBO: TVBO;
      fRenderPass: TRenderPass;
    private
      fCurrentHeight: Single;
    public
      Uniforms: Array[0..12] of GLUInt;
      property CurrentHeight: Single read fCurrentHeight;
      property RenderShader: TShader read fRenderShader;
      property SimpleShader: TShader read fSimpleShader;
      property CheckShader: TShader read fCheckShader;
      property BumpOffset: TVector2D read fBumpOffset;
      property WaterVBO: TVBO read fWaterVBO;
      property RenderPass: TRenderPass read fRenderPass;
      procedure Update(Event: String; Data, Result: Pointer);
      procedure Resize(Event: String; Data, Result: Pointer);
      procedure Check;
      procedure Render;
      procedure RenderSimple;
      procedure Advance;
      procedure RenderBuffers;
      constructor Create;
      destructor Free;
    end;

implementation

uses
  m_varlist, u_events, g_park, main;

const
  UNIFORM_CHECK_HEIGHT = 0;
  UNIFORM_CHECK_TERRAINSIZE = 1;
  
  UNIFORM_RENDER_BUMPOFFSET = 2;
  UNIFORM_RENDER_HEIGHT = 3;
  UNIFORM_RENDER_TERRAINSIZE = 4;
  UNIFORM_RENDER_OFFSET = 5;
  UNIFORM_RENDER_UNDERWATERFACTOR = 6;
  UNIFORM_RENDER_MEDIUMS = 7;

  UNIFORM_SIMPLE_BUMPOFFSET = 8;
  UNIFORM_SIMPLE_HEIGHT = 9;
  UNIFORM_SIMPLE_TERRAINSIZE = 10;
  UNIFORM_SIMPLE_OFFSET = 11;
  UNIFORM_SIMPLE_VIEWPOINT = 12;

  
procedure TRWater.Advance;
begin
  fBumpOffset := fBumpOffset + Vector(0.1, 0.2) / 150 * FPSDisplay.MS;
end;

procedure TRWater.Resize(Event: String; Data, Result: Pointer);
begin
  fWaterMap.Resize(Park.pTerrain.SizeX, Park.pTerrain.SizeY);
end;

procedure TRWater.Update(Event: String; Data, Result: Pointer);
var
  i, x, y: integer;
  h: Word;
  P: Pointer;
  fWaterLayerList: Array[0..65535] of TWaterLayer;
begin
  P := Data;
  Inc(P, SizeOf(Integer));
  for i := 0 to 65535 do
    fWaterLayerList[i] := nil;
  for i := 0 to high(fWaterLayers) do
    fWaterLayerList[fWaterLayers[i].Height] := fWaterLayers[i];
  for i := 0 to Integer(Data^) - 1 do
    begin
    x := Integer(P^); Inc(P, SizeOf(Integer));
    y := Integer(P^); Inc(P, SizeOf(Integer));
    h := fWaterMap[X, Y];
    if fWaterLayerList[h] <> nil then
      dec(fWaterLayerList[h].fCount);
    h := Park.pTerrain.ExactWaterMap[x, y];
    if fWaterLayerList[h] <> nil then
      inc(fWaterLayerList[h].fCount)
    else if h <> 0 then
      begin
      fWaterLayerList[h] := TWaterLayer.Create(h);
      SetLength(fWaterLayers, length(fWaterLayers) + 1);
      fWaterLayers[high(fWaterLayers)] := fWaterLayerList[h];

      fWaterLayerList[h].fCount := 1;
      end;
    end;
  i := 0;
  while i <= high(fWaterLayers) do
    if fWaterLayers[i].fCount = 0 then
      begin
      fWaterLayers[i].Free;
      fWaterLayers[i] := fWaterLayers[high(fWaterLayers)];
      SetLength(fWaterLayers, length(fWaterLayers) - 1);
      end
    else
      inc(i);
end;

procedure TRWater.Check;
var
  i: Integer;
begin
  for i := 0 to high(fWaterLayers) do
    fWaterLayers[i].CheckVisibility;
end;

procedure TRWater.Render;
var
  i: Integer;
begin
  glDisable(GL_CULL_FACE);
  for i := 0 to high(fWaterLayers) do
    if fWaterLayers[i].Visible then
      begin
      fBumpMap.Bind(1);
      fWaterLayers[i].Render;
      end;
  glEnable(GL_CULL_FACE);
end;

procedure TRWater.RenderSimple;
var
  i: Integer;
begin
  for i := 0 to high(fWaterLayers) do
//     if fWaterLayers[i].Visible then
      begin
      fBumpMap.Bind(1);
      fWaterLayers[i].RenderSimple;
      end;
end;

procedure TRWater.RenderBuffers;
var
  i: Integer;
begin
  glMatrixMode(GL_PROJECTION);
  glPushMatrix;
  glMatrixMode(GL_MODELVIEW);
  glPushMatrix;
  for i := 0 to high(fWaterLayers) do
    if fWaterLayers[i].Visible then
      fWaterLayers[i].RenderBuffers;
  glMatrixMode(GL_MODELVIEW);
  glPopMatrix;
  glMatrixMode(GL_PROJECTION);
  glPopMatrix;
  glMatrixMode(GL_MODELVIEW);
end;

constructor TRWater.Create;
var
  Radius, OldRadius: Single;
  Count: Integer;
  i, j: Integer;
  ResX, ResY: Integer;
begin
  writeln('Hint: Initializing water renderer');

  ModuleManager.ModGLContext.GetResolution(ResX, ResY);

  fCheckShader := TShader.Create('orcf-world-engine/scene/water/waterSimple.vs', 'orcf-world-engine/scene/water/waterCheck.fs');
  fCheckShader.UniformI('HeightMap', 0);
  Uniforms[UNIFORM_CHECK_HEIGHT] := fCheckShader.GetUniformLocation('Height');
  Uniforms[UNIFORM_CHECK_TERRAINSIZE] := fCheckShader.GetUniformLocation('TerrainSize');

  fRenderShader := TShader.Create('orcf-world-engine/scene/water/water.vs', 'orcf-world-engine/scene/water/water.fs');
  fRenderShader.UniformI('HeightMap', 0);
  fRenderShader.UniformI('BumpMap', 1);
  fRenderShader.UniformI('RefractTex', 2);
  fRenderShader.UniformI('ReflectTex', 3);
  fRenderShader.UniformI('GeometryMap', 4);
  fRenderShader.UniformF('ScreenSize', ModuleManager.ModRenderer.BufferSizeX, ModuleManager.ModRenderer.BufferSizeY);
  fRenderShader.UniformF('BumpOffset', 0, 0);
  Uniforms[UNIFORM_RENDER_BUMPOFFSET] := fRenderShader.GetUniformLocation('BumpOffset');
  Uniforms[UNIFORM_RENDER_HEIGHT] := fRenderShader.GetUniformLocation('Height');
  Uniforms[UNIFORM_RENDER_TERRAINSIZE] := fRenderShader.GetUniformLocation('TerrainSize');
  Uniforms[UNIFORM_RENDER_OFFSET] := fRenderShader.GetUniformLocation('Offset');
  Uniforms[UNIFORM_RENDER_UNDERWATERFACTOR] := fRenderShader.GetUniformLocation('UnderWaterFactor');
  Uniforms[UNIFORM_RENDER_MEDIUMS] := fRenderShader.GetUniformLocation('Mediums');

  fSimpleShader := TShader.Create('orcf-world-engine/scene/water/waterSimple.vs', 'orcf-world-engine/scene/water/waterSimple.fs');
  fSimpleShader.UniformI('HeightMap', 0);
  fSimpleShader.UniformI('BumpMap', 1);
  fSimpleShader.UniformI('EnvironmentMap', 3);
  fSimpleShader.UniformF('BumpOffset', 0, 0);
  Uniforms[UNIFORM_SIMPLE_BUMPOFFSET] := fSimpleShader.GetUniformLocation('BumpOffset');
  Uniforms[UNIFORM_SIMPLE_HEIGHT] := fSimpleShader.GetUniformLocation('Height');
  Uniforms[UNIFORM_SIMPLE_TERRAINSIZE] := fSimpleShader.GetUniformLocation('TerrainSize');
  Uniforms[UNIFORM_SIMPLE_OFFSET] := fSimpleShader.GetUniformLocation('Offset');
  fSimpleShader.Unbind;

  fWaterMap := TTable.Create;

  fBumpMap := TTexture.Create;
  fBumpMap.FromFile('terrain/water-bumpmap.tga');
  fBumpMap.CreateMipMaps;

  EventManager.AddCallback('TTerrain.ChangedWater', @Update);
  EventManager.AddCallback('TTerrain.Resize', @Resize);

  fBumpOffset := Vector(0, 0);

  OldRadius := 0;
  Radius := 0.005;
  Count := 0;

  fWaterVBO := TVBO.Create(720000, GL_V3F, GL_QUADS);
  for i := 0 to 1499 do
    begin
    if i = 1499 then
      Radius := 7000;
    for j := 0 to 119 do
      begin
      fWaterVBO.Vertices[Count + 0] := Vector(sin(DegToRad(3 * (j + 0))) * OldRadius, cos(DegToRad(3 * (j + 0))) * OldRadius, Min(1, 15 - 0.01 * (i + 0)));
      fWaterVBO.Vertices[Count + 1] := Vector(sin(DegToRad(3 * (j + 0))) *    Radius, cos(DegToRad(3 * (j + 0))) *    Radius, Min(1, 15 - 0.01 * (i + 1)));
      fWaterVBO.Vertices[Count + 2] := Vector(sin(DegToRad(3 * (j + 1))) *    Radius, cos(DegToRad(3 * (j + 1))) *    Radius, Min(1, 15 - 0.01 * (i + 1)));
      fWaterVBO.Vertices[Count + 3] := Vector(sin(DegToRad(3 * (j + 1))) * OldRadius, cos(DegToRad(3 * (j + 1))) * OldRadius, Min(1, 15 - 0.01 * (i + 0)));
      inc(Count, 4);
      end;
    OldRadius := Radius;
    Radius := Radius + Max(0.005, i / 30000);
    end;
  fWaterVBO.Unbind;

  fRenderPass := TRenderPass.Create(Round(ResX * ModuleManager.ModRenderer.WaterReflectionBufferSamples), Round(ResY * ModuleManager.ModRenderer.WaterReflectionBufferSamples));
  fRenderPass.RenderWater := False;
end;

destructor TRWater.Free;
var
  i: Integer;
begin
  fRenderPass.Free;

  EventManager.RemoveCallback(@Resize);
  EventManager.RemoveCallback(@Update);

  fBumpMap.Free;

  fWaterVBO.Free;

  fWaterMap.Free;

  fRenderShader.Free;
  fCheckShader.Free;
  fSimpleShader.Free;

  for i := 0 to high(fWaterLayers) do
    fWaterLayers[i].Free;
end;

function TWaterLayer.Visible: Boolean;
begin
  Result := fQuery.Result > 0;
end;

procedure TWaterLayer.CheckVisibility;
begin
  glDisable(GL_CULL_FACE);

  with ModuleManager.ModRenderer.RWater do
    begin
    CheckShader.Bind;
    CheckShader.UniformF(Uniforms[UNIFORM_CHECK_HEIGHT], Height / 65535 * 256);
    CheckShader.UniformF(Uniforms[UNIFORM_CHECK_TERRAINSIZE], Park.pTerrain.SizeX / 5, Park.pTerrain.SizeY / 5);
    end;
  ModuleManager.ModRenderer.RTerrain.TerrainMap.Bind(0);

  fQuery.StartCounter;

  glBegin(GL_QUADS);
    glVertex2f(-2048, Park.pTerrain.SizeY / 5 + 2048);
    glVertex2f(Park.pTerrain.SizeX / 5 + 2048, Park.pTerrain.SizeY / 5 + 2048);
    glVertex2f(Park.pTerrain.SizeX / 5 + 2048, -2048);
    glVertex2f(-2048, -2048);
  glEnd;

  fQuery.EndCounter;

  ModuleManager.ModRenderer.RWater.CheckShader.Unbind;

  glEnable(GL_CULL_FACE);
end;

procedure TWaterLayer.Render;
begin
  with ModuleManager.ModRenderer.RWater do
    begin
    RenderShader.Bind;
    RenderShader.UniformF(Uniforms[UNIFORM_RENDER_BUMPOFFSET], ModuleManager.ModRenderer.RWater.BumpOffset.X, ModuleManager.ModRenderer.RWater.BumpOffset.Y);
    RenderShader.UniformF(Uniforms[UNIFORM_RENDER_HEIGHT], Height / 65535 * 256);
    RenderShader.UniformF(Uniforms[UNIFORM_RENDER_TERRAINSIZE], Park.pTerrain.SizeX / 5, Park.pTerrain.SizeY / 5);
    RenderShader.UniformF(Uniforms[UNIFORM_RENDER_OFFSET], ModuleManager.ModCamera.ActiveCamera.Position.X, ModuleManager.ModCamera.ActiveCamera.Position.Z);
    if ModuleManager.ModCamera.ActiveCamera.Position.Y < fHeight / 256 then
      begin
      RenderShader.UniformF(Uniforms[UNIFORM_RENDER_UNDERWATERFACTOR], -1);
      RenderShader.UniformF(Uniforms[UNIFORM_RENDER_MEDIUMS], 1.33, 1.0);
      end
    else
      begin
      RenderShader.UniformF(Uniforms[UNIFORM_RENDER_UNDERWATERFACTOR], 1);
      RenderShader.UniformF(Uniforms[UNIFORM_RENDER_MEDIUMS], 1.0, 1.33);
      end;
    end;
  ModuleManager.ModRenderer.RTerrain.TerrainMap.Bind(0);
  fRefractionPass.Textures[0].Bind(2);
  fReflectionPass.Textures[0].Bind(3);
  fRefractionGeo.Textures[0].Bind(4);

  ModuleManager.ModRenderer.RWater.WaterVBO.Bind;
  ModuleManager.ModRenderer.RWater.WaterVBO.Render;
  ModuleManager.ModRenderer.RWater.WaterVBO.Unbind;

  fRefractionGeo.Textures[0].UnBind;
  fReflectionPass.Textures[0].UnBind;
  fRefractionPass.Textures[0].UnBind;
  ModuleManager.ModRenderer.RTerrain.TerrainMap.UnBind;

  ModuleManager.ModRenderer.RWater.RenderShader.Unbind;
end;

procedure TWaterLayer.RenderSimple;
begin
  with ModuleManager.ModRenderer.RWater do
    begin
    SimpleShader.Bind;
    SimpleShader.UniformF(Uniforms[UNIFORM_SIMPLE_BUMPOFFSET], ModuleManager.ModRenderer.RWater.BumpOffset.X, ModuleManager.ModRenderer.RWater.BumpOffset.Y);
    SimpleShader.UniformF(Uniforms[UNIFORM_SIMPLE_HEIGHT], Height / 65535 * 256);
    SimpleShader.UniformF(Uniforms[UNIFORM_SIMPLE_TERRAINSIZE], Park.pTerrain.SizeX / 5, Park.pTerrain.SizeY / 5);
    SimpleShader.UniformF(Uniforms[UNIFORM_SIMPLE_OFFSET], ModuleManager.ModCamera.ActiveCamera.Position.X, ModuleManager.ModCamera.ActiveCamera.Position.Z);
    SimpleShader.UniformF(Uniforms[UNIFORM_SIMPLE_VIEWPOINT], ModuleManager.ModRenderer.ViewPoint.X, ModuleManager.ModRenderer.ViewPoint.Y, ModuleManager.ModRenderer.ViewPoint.Z);
    end;

  ModuleManager.ModRenderer.EnvironmentMap.Map.Textures[0].Bind(3);
  ModuleManager.ModRenderer.RTerrain.TerrainMap.Bind(0);

//   ModuleManager.ModRenderer.RWater.WaterVBO.Bind;
//   ModuleManager.ModRenderer.RWater.WaterVBO.Render;
//   ModuleManager.ModRenderer.RWater.WaterVBO.Unbind;

  glBegin(GL_QUADS);
    glVertex2f(-2048, Park.pTerrain.SizeY / 5 + 2048);
    glVertex2f(Park.pTerrain.SizeX / 5 + 2048, Park.pTerrain.SizeY / 5 + 2048);
    glVertex2f(Park.pTerrain.SizeX / 5 + 2048, -2048);
    glVertex2f(-2048, -2048);
  glEnd;

  ModuleManager.ModRenderer.EnvironmentMap.Map.Textures[0].UnBind;
  ModuleManager.ModRenderer.RTerrain.TerrainMap.UnBind;

  ModuleManager.ModRenderer.RWater.SimpleShader.Unbind;
end;

procedure TWaterLayer.RenderBuffers;
var
  ClipPlane: Array[0..3] of GLDouble = (0, -1, 0, 0);
begin
  ModuleManager.ModRenderer.RWater.fCurrentHeight := fHeight / 256;

  if ModuleManager.ModCamera.ActiveCamera.Position.Y < fHeight / 256 then
    ClipPlane[1] := 1
  else
    ClipPlane[1] := -1;

  glEnable(GL_CLIP_PLANE0);

  glMatrixMode(GL_MODELVIEW);

  glPushMatrix;
    glTranslatef(0, fHeight / 256, 0);
    glClipPlane(GL_CLIP_PLANE0, @ClipPlane[0]);
    glScalef(1, -1, 1);
    glTranslatef(0, -fHeight / 256, 0);

    ModuleManager.ModRenderer.InvertFrontFace;
    ModuleManager.ModRenderer.RTerrain.BorderEnabled := True;

    ModuleManager.ModRenderer.Frustum.Calculate;

    ModuleManager.ModRenderer.RWater.RenderPass.EnableFog := False;
    ModuleManager.ModRenderer.RWater.RenderPass.EnableRefractionFog := False;
    ModuleManager.ModRenderer.RWater.RenderPass.RenderSky := ModuleManager.ModRenderer.WaterReflectSky and (ClipPlane[1] = -1);
    ModuleManager.ModRenderer.RWater.RenderPass.RenderTerrain := ModuleManager.ModRenderer.WaterReflectTerrain;
    ModuleManager.ModRenderer.RWater.RenderPass.RenderObjects := ModuleManager.ModRenderer.WaterReflectObjects;
    ModuleManager.ModRenderer.RWater.RenderPass.RenderParticles := ModuleManager.ModRenderer.WaterReflectParticles;
    ModuleManager.ModRenderer.RWater.RenderPass.RenderAutoplants := ModuleManager.ModRenderer.WaterReflectAutoplants;
    ModuleManager.ModRenderer.RWater.RenderPass.Render;

    fReflectionPass.CopyFrom(ModuleManager.ModRenderer.RWater.RenderPass.Scene.Textures[0]);
    
    ModuleManager.ModRenderer.InvertFrontFace;
  glPopMatrix;

  glPushMatrix;
    glTranslatef(0, fHeight / 256 + 0.05, 0);
    glClipPlane(GL_CLIP_PLANE0, @ClipPlane[0]);
  glPopMatrix;

  ModuleManager.ModRenderer.Frustum.Calculate;

  ModuleManager.ModRenderer.RTerrain.BorderEnabled := True;
  ModuleManager.ModRenderer.RWater.RenderPass.EnableFog := False;
  ModuleManager.ModRenderer.RWater.RenderPass.EnableRefractionFog := True;
  ModuleManager.ModRenderer.RWater.RenderPass.RenderSky := ClipPlane[1] = 1;
  ModuleManager.ModRenderer.RWater.RenderPass.RenderTerrain := ModuleManager.ModRenderer.WaterRefractTerrain;
  ModuleManager.ModRenderer.RWater.RenderPass.RenderObjects := ModuleManager.ModRenderer.WaterRefractObjects;
  ModuleManager.ModRenderer.RWater.RenderPass.RenderParticles := ModuleManager.ModRenderer.WaterRefractParticles;
  ModuleManager.ModRenderer.RWater.RenderPass.RenderAutoplants := ModuleManager.ModRenderer.WaterRefractAutoplants;
  ModuleManager.ModRenderer.RWater.RenderPass.Render;
  fRefractionPass.CopyFrom(ModuleManager.ModRenderer.RWater.RenderPass.Scene.Textures[0]);
  fRefractionGeo.CopyFrom(ModuleManager.ModRenderer.RWater.RenderPass.GBuffer.Textures[2]);

  glDisable(GL_CLIP_PLANE0);
end;

constructor TWaterLayer.Create(H: Word);
var
  ResX, ResY: Integer;
begin
  ModuleManager.ModGLContext.GetResolution(ResX, ResY);
  fReflectionPass := TFBO.Create(Round(ResX * ModuleManager.ModRenderer.WaterReflectionBufferSamples), Round(ResY * ModuleManager.ModRenderer.WaterReflectionBufferSamples), False);
  fReflectionPass.AddTexture(GL_RGB16F_ARB, GL_LINEAR, GL_LINEAR);
  fReflectionPass.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);
  fRefractionPass := TFBO.Create(Round(ResX * ModuleManager.ModRenderer.WaterReflectionBufferSamples), Round(ResY * ModuleManager.ModRenderer.WaterReflectionBufferSamples), False);
  fRefractionPass.AddTexture(GL_RGB16F_ARB, GL_LINEAR, GL_LINEAR);
  fRefractionPass.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);
  fRefractionGeo := TFBO.Create(Round(ResX * ModuleManager.ModRenderer.WaterReflectionBufferSamples), Round(ResY * ModuleManager.ModRenderer.WaterReflectionBufferSamples), False);
  fRefractionGeo.AddTexture(GL_RGBA32F_ARB, GL_LINEAR, GL_LINEAR);
  fRefractionGeo.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);
  fQuery := TOcclusionQuery.Create;
  fHeight := H;
end;

destructor TWaterLayer.Free;
begin
  fQuery.Free;
  fRefractionPass.Free;
  fRefractionGeo.Free;
  fReflectionPass.Free;
end;

end.