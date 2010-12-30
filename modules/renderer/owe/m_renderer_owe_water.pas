unit m_renderer_owe_water;

interface

uses
  SysUtils, Classes, m_renderer_owe_renderpass, m_renderer_owe_classes, u_arrays, m_shdmng_class, m_texmng_class, u_vectors, DGLOpenGL, math;

type
  TWaterLayer = class
    protected
      fHeight: Word;
      fRefractionPass, fReflectionPass: TRenderPass;
      fQuery: TOcclusionQuery;
      fVisible: Boolean;
    private
      fCount: Integer;
    public
      property Height: Word read fHeight;
      function Visible: Boolean;
      procedure CheckVisibility;
      procedure Render;
      procedure RenderBuffers;
      constructor Create(H: Word);
      destructor Free;
    end;

  TRWater = class
    protected
      fWaterMap: TTable;
      fCheckShader, fRenderShader: TShader;
      fWaterLayers: Array of TWaterLayer;
      fBumpMap: TTexture;
      fBumpOffset: TVector2D;
      fWaterVBO: TVBO;
    public
      property RenderShader: TShader read fRenderShader;
      property CheckShader: TShader read fCheckShader;
      property BumpOffset: TVector2D read fBumpOffset;
      property WaterVBO: TVBO read fWaterVBO;
      procedure Update(Event: String; Data, Result: Pointer);
      procedure Resize(Event: String; Data, Result: Pointer);
      procedure Check;
      procedure Render;
      procedure RenderBuffers;
      constructor Create;
      destructor Free;
    end;

implementation

uses
  m_varlist, u_events, g_park, main;

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
  fBumpOffset := fBumpOffset + Vector(0.1, 0.2) / 150 * FPSDisplay.MS;
  for i := 0 to high(fWaterLayers) do
    if fWaterLayers[i].Visible then
      begin
      fBumpMap.Bind(1);
      fWaterLayers[i].Render;
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
begin
  writeln('Hint; Initializing water renderer');

  fCheckShader := TShader.Create('orcf-world-engine/scene/water/water.vs', 'orcf-world-engine/scene/water/waterCheck.fs');
  fCheckShader.UniformI('HeightMap', 0);

  fRenderShader := TShader.Create('orcf-world-engine/scene/water/water.vs', 'orcf-world-engine/scene/water/water.fs');
  fRenderShader.UniformI('HeightMap', 0);
  fRenderShader.UniformI('BumpMap', 1);
  fRenderShader.UniformI('RefractTex', 2);
  fRenderShader.UniformI('ReflectTex', 3);
  fRenderShader.UniformI('GeometryMap', 4);
  fRenderShader.UniformF('ScreenSize', ModuleManager.ModRenderer.BufferSizeX, ModuleManager.ModRenderer.BufferSizeY);
  fRenderShader.UniformF('BumpOffset', 0, 0);

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
end;

destructor TRWater.Free;
var
  i: Integer;
begin
  EventManager.RemoveCallback(@Resize);
  EventManager.RemoveCallback(@Update);

  fBumpMap.Free;

  fWaterVBO.Free;

  fWaterMap.Free;

  fRenderShader.Free;
  fCheckShader.Free;

  for i := 0 to high(fWaterLayers) do
    fWaterLayers[i].Free;
end;

function TWaterLayer.Visible: Boolean;
begin
  Result := fQuery.Result > 0;
end;

procedure TWaterLayer.CheckVisibility;
begin
  ModuleManager.ModRenderer.RWater.CheckShader.Bind;
  ModuleManager.ModRenderer.RWater.CheckShader.UniformF('Height', Height / 65535 * 256);
  ModuleManager.ModRenderer.RWater.CheckShader.UniformF('TerrainSize', Park.pTerrain.SizeX / 5, Park.pTerrain.SizeY / 5);
  ModuleManager.ModRenderer.RTerrain.TerrainMap.Bind(0);

  fQuery.StartCounter;

  glBegin(GL_QUADS);
    glVertex2f(-204.8, Park.pTerrain.SizeY / 5 + 204.8);
    glVertex2f(Park.pTerrain.SizeX / 5 + 204.8, Park.pTerrain.SizeY / 5 + 204.8);
    glVertex2f(Park.pTerrain.SizeX / 5 + 204.8, -204.8);
    glVertex2f(-204.8, -204.8);
  glEnd;

  fQuery.EndCounter;

  ModuleManager.ModRenderer.RWater.CheckShader.Unbind;
end;

procedure TWaterLayer.Render;
begin
  ModuleManager.ModRenderer.RWater.RenderShader.Bind;
  ModuleManager.ModRenderer.RWater.RenderShader.UniformF('BumpOffset', ModuleManager.ModRenderer.RWater.BumpOffset.X, ModuleManager.ModRenderer.RWater.BumpOffset.Y);
  ModuleManager.ModRenderer.RWater.RenderShader.UniformF('Height', Height / 65535 * 256);
  ModuleManager.ModRenderer.RWater.RenderShader.UniformF('TerrainSize', Park.pTerrain.SizeX / 5, Park.pTerrain.SizeY / 5);
  ModuleManager.ModRenderer.RWater.RenderShader.UniformF('Offset', ModuleManager.ModCamera.ActiveCamera.Position.X, ModuleManager.ModCamera.ActiveCamera.Position.Z);
  fRefractionPass.Scene.Textures[0].Bind(2);
  fReflectionPass.Scene.Textures[0].Bind(3);
  fRefractionPass.GBuffer.Textures[2].Bind(4);
  ModuleManager.ModRenderer.RTerrain.TerrainMap.Bind(0);


  ModuleManager.ModRenderer.RWater.WaterVBO.Bind;
  ModuleManager.ModRenderer.RWater.WaterVBO.Render;
  ModuleManager.ModRenderer.RWater.WaterVBO.Unbind;


//   glBegin(GL_QUADS);
//     glVertex2f(0, Park.pTerrain.SizeY / 5);
//     glVertex2f(Park.pTerrain.SizeX / 5, Park.pTerrain.SizeY / 5);
//     glVertex2f(Park.pTerrain.SizeX / 5, 0);
//     glVertex2f(0, 0);
//   glEnd;

  ModuleManager.ModRenderer.RWater.RenderShader.Unbind;
end;

procedure TWaterLayer.RenderBuffers;
const
  ClipPlane: Array[0..3] of GLDouble = (0, -1, 0, 0);
begin
  glEnable(GL_CLIP_PLANE0);

  glMatrixMode(GL_MODELVIEW);

  glPushMatrix;
    glTranslatef(0, fHeight / 256, 0);
    glClipPlane(GL_CLIP_PLANE0, @ClipPlane[0]);
    glScalef(1, -1, 1);
    glTranslatef(0, -fHeight / 256, 0);

    glFrontFace(GL_CW);
    ModuleManager.ModRenderer.RTerrain.BorderEnabled := True;
    fReflectionPass.Render;
    glFrontFace(GL_CCW);
  glPopMatrix;

  glPushMatrix;
    glTranslatef(0, fHeight / 256 + 0.05, 0);
    glClipPlane(GL_CLIP_PLANE0, @ClipPlane[0]);
  glPopMatrix;

  ModuleManager.ModRenderer.RTerrain.BorderEnabled := True;
  fRefractionPass.Render;

  glDisable(GL_CLIP_PLANE0);
end;

constructor TWaterLayer.Create(H: Word);
var
  ResX, ResY: Integer;
begin
  ModuleManager.ModGLContext.GetResolution(ResX, ResY);
  fReflectionPass := TRenderPass.Create(Round(ResX * ModuleManager.ModRenderer.WaterReflectionBufferSamples), Round(ResY * ModuleManager.ModRenderer.WaterReflectionBufferSamples));
  fRefractionPass := TRenderPass.Create(Round(ResX * ModuleManager.ModRenderer.WaterReflectionBufferSamples), Round(ResY * ModuleManager.ModRenderer.WaterReflectionBufferSamples));
  fQuery := TOcclusionQuery.Create;
  fHeight := H;
end;

destructor TWaterLayer.Free;
begin
  fQuery.Free;
  fRefractionPass.Free;
  fReflectionPass.Free;
end;

end.