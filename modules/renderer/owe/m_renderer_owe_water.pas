unit m_renderer_owe_water;

interface

uses
  SysUtils, Classes, m_renderer_owe_renderpass, m_renderer_owe_classes, u_arrays, m_shdmng_class, m_texmng_class, u_vectors, DGLOpenGL;

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
    public
      property RenderShader: TShader read fRenderShader;
      property CheckShader: TShader read fCheckShader;
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
  m_varlist, u_events, g_park;

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
  for i := 0 to high(fWaterLayers) do
//     if fWaterLayers[i].Visible then
      fWaterLayers[i].Render;
end;

procedure TRWater.RenderBuffers;
var
  i: Integer;
begin
  for i := 0 to high(fWaterLayers) do
    if fWaterLayers[i].Visible then
      fWaterLayers[i].RenderBuffers;
end;

constructor TRWater.Create;
begin
  writeln('Hint; Initializing water renderer');

  fCheckShader := TShader.Create('orcf-world-engine/scene/water/water.vs', 'orcf-world-engine/scene/water/waterCheck.fs');
  fCheckShader.UniformI('HeightMap', 0);

  fRenderShader := TShader.Create('orcf-world-engine/scene/water/water.vs', 'orcf-world-engine/scene/water/water.fs');
  fRenderShader.UniformI('HeightMap', 0);
  fRenderShader.UniformI('BumpMap', 1);
  fRenderShader.UniformI('RefractTex', 2);
  fRenderShader.UniformI('ReflectTex', 3);

  fWaterMap := TTable.Create;

  EventManager.AddCallback('TTerrain.ChangedWater', @Update);
  EventManager.AddCallback('TTerrain.Resize', @Resize);
end;

destructor TRWater.Free;
var
  i: Integer;
begin
  EventManager.RemoveCallback(@Resize);
  EventManager.RemoveCallback(@Update);

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
    glVertex2f(0, Park.pTerrain.SizeY / 5);
    glVertex2f(Park.pTerrain.SizeX / 5, Park.pTerrain.SizeY / 5);
    glVertex2f(Park.pTerrain.SizeX / 5, 0);
    glVertex2f(0, 0);
  glEnd;

  fQuery.EndCounter;

  ModuleManager.ModRenderer.RWater.CheckShader.Unbind;
end;

procedure TWaterLayer.Render;
begin
  ModuleManager.ModRenderer.RWater.RenderShader.Bind;
  ModuleManager.ModRenderer.RWater.RenderShader.UniformF('Height', Height / 65535 * 256);
  ModuleManager.ModRenderer.RWater.RenderShader.UniformF('TerrainSize', Park.pTerrain.SizeX / 5, Park.pTerrain.SizeY / 5);
  fRefractionPass.Scene.Textures[0].Bind(2);
  fReflectionPass.Scene.Textures[0].Bind(3);
  ModuleManager.ModRenderer.RTerrain.TerrainMap.Bind(0);

  glBegin(GL_QUADS);
    glVertex2f(0, Park.pTerrain.SizeY / 5);
    glVertex2f(Park.pTerrain.SizeX / 5, Park.pTerrain.SizeY / 5);
    glVertex2f(Park.pTerrain.SizeX / 5, 0);
    glVertex2f(0, 0);
  glEnd;

  ModuleManager.ModRenderer.RWater.RenderShader.Unbind;
end;

procedure TWaterLayer.RenderBuffers;
const
  ClipPlane: Array[0..3] of GLDouble = (0, -1, 0, 0);
begin
  glEnable(GL_CLIP_PLANE0);
  glPushMatrix;
    glTranslatef(0, fHeight / 256, 0);
    glClipPlane(GL_CLIP_PLANE0, @ClipPlane[0]);
    glScalef(0, -1, 0);
    glTranslatef(0,-fHeight / 256, 0);

    glFrontFace(GL_CW);
    fReflectionPass.Render;
    glFrontFace(GL_CCW);
  glPopMatrix;

  glPushMatrix;
    glTranslatef(0, fHeight, 0);
    glClipPlane(GL_CLIP_PLANE0, @ClipPlane[0]);
  glPopMatrix;

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