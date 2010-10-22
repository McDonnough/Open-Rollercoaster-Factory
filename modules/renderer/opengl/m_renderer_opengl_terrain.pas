unit m_renderer_opengl_terrain;

interface

uses
  SysUtils, Classes, DGLOpenGL, m_renderer_opengl_classes, u_vectors, m_shdmng_class, m_texmng_class, u_math, math,
  m_renderer_opengl_interface, g_loader_ocf, m_renderer_opengl_lights, u_scene;

type
  TWaterLayerFBO = class
    public
      Height: Single;
      Deletable: Boolean;
      Check: Boolean;
      Query: TOcclusionQuery;
      RefractionFBO, ReflectionFBO: TFBO;
      Blocks: Array of Array of Boolean;
      constructor Create;
      destructor Free;
    end;

  TRTerrain = class(TThread)
    protected
      fForcedHeightLine: Single;
      fCanWork, fWorking: Boolean;
      fTerrainEditorIsOpen: Boolean;
      fCheckBBoxes, fCheckWater: Boolean;
      fUpdatePlants: Boolean;
      fFineVBO, fGoodVBO, fRawVBO, fWaterVBO, fBorderVBO: TVBO;
      fAPVBOs: Array[0..7] of TVBO;
      fAPCount: Array[0..7] of Integer;
      fAPPositions: Array[0..7] of Array of TVector2D;
      fShader, fShadowShader, fShaderTransformDepth, fShaderTransformSunShadow, fAPShader: TShader;
      fWaterShader, fWaterShaderTransformDepth, fWaterShaderTransformSunShadow: TShader;
      fWaterBumpmap: TTexture;
      fWaterBumpmapOffset: TVector2D;
      fHeightRanges: Array of Array of Array[0..1] of Single;
      fTmpFineOffsetX, fTmpFineOffsetY: Word;
      fFineOffsetX, fFineOffsetY: Word;
      fPrevPos: TVector2D;
      fHeightMap: TTexture;
      fFrameCount: Byte;
      RenderStep: Single;
      fMarks: Array of TGeoObject;
      procedure Sync;
      procedure Execute; override;
      procedure RecalcBoundingSpheres(X, Y: Integer);
      procedure CheckWaterLevel(X, Y: Word);
      function BlockIsEven(X, Y: Integer): Boolean;
    public
      fBoundingSphereRadius, fAvgHeight, fMinHeight: Array of Array of Single;
      fTerrainMarkOCF: TOCFFile;
      fWaterLayerFBOs: Array of TWaterLayerFBO;
      fStrongestLights: Array of Array of Array[0..6] of TLight;
      procedure ChangeTerrainEditorState(Event: String; Data, Result: Pointer);
      procedure SetHeightLine(Event: String; Data, Result: Pointer);
      procedure Render(Event: String; Data, Result: Pointer);
      procedure RenderAutoplants(Event: String; Data, Result: Pointer);
      procedure Advance;
      procedure RecreateWaterVBO;
      procedure RecreateBorderVBO;
      procedure CheckWaterLayerVisibility;
      procedure RenderWaterSurfaces;
      procedure UpdateCollection(Event: String; Data, Result: Pointer);
      procedure ApplyChanges(Event: String; Data, Result: Pointer);
      procedure Unload;
      constructor Create;
    end;

implementation

uses
  g_park, u_events, m_varlist, u_files, u_graphics, main, u_functions;

constructor TWaterLayerFBO.Create;
var
  i: Integer;
begin
  Query := TOcclusionQuery.Create;

  ReflectionFBO := TFBO.Create(512, 512, true);
  ReflectionFBO.AddTexture(GL_RGB, GL_LINEAR, GL_LINEAR);
  ReflectionFBO.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);
  ReflectionFBO.Unbind;

  RefractionFBO := TFBO.Create(512, 512, true);
  RefractionFBO.AddTexture(GL_RGBA16F, GL_LINEAR, GL_LINEAR);
  RefractionFBO.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);
  RefractionFBO.Unbind;

  setLength(Blocks, Park.pTerrain.SizeX div 128);
  for i := 0 to high(Blocks) do
    setLength(Blocks[i], Park.pTerrain.SizeY div 128);

  Check := false;
  Deletable := false;
end;

destructor TWaterLayerFBO.Free;
begin
  RefractionFBO.Free;
  ReflectionFBO.Free;
  Query.Free;
end;


procedure TRTerrain.Sync;
begin
  while fWorking do
    sleep(1);
  sleep(1);
end;

function TRTerrain.BlockIsEven(X, Y: Integer): Boolean;
begin
  Result := abs(fMinHeight[X, Y] - fAvgHeight[X, Y]) < 0.001;
end;

procedure TRTerrain.Execute;
var
  i, j, l: Integer;
  function Check(ID: Integer): Boolean;
  var
    i, j: Integer;
  begin
    fWaterLayerFBOs[ID].Check := False;
    for i := 0 to Park.pTerrain.SizeX - 1 do
      for j := 0 to Park.pTerrain.SizeY - 1 do
        begin
        if Round(10 * fWaterLayerFBOs[ID].Height) = Round(10 * Park.pTerrain.WaterMap[I / 5, J / 5]) then
          exit(false);
        end;
    Result := true;
  end;
begin
  fCanWork := false;
  fWorking := false;
  while not Terminated do
    begin
    try
      if fCanWork then
        begin
        fWorking := true;
        fCanWork := false;
        if fCheckWater then
          begin
          for l := 0 to high(fWaterLayerFBOs) do
            begin
            if fWaterLayerFBOs[l].Check then
              fWaterLayerFBOs[l].Deletable := Check(L);
            end;
          fCheckWater := false;
          end;
        if fCheckBBoxes then
          begin
          for i := 0 to Park.pTerrain.SizeX div 128 - 1 do
            for j := 0 to Park.pTerrain.SizeY div 128 - 1 do
              RecalcBoundingSpheres(i, j);
          fCheckBBoxes := false;
          end;
        end
      else
        sleep(1);
      fWorking := false;
    except
      ModuleManager.ModLog.AddError('Exception in terrain renderer thread');
    end;
    end;
  writeln('Hint: Terminated terrain renderer thread');
end;

procedure TRTerrain.ChangeTerrainEditorState(Event: String; Data, Result: Pointer);
begin
  fTerrainEditorIsOpen := not fTerrainEditorIsOpen;
end;

procedure TRTerrain.Advance;
begin
  fWaterBumpmapOffset := fWaterBumpmapOffset - Vector(0.00002, 0.00010) * FPSDisplay.MS;
end;

procedure TRTerrain.SetHeightLine(Event: String; Data, Result: Pointer);
begin
  fForcedHeightLine := Single(Data^);
end;

procedure TRTerrain.RecreateBorderVBO;
var
  i, j, n, vc: Integer;
begin
  writeln('Creating border VBO');
  vc := 4 * (Park.pTerrain.SizeX div 4 * 20 + Park.pTerrain.SizeY div 4 * 20 + 100 * 4);
  if fBorderVBO <> nil then
    fBorderVBO.Free;
  fBorderVBO := TVBO.Create(vc, GL_V3F, GL_QUADS);
  fBorderVBO.Bind;
  n := 0;
  for i := 0 to (Park.pTerrain.SizeX div 4) - 1 do
    for j := 0 to 9 do
      begin
      fBorderVBO.Vertices[n + 0] := Vector(0.8 * (i + 0), (j + 0) / 10, -500 * (j + 0));
      fBorderVBO.Vertices[n + 1] := Vector(0.8 * (i + 1), (j + 0) / 10, -500 * (j + 0));
      fBorderVBO.Vertices[n + 2] := Vector(0.8 * (i + 1), (j + 1) / 10, -500 * (j + 1));
      fBorderVBO.Vertices[n + 3] := Vector(0.8 * (i + 0), (j + 1) / 10, -500 * (j + 1));
      inc(n, 4);
      fBorderVBO.Vertices[n + 0] := Vector(0.8 * (i + 0), (j + 1) / 10, 0.2 * Park.pTerrain.SizeY + 500 * (j + 1));
      fBorderVBO.Vertices[n + 1] := Vector(0.8 * (i + 1), (j + 1) / 10, 0.2 * Park.pTerrain.SizeY + 500 * (j + 1));
      fBorderVBO.Vertices[n + 2] := Vector(0.8 * (i + 1), (j + 0) / 10, 0.2 * Park.pTerrain.SizeY + 500 * (j + 0));
      fBorderVBO.Vertices[n + 3] := Vector(0.8 * (i + 0), (j + 0) / 10, 0.2 * Park.pTerrain.SizeY + 500 * (j + 0));
      inc(n, 4);
      end;
  for i := 0 to (Park.pTerrain.SizeY div 4) - 1 do
    for j := 0 to 9 do
      begin
      fBorderVBO.Vertices[n + 0] := Vector(-500 * (j + 1), (j + 1) / 10, 0.8 * (i + 0));
      fBorderVBO.Vertices[n + 1] := Vector(-500 * (j + 1), (j + 1) / 10, 0.8 * (i + 1));
      fBorderVBO.Vertices[n + 2] := Vector(-500 * (j + 0), (j + 0) / 10, 0.8 * (i + 1));
      fBorderVBO.Vertices[n + 3] := Vector(-500 * (j + 0), (j + 0) / 10, 0.8 * (i + 0));
      inc(n, 4);
      fBorderVBO.Vertices[n + 0] := Vector(0.2 * Park.pTerrain.SizeX + 500 * (j + 0), (j + 0) / 10, 0.8 * (i + 0));
      fBorderVBO.Vertices[n + 1] := Vector(0.2 * Park.pTerrain.SizeX + 500 * (j + 0), (j + 0) / 10, 0.8 * (i + 1));
      fBorderVBO.Vertices[n + 2] := Vector(0.2 * Park.pTerrain.SizeX + 500 * (j + 1), (j + 1) / 10, 0.8 * (i + 1));
      fBorderVBO.Vertices[n + 3] := Vector(0.2 * Park.pTerrain.SizeX + 500 * (j + 1), (j + 1) / 10, 0.8 * (i + 0));
      inc(n, 4);
      end;
  for i := 0 to 9 do
    for j := 0 to 9 do
      begin
      fBorderVBO.Vertices[n + 0] := Vector(-500 * (j + 0), Min(1, VecLength(Vector(i + 0, j + 0)) / 10), -500 * (i + 0));
      fBorderVBO.Vertices[n + 1] := Vector(-500 * (j + 0), Min(1, VecLength(Vector(i + 1, j + 0)) / 10), -500 * (i + 1));
      fBorderVBO.Vertices[n + 2] := Vector(-500 * (j + 1), Min(1, VecLength(Vector(i + 1, j + 1)) / 10), -500 * (i + 1));
      fBorderVBO.Vertices[n + 3] := Vector(-500 * (j + 1), Min(1, VecLength(Vector(i + 0, j + 1)) / 10), -500 * (i + 0));
      inc(n, 4);
      fBorderVBO.Vertices[n + 0] := Vector(Park.pTerrain.SizeX / 5 + 500 * (j + 1), Min(1, VecLength(Vector(i + 0, j + 1)) / 10), -500 * (i + 0));
      fBorderVBO.Vertices[n + 1] := Vector(Park.pTerrain.SizeX / 5 + 500 * (j + 1), Min(1, VecLength(Vector(i + 1, j + 1)) / 10), -500 * (i + 1));
      fBorderVBO.Vertices[n + 2] := Vector(Park.pTerrain.SizeX / 5 + 500 * (j + 0), Min(1, VecLength(Vector(i + 1, j + 0)) / 10), -500 * (i + 1));
      fBorderVBO.Vertices[n + 3] := Vector(Park.pTerrain.SizeX / 5 + 500 * (j + 0), Min(1, VecLength(Vector(i + 0, j + 0)) / 10), -500 * (i + 0));
      inc(n, 4);
      fBorderVBO.Vertices[n + 0] := Vector(Park.pTerrain.SizeX / 5 + 500 * (j + 0), Min(1, VecLength(Vector(i + 0, j + 0)) / 10), Park.pTerrain.SizeY / 5 + 500 * (i + 0));
      fBorderVBO.Vertices[n + 1] := Vector(Park.pTerrain.SizeX / 5 + 500 * (j + 0), Min(1, VecLength(Vector(i + 1, j + 0)) / 10), Park.pTerrain.SizeY / 5 + 500 * (i + 1));
      fBorderVBO.Vertices[n + 2] := Vector(Park.pTerrain.SizeX / 5 + 500 * (j + 1), Min(1, VecLength(Vector(i + 1, j + 1)) / 10), Park.pTerrain.SizeY / 5 + 500 * (i + 1));
      fBorderVBO.Vertices[n + 3] := Vector(Park.pTerrain.SizeX / 5 + 500 * (j + 1), Min(1, VecLength(Vector(i + 0, j + 1)) / 10), Park.pTerrain.SizeY / 5 + 500 * (i + 0));
      inc(n, 4);
      fBorderVBO.Vertices[n + 0] := Vector(-500 * (j + 1), Min(1, VecLength(Vector(i + 0, j + 1)) / 10), Park.pTerrain.SizeY / 5 + 500 * (i + 0));
      fBorderVBO.Vertices[n + 1] := Vector(-500 * (j + 1), Min(1, VecLength(Vector(i + 1, j + 1)) / 10), Park.pTerrain.SizeY / 5 + 500 * (i + 1));
      fBorderVBO.Vertices[n + 2] := Vector(-500 * (j + 0), Min(1, VecLength(Vector(i + 1, j + 0)) / 10), Park.pTerrain.SizeY / 5 + 500 * (i + 1));
      fBorderVBO.Vertices[n + 3] := Vector(-500 * (j + 0), Min(1, VecLength(Vector(i + 0, j + 0)) / 10), Park.pTerrain.SizeY / 5 + 500 * (i + 0));
      inc(n, 4);
      end;
  fBorderVBO.Unbind;
end;

procedure TRTerrain.RecreateWaterVBO;
var
  i, j, n: Integer;
begin
  if fWaterVBO <> nil then
    fWaterVBO.Free;
  n := 0;
  fWaterVBO := TVBO.Create(4 * (Park.pTerrain.SizeX div 128) * (Park.pTerrain.SizeY div 128) + 4 * 4, GL_V3F, GL_QUADS);
  fWaterVBO.Bind;
  for i := 0 to Park.pTerrain.SizeX div 128 - 1 do
    for j := 0 to Park.pTerrain.SizeY div 128 - 1 do
      begin
      fWaterVBO.Vertices[4 * (Park.pTerrain.SizeX div 128 * j + i) + 0] := Vector(128 * i / 5, 0, 128 * j / 5);
      fWaterVBO.Vertices[4 * (Park.pTerrain.SizeX div 128 * j + i) + 1] := Vector(128 * (i + 1) / 5, 0, 128 * j / 5);
      fWaterVBO.Vertices[4 * (Park.pTerrain.SizeX div 128 * j + i) + 2] := Vector(128 * (i + 1) / 5, 0, 128 * (j + 1) / 5);
      fWaterVBO.Vertices[4 * (Park.pTerrain.SizeX div 128 * j + i) + 3] := Vector(128 * i / 5, 0, 128 * (j + 1) / 5);
      inc(n, 4);
      end;
  fWaterVBO.Vertices[n + 0] := Vector(Park.pTerrain.SizeX / 5, 0, 0);
  fWaterVBO.Vertices[n + 1] := Vector(5000 + Park.pTerrain.SizeX / 5, 0, -5000);
  fWaterVBO.Vertices[n + 2] := Vector(-5000, 0, -5000);
  fWaterVBO.Vertices[n + 3] := Vector(0, 0, 0);
  inc(n, 4);
  fWaterVBO.Vertices[n + 3] := Vector(0, 0, Park.pTerrain.SizeY / 5);
  fWaterVBO.Vertices[n + 2] := Vector(-5000, 0, Park.pTerrain.SizeY / 5 + 5000);
  fWaterVBO.Vertices[n + 1] := Vector(5000 + Park.pTerrain.SizeX / 5, 0, Park.pTerrain.SizeY / 5 + 5000);
  fWaterVBO.Vertices[n + 0] := Vector(Park.pTerrain.SizeX / 5, 0, Park.pTerrain.SizeY / 5);
  inc(n, 4);
  fWaterVBO.Vertices[n + 0] := Vector(0, 0, Park.pTerrain.SizeY / 5);
  fWaterVBO.Vertices[n + 1] := Vector(-5000, 0, 5000 + Park.pTerrain.SizeY / 5);
  fWaterVBO.Vertices[n + 2] := Vector(-5000, 0, -5000);
  fWaterVBO.Vertices[n + 3] := Vector(0, 0, 0);
  inc(n, 4);
  fWaterVBO.Vertices[n + 3] := Vector(Park.pTerrain.SizeX / 5, 0, Park.pTerrain.SizeY / 5);
  fWaterVBO.Vertices[n + 2] := Vector(Park.pTerrain.SizeX / 5 + 5000, 0, 5000 + Park.pTerrain.SizeY / 5);
  fWaterVBO.Vertices[n + 1] := Vector(Park.pTerrain.SizeX / 5 + 5000, 0, -5000);
  fWaterVBO.Vertices[n + 0] := Vector(Park.pTerrain.SizeX / 5, 0, 0);
  inc(n, 4);
  fWaterVBO.Unbind;
end;

procedure TRTerrain.Render(Event: String; Data, Result: Pointer);
var
  fBoundShader: TShader;
  CurrWaterLayer: Integer;
  WaterModeRefraction: Boolean;
  fBelow, fAbove: Single;

  procedure BindBlockLights(X, Y: Integer);
  var
    k: Integer;
  begin
    X := Round(Clamp(X, 0, Park.pTerrain.SizeX div 128 - 1));
    Y := Round(Clamp(Y, 0, Park.pTerrain.SizeY div 128 - 1));
    if fInterface.Options.Items['shader:mode'] = 'normal:normal' then
      begin
      ModuleManager.ModRenderer.LightManager.StartBinding;
      for k := 0 to high(fStrongestLights[X, Y]) do
        if fStrongestLights[X, Y, k] <> nil then
          fStrongestLights[X, Y, k].Bind(k + 1)
        else
          ModuleManager.ModRenderer.LightManager.NoLight.Bind(k + 1);
      ModuleManager.ModRenderer.LightManager.EndBinding;
      end;
  end;

  procedure RenderBlock(X, Y: Integer; Check: Boolean);
  var
    k: Integer;
  begin
    try
      if (fBoundShader = fShaderTransformSunShadow) or (fBoundShader = fShadowShader) then
        if BlockIsEven(X, Y) then
          exit;
      if (X >= 0) and (Y >= 0) and (X <= Park.pTerrain.SizeX div 128 - 1) and (Y <= Park.pTerrain.SizeY div 128 - 1) then
        if (ModuleManager.ModRenderer.Frustum.IsSphereWithin(12.8 + 25.6 * X, fAvgHeight[X, Y], 12.8 + 25.6 * Y, fBoundingSphereRadius[X, Y])) and (SphereSphereIntersection(Sphere(Vector(12.8 + 25.6 * X, fAvgHeight[X, Y], 12.8 + 25.6 * Y), fBoundingSphereRadius[X, Y]), Sphere(ModuleManager.ModRenderer.DistanceMeasuringPoint, ModuleManager.ModRenderer.MaxRenderDistance))) then
          begin
          if WaterModeRefraction then
            if not fWaterLayerFBOs[CurrWaterLayer].Blocks[X, Y] then
              exit;
          if (fHeightRanges[X, Y, 0] > fBelow) or (fHeightRanges[X, Y, 1] < fAbove) then
            exit;
          ModuleManager.ModRenderer.MinRenderHeight := Min(ModuleManager.ModRenderer.MinRenderHeight, fMinHeight[X, Y] - 8);
          fBoundShader.UniformF('VOffset', 128 * x / 5, 128 * y / 5);
          if fInterface.Options.Items['shader:mode'] = 'normal:normal' then
            begin
            ModuleManager.ModRenderer.LightManager.StartBinding;
            for k := 0 to high(fStrongestLights[X, Y]) do
              if fStrongestLights[X, Y, k] <> nil then
                fStrongestLights[X, Y, k].Bind(k + 1)
              else
                ModuleManager.ModRenderer.LightManager.NoLight.Bind(k + 1);
            ModuleManager.ModRenderer.LightManager.EndBinding;
            end;
          if ((VecLengthNoRoot(Vector(128 * x / 5, 0, 128 * y / 5) + Vector(12.8, 0.0, 12.8) - ModuleManager.ModCamera.ActiveCamera.Position * Vector(1, 0, 1)) < 13000) and (ModuleManager.ModRenderer.StaticLODBias + ModuleManager.ModRenderer.DynamicLODBias <= 0)) or (ModuleManager.ModRenderer.StaticLODBias + ModuleManager.ModRenderer.DynamicLODBias < 0) then
            begin
            fBoundShader.UniformI('LOD', 1);
            fGoodVBO.Bind;
            fGoodVBO.Render;
            fGoodVBO.Unbind;
            end
          else
            begin
            fBoundShader.UniformI('LOD', 0);
            fRawVBO.Bind;
            fRawVBO.Render;
            fRawVBO.Unbind;
            end;
          end;
    except
      writeln('Exception: ', X, ' ', Y);
    end;
  end;
var
  i, j, k: integer;
  Blocks: Array of Array[0..2] of Integer;
  fFineBlockX, fFineBlockY: Integer;
  DoFineRender: Boolean;
begin
  WaterModeRefraction := fInterface.Options.Items['water:mode'] = 'refraction';
  CurrWaterLayer := StrToIntWD(fInterface.Options.Items['water:currlayer'], 0);
  fBelow := StrToFloatWD(fInterface.Options.Items['all:below'], 256);
  fAbove := StrToFloatWD(fInterface.Options.Items['all:above'], 0);
  if not fWorking then
    for i := 0 to high(fWaterLayerFBOs) do
      if i > high(fWaterLayerFBOs) then
        exit
      else
        if fWaterLayerFBOs[i].Deletable then
          begin
          fWaterLayerFBOs[i].Free;
          fWaterLayerFBOs[i] := fWaterLayerFBOs[high(fWaterLayerFBOs)];
          SetLength(fWaterLayerFBOs, length(fWaterLayerFBOs) - 1);
          end;
  glDisable(GL_BLEND);
  fHeightMap.Bind(1);
  Park.pTerrain.Collection.Texture.Bind(0);
  fFineOffsetX := 4 * Round(Clamp((ModuleManager.ModCamera.ActiveCamera.Position.X) * 5 - 128, 0, Park.pTerrain.SizeX - 256) / 4);
  fFineOffsetY := 4 * Round(Clamp((ModuleManager.ModCamera.ActiveCamera.Position.Z) * 5 - 128, 0, Park.pTerrain.SizeY - 256) / 4);
  fBoundShader := fShader;
  if fInterface.Options.Items['shader:mode'] = 'transform:depth' then
    fBoundShader := fShaderTransformDepth
  else if fInterface.Options.Items['shader:mode'] = 'shadow:shadow' then
    fBoundShader := fShadowShader
  else if fInterface.Options.Items['shader:mode'] = 'sunshadow:sunshadow' then
    fBoundShader := fShaderTransformSunShadow
  else
    begin
    if (Park.pTerrain.CurrMark.X >= 0) and (Park.pTerrain.CurrMark.Y >= 0) and (Park.pTerrain.CurrMark.X <= 0.2 * Park.pTerrain.SizeX) and (Park.pTerrain.CurrMark.Y <= 0.2 * Park.pTerrain.SizeY) and (Park.pTerrain.MarkMode = 0) then
      fBoundShader.UniformF('PointToHighlight', Park.pTerrain.CurrMark.X, Park.pTerrain.CurrMark.Y)
    else
      fBoundShader.UniformF('PointToHighlight', -1, -1);
    if (Park.pTerrain.MarkMode = 1) then
      fBoundShader.UniformF('HeightLineToHighlight', 0.1 + Round(10 * Park.pTerrain.HeightMap[Park.pTerrain.CurrMark.X, Park.pTerrain.CurrMark.Y]) / 10)
    else
      fBoundShader.UniformF('HeightLineToHighlight', fForcedHeightLine);
    if fTerrainEditorIsOpen then
      begin
      fBoundShader.UniformF('Min', 0, 0);
      fBoundShader.UniformF('Max', Park.pTerrain.SizeX / 5, Park.pTerrain.SizeY / 5);
      end
    else
      begin
      fBoundShader.UniformF('Min', -10000, -10000);
      fBoundShader.UniformF('Max', 10000, 10000);
      end;
    end;
  fBoundShader.Bind;
  fBoundShader.UniformF('Scale', 1, 1);
  fBoundShader.UniformF('ShadowQuadA', ModuleManager.ModRenderer.ShadowQuad[0].X, ModuleManager.ModRenderer.ShadowQuad[0].Z);
  fBoundShader.UniformF('ShadowQuadB', ModuleManager.ModRenderer.ShadowQuad[1].X, ModuleManager.ModRenderer.ShadowQuad[1].Z);
  fBoundShader.UniformF('ShadowQuadC', ModuleManager.ModRenderer.ShadowQuad[2].X, ModuleManager.ModRenderer.ShadowQuad[2].Z);
  fBoundShader.UniformF('ShadowQuadD', ModuleManager.ModRenderer.ShadowQuad[3].X, ModuleManager.ModRenderer.ShadowQuad[3].Z);
  if fInterface.Options.Items['terrain:hd'] <> 'off' then
    begin
    fBoundShader.UniformF('offset', fFineOffsetX / 5, fFineOffsetY / 5);
    if fBoundShader = fShader then
      fBoundShader.UniformF('NFactor', 1.0);
    end
  else
    begin
    fBoundShader.UniformF('offset', -10000, -10000);
    if fBoundShader = fShader then
      fBoundShader.UniformF('NFactor', 4.0);
    end;
  setLength(Blocks, Park.pTerrain.SizeX div 128 * Park.pTerrain.SizeY div 128);
  for i := 0 to Park.pTerrain.SizeX div 128 - 1 do
    for j := 0 to Park.pTerrain.SizeY div 128 - 1 do
      begin
      Blocks[Park.pTerrain.SizeY div 128 * i + j, 0] := Round(VecLengthNoRoot(Vector(128 * I / 5, 0, 128 * J / 5) + Vector(12.8, 0.0, 12.8) - ModuleManager.ModCamera.ActiveCamera.Position * Vector(1, 0, 1)));
      Blocks[Park.pTerrain.SizeY div 128 * i + j, 1] := i;
      Blocks[Park.pTerrain.SizeY div 128 * i + j, 2] := j;
      end;
  for i := 0 to high(Blocks) - 1 do
    for j := i + 1 to high(Blocks) do
      if Blocks[i, 0] > Blocks[j, 0] then
        begin
        k := Blocks[i, 0]; Blocks[i, 0] := Blocks[j, 0]; Blocks[j, 0] := k;
        k := Blocks[i, 1]; Blocks[i, 1] := Blocks[j, 1]; Blocks[j, 1] := k;
        k := Blocks[i, 2]; Blocks[i, 2] := Blocks[j, 2]; Blocks[j, 2] := k;
        end;
  if fInterface.Options.Items['shader:mode'] = 'normal:normal' then
    begin
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glDisable(GL_ALPHA_TEST);
    end;
  for i := 0 to high(Blocks) do
    RenderBlock(Blocks[i, 1], Blocks[i, 2], fBoundShader = fShaderTransformDepth);
  if fInterface.Options.Items['terrain:hd'] <> 'off' then
    begin
    DoFineRender := true;
    if ((fBoundShader = fShadowShader) or (fBoundShader = fShaderTransformSunShadow)) and (
          (BlockIsEven(Floor((fFineOffsetX + 64) / 128), Floor((fFineOffsetY + 64) / 128)))
      and (BlockIsEven(Floor((fFineOffsetX + 64) / 128), Floor((fFineOffsetY + 192) / 128)))
      and (BlockIsEven(Floor((fFineOffsetX + 192) / 128), Floor((fFineOffsetY + 192) / 128)))
      and (BlockIsEven(Floor((fFineOffsetX + 192) / 128), Floor((fFineOffsetY + 64) / 128)))) then
        DoFineRender := false;

    if DoFineRender then
      begin
      glDisable(GL_CULL_FACE);
      fBoundShader.UniformI('LOD', 2);
      fBoundShader.UniformF('VOffset', fFineOffsetX / 5 + 25.6, fFineOffsetY / 5 + 25.6);
      fFineVBO.Bind;
      BindBlockLights(Floor((fFineOffsetX + 192) / 128), Floor((fFineOffsetY + 192) / 128));
      fBoundShader.UniformF('Scale', 1, 1);
      fFineVBO.Render;
      BindBlockLights(Floor((fFineOffsetX + 64) / 128), Floor((fFineOffsetY + 192) / 128));
      fBoundShader.UniformF('Scale', -1, 1);
      fFineVBO.Render;
      BindBlockLights(Floor((fFineOffsetX + 64) / 128), Floor((fFineOffsetY + 64) / 128));
      fBoundShader.UniformF('Scale', -1, -1);
      fFineVBO.Render;
      BindBlockLights(Floor((fFineOffsetX + 192) / 128), Floor((fFineOffsetY + 64) / 128));
      fBoundShader.UniformF('Scale', 1, -1);
      fFineVBO.Render;
      fFineVBO.Unbind;
      fBoundShader.UniformF('Scale', 1, 1);
      glEnable(GL_CULL_FACE);
      end;
    end;
  if (fBoundShader <> fShadowShader) and (fBoundShader <> fShaderTransformSunShadow) then
    begin
    fBoundShader.UniformI('LOD', 3);
    fBoundShader.UniformF('VOffset', 0, 0);
    fBorderVBO.Bind;
    fBorderVBO.Render;
    fBorderVBO.Unbind;
    end;
  fBoundShader.Unbind;
  Park.pTerrain.Collection.Texture.UnBind;

  glUseProgram(0);

  // Render marks - WILL BE REPLACED
  glDisable(GL_TEXTURE_2D);
  glDisable(GL_CULL_FACE);

  for i := high(fMarks) downto Park.pTerrain.Marks.Height do
    begin
    fMarks[i].Free;
    SetLength(fMarks, length(fMarks) - 1);
    end;

  for i := high(fMarks) + 1 to Park.pTerrain.Marks.Height - 1 do
    begin
    SetLength(fMarks, length(fMarks) + 1);
    fMarks[i] := TGeoObject.Create;
//     fMarks[i].ReadFromOCFFile(fTerrainMarkOCF);
    end;


    for i := 0 to high(fMarks) do
      begin
      fMarks[i].Matrix := TranslationMatrix(Vector(Park.pTerrain.Marks.Value[0, i], Park.pTerrain.HeightMap[0.2 * Park.pTerrain.Marks.Value[0, i], 0.2 * Park.pTerrain.Marks.Value[1, i]], Park.pTerrain.Marks.Value[1, i]));
      glVertex3f(0.2 * Park.pTerrain.Marks.Value[0, i] - 0.1, 0.1 + Park.pTerrain.HeightMap[0.2 * Park.pTerrain.Marks.Value[0, i], 0.2 * Park.pTerrain.Marks.Value[1, i]], 0.2 * Park.pTerrain.Marks.Value[1, i] - 0.1);
      glVertex3f(0.2 * Park.pTerrain.Marks.Value[0, i] + 0.1, 0.1 + Park.pTerrain.HeightMap[0.2 * Park.pTerrain.Marks.Value[0, i], 0.2 * Park.pTerrain.Marks.Value[1, i]], 0.2 * Park.pTerrain.Marks.Value[1, i] - 0.1);
      glVertex3f(0.2 * Park.pTerrain.Marks.Value[0, i] + 0.1, 0.1 + Park.pTerrain.HeightMap[0.2 * Park.pTerrain.Marks.Value[0, i], 0.2 * Park.pTerrain.Marks.Value[1, i]], 0.2 * Park.pTerrain.Marks.Value[1, i] + 0.1);
      glVertex3f(0.2 * Park.pTerrain.Marks.Value[0, i] - 0.1, 0.1 + Park.pTerrain.HeightMap[0.2 * Park.pTerrain.Marks.Value[0, i], 0.2 * Park.pTerrain.Marks.Value[1, i]], 0.2 * Park.pTerrain.Marks.Value[1, i] + 0.1);
      end;
    if (Park.pTerrain.CurrMark.X >= 0) and (Park.pTerrain.CurrMark.Y >= 0) and (Park.pTerrain.CurrMark.X <= 0.2 * Park.pTerrain.SizeX) and (Park.pTerrain.CurrMark.Y <= 0.2 * Park.pTerrain.SizeY) then
      if Park.pTerrain.MarkMode = 0 then
        begin
        glColor4f(1, 0, 0, 1.0);
        glVertex3f(Park.pTerrain.CurrMark.X - 0.1, 0.1 + Park.pTerrain.HeightMap[Park.pTerrain.CurrMark.X, Park.pTerrain.CurrMark.Y], Park.pTerrain.CurrMark.Y - 0.1);
        glVertex3f(Park.pTerrain.CurrMark.X + 0.1, 0.1 + Park.pTerrain.HeightMap[Park.pTerrain.CurrMark.X, Park.pTerrain.CurrMark.Y], Park.pTerrain.CurrMark.Y - 0.1);
        glVertex3f(Park.pTerrain.CurrMark.X + 0.1, 0.1 + Park.pTerrain.HeightMap[Park.pTerrain.CurrMark.X, Park.pTerrain.CurrMark.Y], Park.pTerrain.CurrMark.Y + 0.1);
        glVertex3f(Park.pTerrain.CurrMark.X - 0.1, 0.1 + Park.pTerrain.HeightMap[Park.pTerrain.CurrMark.X, Park.pTerrain.CurrMark.Y], Park.pTerrain.CurrMark.Y + 0.1);
        end
      else
        begin
        glColor4f(1, 0, 0, 1.0);
        glVertex3f(Park.pTerrain.CurrMark.X - 0.1, 0.1 + Round(10 * Park.pTerrain.HeightMap[Park.pTerrain.CurrMark.X, Park.pTerrain.CurrMark.Y]) / 10, Park.pTerrain.CurrMark.Y - 0.1);
        glVertex3f(Park.pTerrain.CurrMark.X + 0.1, 0.1 + Round(10 * Park.pTerrain.HeightMap[Park.pTerrain.CurrMark.X, Park.pTerrain.CurrMark.Y]) / 10, Park.pTerrain.CurrMark.Y - 0.1);
        glVertex3f(Park.pTerrain.CurrMark.X + 0.1, 0.1 + Round(10 * Park.pTerrain.HeightMap[Park.pTerrain.CurrMark.X, Park.pTerrain.CurrMark.Y]) / 10, Park.pTerrain.CurrMark.Y + 0.1);
        glVertex3f(Park.pTerrain.CurrMark.X - 0.1, 0.1 + Round(10 * Park.pTerrain.HeightMap[Park.pTerrain.CurrMark.X, Park.pTerrain.CurrMark.Y]) / 10, Park.pTerrain.CurrMark.Y + 0.1);
        end;

  glBegin(GL_LINE_LOOP);
    glColor4f(1, 1, 1, 1);
    for i := 0 to Park.pTerrain.Marks.Height - 1 do
      glVertex3f(0.2 * Park.pTerrain.Marks.Value[0, i], 0.1 + Park.pTerrain.HeightMap[0.2 * Park.pTerrain.Marks.Value[0, i], 0.2 * Park.pTerrain.Marks.Value[1, i]], 0.2 * Park.pTerrain.Marks.Value[1, i]);
    if (Park.pTerrain.CurrMark.X >= 0) and (Park.pTerrain.CurrMark.Y >= 0) and (Park.pTerrain.CurrMark.X <= 0.2 * Park.pTerrain.SizeX) and (Park.pTerrain.CurrMark.Y <= 0.2 * Park.pTerrain.SizeY) then
      glVertex3f(Park.pTerrain.CurrMark.X, 0.1 + Park.pTerrain.HeightMap[Park.pTerrain.CurrMark.X, Park.pTerrain.CurrMark.Y], Park.pTerrain.CurrMark.Y);
  glEnd;

//   glDisable(GL_DEPTH_TEST);
//   glDisable(GL_CULL_FACE);
//   glBegin(GL_QUADS);
//     with ModuleManager.ModRenderer do
//       begin
//       glColor4f(0, 0, 0, 1); glVertex3f(ShadowQuad[0].X, 64, ShadowQuad[0].Z);
//       glColor4f(1, 0, 0, 1); glVertex3f(ShadowQuad[1].X, 64, ShadowQuad[1].Z);
//       glColor4f(1, 1, 0, 1); glVertex3f(ShadowQuad[2].X, 64, ShadowQuad[2].Z);
//       glColor4f(0, 1, 0, 1); glVertex3f(ShadowQuad[3].X, 64, ShadowQuad[3].Z);
//       glColor4f(1, 1, 1, 1);
//       end;
//   glEnd;
//   glEnable(GL_CULL_FACE);
//   glEnable(GL_DEPTH_TEST);

  glEnable(GL_TEXTURE_2D);
  if fInterface.Options.Items['all:renderpass'] = '0' then
    fUpdatePlants := true;

  fHeightMap.Unbind;
end;

procedure TRTerrain.RenderAutoplants(Event: String; Data, Result: Pointer);
const
  AUTOPLANT_UPDATE_FRAMES = 10;
var
  i, j, k: Integer;
  fDeg, fRot: Single;
  Position, fTmp: TVector2D;
  fFineBlockX, fFineBlockY: Integer;
begin
  // Render autoplants
  fFineBlockX := Round((fFineOffsetX + 128) / 128);
  fFineBlockY := Round((fFineOffsetY + 128) / 128);
  if fInterface.Options.Items['shader:mode'] = 'normal:normal' then
    begin
    ModuleManager.ModRenderer.LightManager.StartBinding;
    for k := 0 to high(fStrongestLights[fFineBlockX, fFineBlockY]) do
      if fStrongestLights[fFineBlockX, fFineBlockY, k] <> nil then
        fStrongestLights[fFineBlockX, fFineBlockY, k].Bind(k + 1)
      else
        ModuleManager.ModRenderer.LightManager.NoLight.Bind(k + 1);
    ModuleManager.ModRenderer.LightManager.EndBinding;
    end;
  if (ModuleManager.ModRenderer.StaticLODBias + ModuleManager.ModRenderer.DynamicLODBias <= 0) and (fInterface.Options.Items['terrain:autoplants'] <> 'off') then
    begin
    fHeightMap.Bind(1);
    glDisable(GL_CULL_FACE);
    glColor4f(1, 1, 1, 1);
    glEnable(GL_BLEND);
    glEnable(GL_ALPHA_TEST);
    glAlphaFunc(GL_GREATER, 0.2);
    fAPShader.Bind;
    fAPShader.UniformF('ShadowQuadA', ModuleManager.ModRenderer.ShadowQuad[0].X, ModuleManager.ModRenderer.ShadowQuad[0].Z);
    fAPShader.UniformF('ShadowQuadB', ModuleManager.ModRenderer.ShadowQuad[1].X, ModuleManager.ModRenderer.ShadowQuad[1].Z);
    fAPShader.UniformF('ShadowQuadC', ModuleManager.ModRenderer.ShadowQuad[2].X, ModuleManager.ModRenderer.ShadowQuad[2].Z);
    fAPShader.UniformF('ShadowQuadD', ModuleManager.ModRenderer.ShadowQuad[3].X, ModuleManager.ModRenderer.ShadowQuad[3].Z);
    if fUpdatePlants then
      begin
      inc(fFrameCount);
      if fFrameCount = AUTOPLANT_UPDATE_FRAMES then
        fFrameCount := 0;
      end;
    for i := 0 to high(fAPVBOs) do
      if fAPVBOs[i] <> nil then
        begin
        fAPShader.UniformF('TexToDo', i);
        Park.pTerrain.Collection.Materials[i].AutoplantProperties.Texture.Bind(0);
        if fUpdatePlants then
          begin
          fAPVBOs[i].Bind;
          for j := 0 to high(fAPPositions[i]) * fFrameCount div AUTOPLANT_UPDATE_FRAMES do
            begin
            if VecLengthNoRoot(fAPPositions[i, j] - Vector(ModuleManager.ModCamera.ActiveCamera.Position.X, ModuleManager.ModCamera.ActiveCamera.Position.Z)) > 400 then
              begin
              fDeg := PI * 2 * Random;
              fRot := PI * 2 * Random;
              fTMP := Vector(Sin(fRot), Cos(fRot)) * 0.6;
              Position := Vector(ModuleManager.ModCamera.ActiveCamera.Position.X, ModuleManager.ModCamera.ActiveCamera.Position.Z) + Vector(Sin(fDeg), Cos(fDeg)) * (2 * Random + 18);
              fAPPositions[i, j] := Position;
              inc(fAPCount[i]);
              if Park.pTerrain.TexMap[Position.X, Position.Y] = i then
                begin
                fAPVBOs[i].Vertices[4 * j + 0] := Vector(fAPPositions[i, j].X, 0, fAPPositions[i, j].Y);
                fAPVBOs[i].Vertices[4 * j + 1] := Vector(fAPPositions[i, j].X, 0.3, fAPPositions[i, j].Y);
                fAPVBOs[i].Vertices[4 * j + 2] := Vector(fAPPositions[i, j].X + fTMP.X, 0.3, fAPPositions[i, j].Y + fTMP.Y);
                fAPVBOs[i].Vertices[4 * j + 3] := Vector(fAPPositions[i, j].X + fTMP.X, 0, fAPPositions[i, j].Y + fTMP.Y);
                end
              else
                begin
                fAPVBOs[i].Vertices[4 * j + 0] := Vector(0, 0, 0);
                fAPVBOs[i].Vertices[4 * j + 1] := Vector(0, 0, 0);
                fAPVBOs[i].Vertices[4 * j + 2] := Vector(0, 0, 0);
                fAPVBOs[i].Vertices[4 * j + 3] := Vector(0, 0, 0);
                dec(fAPCount[i]);
                end;
              end;
            end;
          fAPVBOs[i].Unbind;
          end;
        if fAPCount[i] > 0 then
          begin
          fAPVBOs[i].Bind;
          fAPVBOs[i].Render;
          fAPVBOs[i].Unbind;
          end;
        end;
    fAPShader.Unbind;
    glEnable(GL_CULL_FACE);
    fUpdatePlants := false;
    fHeightMap.UnBind;
    end;
end;

procedure TRTerrain.CheckWaterLayerVisibility;
var
  i: Integer;
begin
  glDisable(GL_CULL_FACE);
  fWaterShaderTransformDepth.Bind;
  fHeightMap.Bind(0);
  for i := 0 to high(fWaterLayerFBOs) do
    begin
    if fWaterLayerFBOs[i].Deletable then
      continue;
    glTexCoord3f(0, 0, fWaterLayerFBOs[i].Height);
    fWaterLayerFBOs[i].Query.StartCounter;
    glBegin(GL_QUADS);
      glVertex3f(-5000, 0, -5000);
      glVertex3f(Park.pTerrain.SizeX / 5 + 5000, 0, -5000);
      glVertex3f(Park.pTerrain.SizeX / 5 + 5000, 0, Park.pTerrain.SizeY / 5 + 5000);
      glVertex3f(-5000, 0, Park.pTerrain.SizeY / 5 + 5000);
    glEnd;
    fWaterLayerFBOs[i].Query.EndCounter;
    end;
  fHeightMap.Unbind;
  fWaterShaderTransformDepth.Unbind;
  glEnable(GL_CULL_FACE);
end;

procedure TRTerrain.RenderWaterSurfaces;
var
  i, j, k: Integer;
  fBoundShader: TShader;
begin
  glEnable(GL_BLEND);
  glDisable(GL_CULL_FACE);

  fBoundShader := fWaterShader;
  if fInterface.Options.Items['shader:mode'] = 'transform:depth' then
    fBoundShader := fWaterShaderTransformDepth
  else if fInterface.Options.Items['shader:mode'] = 'sunshadow:sunshadow' then
    fBoundShader := fWaterShaderTransformSunShadow;
  fBoundShader.Bind;
  fBoundShader.UniformF('ShadowQuadA', ModuleManager.ModRenderer.ShadowQuad[0].X, ModuleManager.ModRenderer.ShadowQuad[0].Z);
  fBoundShader.UniformF('ShadowQuadB', ModuleManager.ModRenderer.ShadowQuad[1].X, ModuleManager.ModRenderer.ShadowQuad[1].Z);
  fBoundShader.UniformF('ShadowQuadC', ModuleManager.ModRenderer.ShadowQuad[2].X, ModuleManager.ModRenderer.ShadowQuad[2].Z);
  fBoundShader.UniformF('ShadowQuadD', ModuleManager.ModRenderer.ShadowQuad[3].X, ModuleManager.ModRenderer.ShadowQuad[3].Z);
  if fInterface.Options.Items['shader:mode'] = 'normal:normal' then
    begin
    if (Park.pTerrain.MarkMode = 1) then
      fBoundShader.UniformF('HeightLineToHighlight', 0.1 + Round(10 * Park.pTerrain.HeightMap[Park.pTerrain.CurrMark.X, Park.pTerrain.CurrMark.Y]) / 10)
    else
      fBoundShader.UniformF('HeightLineToHighlight', fForcedHeightLine);

    if fInterface.Options.Items['water:reflection'] = 'off' then
      fBoundShader.UniformI('UseReflection', 0)
    else
      fBoundShader.UniformI('UseReflection', 1);
    if fInterface.Options.Items['water:refraction'] = 'off' then
      fBoundShader.UniformI('UseRefraction', 0)
    else
      fBoundShader.UniformI('UseRefraction', 1);
    end;

  for k := 0 to high(fWaterLayerFBOs) do
    begin
//     if fWaterLayerFBOs[k].Query.Result = 0 then
//       continue;
    fWaterLayerFBOs[k].ReflectionFBO.Textures[0].Bind(1);
    fWaterLayerFBOs[k].RefractionFBO.Textures[0].Bind(2);
    fWaterBumpmap.Bind(3);
    fHeightMap.Bind(0);
    glTexCoord3f(fWaterBumpmapOffset.X, fWaterBumpmapOffset.Y, fWaterLayerFBOs[k].Height);
    fWaterVBO.Bind;
    fWaterVBO.Render;
    fWaterVBO.Unbind;
    end;

  fBoundShader.Unbind;

  glEnable(GL_CULL_FACE);
end;

procedure TRTerrain.RecalcBoundingSpheres(X, Y: Integer);
var
  i, j, k: Integer;
  avgh, minh, temp, temp2: Single;
  a, b, c, d: Single;
begin
  avgh := 0;
  minh := 256;
  fHeightRanges[X, Y, 0] := 256;
  fHeightRanges[X, Y, 1] := 0;
  for i := 0 to high(fWaterLayerFBOs) do
    fWaterLayerFBOs[i].Blocks[X, Y] := false;
  for i := 0 to 128 do
    for j := 0 to 128 do
      begin
      temp := Park.pTerrain.HeightMap[25.6 * X + 0.2 * i, 25.6 * Y + 0.2 * j];
      temp2 := Park.pTerrain.WaterMap[25.6 * X + 0.2 * i, 25.6 * Y + 0.2 * j];
      for k := 0 to high(fWaterLayerFBOs) do
        fWaterLayerFBOs[k].Blocks[X, Y] := fWaterLayerFBOs[k].Blocks[X, Y] or (Round(256 * temp2) = Round(256 * fWaterLayerFBOs[k].Height));
      if temp < fHeightRanges[X, Y, 0] then fHeightRanges[X, Y, 0] := temp;
      if temp > fHeightRanges[X, Y, 1] then fHeightRanges[X, Y, 1] := temp;
      if (i = 0) and (j = 0) then
        a := temp
      else if (i = 128) and (j = 0) then
        b := temp
      else if (i = 0) and (j = 128) then
        c := temp
      else if (i = 128) and (j = 128) then
        d := temp;
      avgh := avgh + temp;
      minh := Min(minh, temp);
      end;
  avgh := avgh / 129 / 129;
  fAvgHeight[X, Y] := avgh;
  fMinHeight[X, Y] := minh;
  fBoundingSphereRadius[X, Y] := VecLength(Vector(12.8, Max(Max(a, b), Max(c, d)) - avgh, 12.8));
end;

procedure TRTerrain.CheckWaterLevel(X, Y: Word);
var
  i: integer;
begin
  if Park.pTerrain.WaterMap[X / 5, Y / 5] = 0 then
    exit;
  for i := 0 to high(fWaterLayerFBOs) do
    if Round(10 * fWaterLayerFBOs[i].Height) = Round(10 * Park.pTerrain.WaterMap[X / 5, Y / 5]) then
      exit;
  for i := 0 to high(fWaterLayerFBOs) do
    fWaterLayerFBOs[i].Check := true;
  for i := 0 to high(fWaterLayerFBOs) do
    if fWaterLayerFBOs[i].Deletable then
      begin
      fWaterLayerFBOs[i].Deletable := false;
      fWaterLayerFBOs[i].Height := Park.pTerrain.WaterMap[X / 5, Y / 5];
      exit;
      end;
  setLength(fWaterLayerFBOs, length(fWaterLayerFBOs) + 1);
  fWaterLayerFBOs[high(fWaterLayerFBOs)] := TWaterLayerFBO.Create;
  fWaterLayerFBOs[high(fWaterLayerFBOs)].Height := Round(10 * Park.pTerrain.WaterMap[X / 5, Y / 5]) / 10;
end;

procedure TRTerrain.ApplyChanges(Event: String; Data, Result: Pointer);
var
  i, j, k, l: Integer;
  Pixel: TVector4D;
  hd: Boolean;
  procedure StartUpdate;
  begin
    fHeightMap.Bind(0);
  end;

  procedure UpdateVertex(X, Y: Word);
  begin
    Pixel := Vector(Park.pTerrain.TexMap[X / 5, Y / 5] / 8, Park.pTerrain.WaterMap[X / 5, Y / 5] / 256, 0.0, Park.pTerrain.HeightMap[X / 5, Y / 5] / 256);
    glTexSubImage2D(GL_TEXTURE_2D, 0, X, Y, 1, 1, GL_RGBA, GL_FLOAT, @Pixel.X);
  end;

  procedure UpdateVertexSD(X, Y: Word);
  begin
    if (x mod 4 <> 0) or (y mod 4 = 0) then exit;
    Pixel := Vector(Park.pTerrain.TexMap[X / 5, Y / 5] / 8, Park.pTerrain.WaterMap[X / 5, Y / 5] / 256, 0.0, Park.pTerrain.HeightMap[X / 5, Y / 5] / 256);
    glTexSubImage2D(GL_TEXTURE_2D, 0, X div 4, Y div 4, 1, 1, GL_RGBA, GL_FLOAT, @Pixel.X);
  end;

  procedure EndUpdate;
  begin
    fHeightMap.Unbind;
  end;
begin
  hd := fInterface.Options.Items['terrain:hd'] <> 'off';
  if Event = 'TTerrain.Resize' then
    begin
    Sync;
    RecreateWaterVBO;
    fShader.UniformF('TerrainSize', Park.pTerrain.SizeX, Park.pTerrain.SizeY);
    fShadowShader.UniformF('TerrainSize', Park.pTerrain.SizeX, Park.pTerrain.SizeY);
    fShaderTransformDepth.UniformF('TerrainSize', Park.pTerrain.SizeX, Park.pTerrain.SizeY);
    fShaderTransformSunShadow.UniformF('TerrainSize', Park.pTerrain.SizeX, Park.pTerrain.SizeY);
    fWaterShader.UniformF('TerrainSize', Park.pTerrain.SizeX, Park.pTerrain.SizeY);
    fWaterShaderTransformDepth.UniformF('TerrainSize', Park.pTerrain.SizeX, Park.pTerrain.SizeY);
    fWaterShaderTransformSunShadow.UniformF('TerrainSize', Park.pTerrain.SizeX, Park.pTerrain.SizeY);
    fAPShader.UniformF('TerrainSize', Park.pTerrain.SizeX, Park.pTerrain.SizeY);
    if fHeightMap <> nil then
      fHeightMap.Free;
    fHeightMap := TTexture.Create;
    if hd then
      fHeightMap.CreateNew(Park.pTerrain.SizeX, Park.pTerrain.SizeY, GL_RGBA32F)
    else
      fHeightMap.CreateNew(Park.pTerrain.SizeX div 4, Park.pTerrain.SizeY div 4, GL_RGBA32F);
    fHeightMap.SetFilter(GL_NEAREST, GL_NEAREST);
    fHeightMap.SetClamp(GL_CLAMP, GL_CLAMP);
    fHeightMap.Unbind;
    SetLength(fAvgHeight, Park.pTerrain.SizeX div 128);
    SetLength(fMinHeight, Park.pTerrain.SizeX div 128);
    SetLength(fHeightRanges, Park.pTerrain.SizeX div 128);
    SetLength(fStrongestLights, Park.pTerrain.SizeX div 128);
    SetLength(fBoundingSphereRadius, length(fAvgHeight));
    for i := 0 to high(fAvgHeight) do
      begin
      SetLength(fAvgHeight[i], Park.pTerrain.SizeY div 128);
      SetLength(fMinHeight[i], Park.pTerrain.SizeY div 128);
      SetLength(fHeightRanges[i], Park.pTerrain.SizeY div 128);
      SetLength(fStrongestLights[i], Park.pTerrain.SizeY div 128);
      SetLength(fBoundingSphereRadius[i], length(fAvgHeight[i]));
      end;
    for i := 0 to high(fWaterLayerFBOs) do
      begin
      setLength(fWaterLayerFBOs[i].Blocks, Park.pTerrain.SizeX div 128);
      for j := 0 to high(fWaterLayerFBOs[i].Blocks) do
        setLength(fWaterLayerFBOs[i].Blocks[j], Park.pTerrain.SizeX div 128);
      end;
    StartUpdate;
    if hd then
      begin
      for i := 0 to Park.pTerrain.SizeX - 1 do
        for j := 0 to Park.pTerrain.SizeY - 1 do
          UpdateVertex(I, J);
      end
    else
      for i := 0 to Park.pTerrain.SizeX - 1 do
        for j := 0 to Park.pTerrain.SizeY - 1 do
          UpdateVertexSD(I, J);
    EndUpdate;

    RecreateBorderVBO;

    fCheckWater := true;
    fCheckBBoxes := true;

    fCanWork := true;
    end;
  if (Data <> nil) and ((Event = 'TTerrain.Changed') or (Event = 'TTerrain.ChangedTexmap') or (Event = 'TTerrain.ChangedWater')) then
    begin
    k := Integer(Data^);
    StartUpdate;
    if hd then
      begin
      for i := 0 to k - 1 do
        UpdateVertex(Integer((Data + 2 * sizeof(Integer) * i + sizeof(Integer))^), Integer((Data + 2 * sizeof(Integer) * i + 2 * sizeof(Integer))^));
      end
    else
      for i := 0 to k - 1 do
        UpdateVertexSD(Integer((Data + 2 * sizeof(Integer) * i + sizeof(Integer))^), Integer((Data + 2 * sizeof(Integer) * i + 2 * sizeof(Integer))^));
    EndUpdate;
    for i := 0 to k - 1 do
      CheckWaterLevel(Integer((Data + 2 * sizeof(Integer) * i + sizeof(Integer))^), Integer((Data + 2 * sizeof(Integer) * i + 2 * sizeof(Integer))^));
    if Event <> 'TTerrain.ChangedTexmap' then
      begin
      fCheckBBoxes := Event <> 'TTerrain.ChangedWater';
      fCheckWater := true;
      fCanWork := true;
      end;
    end;
end;

procedure TRTerrain.UpdateCollection(Event: String; Data, Result: Pointer);
var
  i, j: Integer;
begin
  for i := 0 to high(fAPVBOs) do
    if fAPVBOs[i] <> nil then
      fAPVBOs[i].Free;
  for i := 0 to high(fAPVBOs) do
    if Park.pTerrain.Collection.Materials[i].AutoplantProperties.Available then
      begin
      fAPVBOs[i] := TVBO.Create(4 * Round(20000 * Park.pTerrain.Collection.Materials[i].AutoplantProperties.Factor), GL_T2F_V3F, GL_QUADS);
      setLength(fAPPositions[i], Round(20000 * Park.pTerrain.Collection.Materials[i].AutoplantProperties.Factor));
      fAPCount[i] := 0;
      for j := 0 to high(fAPPositions[i]) do
        begin
        fAPPositions[i, j] := Vector(-10000, -10000);
        fAPVBOs[i].TexCoords[4 * j + 0] := Vector(0, 1);
        fAPVBOs[i].TexCoords[4 * j + 1] := Vector(0, 0);
        fAPVBOs[i].TexCoords[4 * j + 2] := Vector(1, 0);
        fAPVBOs[i].TexCoords[4 * j + 3] := Vector(1, 1);
        fAPVBOs[i].Vertices[4 * j + 0] := Vector(0, 0, 0);
        fAPVBOs[i].Vertices[4 * j + 1] := Vector(0, 0, 0);
        fAPVBOs[i].Vertices[4 * j + 2] := Vector(0, 0, 0);
        fAPVBOs[i].Vertices[4 * j + 3] := Vector(0, 0, 0);
        end;
      end
    else
      fAPVBOs[i] := nil;
end;

constructor TRTerrain.Create;
var
  i, j, k, l, cv: Integer;
  tempTex: TTexImage;
  TexFormat, CompressedTexFormat: GLEnum;
begin
  writeln('Initializing terrain renderer');
  inherited Create(false);
  fTerrainEditorIsOpen := false;
  fTerrainMarkOCF := nil;
  ModuleManager.ModOCFManager.RequestOCFFile('terrain/terrainmarks/defaultmark.ocf', 'TOCFManager.Loaded', @fTerrainMarkOCF);
  fForcedHeightLine := -1;
  fFrameCount := 0;
  fWaterVBO := nil;
  fBorderVBO := nil;
  try
    fHeightMap := nil;
    fShader := TShader.Create('rendereropengl/glsl/terrain/terrain.vs', 'rendereropengl/glsl/terrain/terrain.fs');
    fShader.UniformI('TerrainTexture', 0);
    fShader.UniformI('HeightMap', 1);
    fShader.UniformI('SunShadowMap', 7);
    fShader.UniformI('ShadowMap1', 4);
    fShader.UniformI('ShadowMap2', 5);
    fShader.UniformI('ShadowMap3', 6);
    fShader.UniformF('maxBumpDistance', fInterface.Option('terrain:bumpdist', 50));
    fShadowShader := TShader.Create('rendereropengl/glsl/terrain/terrainTransform.vs', 'rendereropengl/glsl/terrain/terrainShdGen.fs');
    fShadowShader.UniformI('HeightMap', 1);
    fShadowShader.UniformI('LOD', 1);
    fWaterShader := TShader.Create('rendereropengl/glsl/terrain/water.vs', 'rendereropengl/glsl/terrain/water.fs');
    fWaterShader.UniformI('HeightMap', 0);
    fWaterShader.UniformI('ReflectionMap', 1);
    fWaterShader.UniformI('RefractionMap', 2);
    fWaterShader.UniformI('BumpMap', 3);
    fWaterShader.UniformI('SunShadowMap', 7);
    fShaderTransformDepth := TShader.Create('rendereropengl/glsl/terrain/terrainTransform.vs', 'rendereropengl/glsl/simple.fs');
    fShaderTransformDepth.UniformI('HeightMap', 1);
    fShaderTransformSunShadow := TShader.Create('rendereropengl/glsl/terrain/terrainSunShadowTransform.vs', 'rendereropengl/glsl/shadows/shdGenSun.fs');
    fShaderTransformSunShadow.UniformI('HeightMap', 1);
    fShaderTransformSunShadow.UniformI('UseTexture', 0);
    fShaderTransformSunShadow.UniformF('MeshColor', 1, 1, 1, 1);
    fWaterShaderTransformDepth := TShader.Create('rendereropengl/glsl/terrain/waterTransform.vs', 'rendereropengl/glsl/terrain/simpleWater.fs');
    fWaterShaderTransformDepth.UniformI('HeightMap', 0);
    fWaterShaderTransformSunShadow := TShader.Create('rendereropengl/glsl/terrain/waterSunShadowTransform.vs', 'rendereropengl/glsl/shadows/shdGenSun.fs');
    fWaterShaderTransformSunShadow.UniformI('HeightMap', 0);
    fAPShader := TShader.Create('rendereropengl/glsl/terrain/autoplant.vs', 'rendereropengl/glsl/terrain/autoplant.fs');
    fAPShader.UniformI('Autoplant', 0);
    fAPShader.UniformI('HeightMap', 1);
    fAPShader.UniformI('SunShadowMap', 7);
    fWaterBumpmap := TTexture.Create;
    tempTex := TexFromTGA(ByteStreamFromFile(fInterface.Option('water:bumpmap', 'terrain/water-bumpmap.tga')));
    TexFormat := GL_RGB;
    CompressedTexFormat := GL_COMPRESSED_RGB;
    if TempTex.BPP = 32 then
      begin
      TexFormat := GL_RGBA;
      CompressedTexFormat := GL_COMPRESSED_RGBA;
      end;
    fWaterBumpmap.CreateNew(Temptex.Width, Temptex.Height, CompressedTexFormat);
    gluBuild2DMipmaps(GL_TEXTURE_2D, TempTex.BPP div 8, Temptex.Width, Temptex.Height, TexFormat, GL_UNSIGNED_BYTE, @TempTex.Data[0]);
    fWaterBumpmap.SetFilter(GL_LINEAR_MIPMAP_LINEAR, GL_LINEAR_MIPMAP_LINEAR);
    fWaterBumpmapOffset := Vector(0, 0);
    fFineOffsetX := 0;
    fFineOffsetY := 0;
    fFineVBO := TVBO.Create((65 * 65 + 3 * 33 * 33) * 4, GL_V3F, GL_QUADS);
    cv := 0;
    for i := 0 to 64 do
      for j := 0 to 64 do
        begin
        fFineVBO.Vertices[cv + 0] := Vector(0.0 + 0.2 * i, 0.0, 0.2 * j + 0.2);
        fFineVBO.Vertices[cv + 1] := Vector(0.2 + 0.2 * i, 0.0, 0.2 * j + 0.2);
        fFineVBO.Vertices[cv + 2] := Vector(0.2 + 0.2 * i, 0.0, 0.2 * j + 0.0);
        fFineVBO.Vertices[cv + 3] := Vector(0.0 + 0.2 * i, 0.0, 0.2 * j + 0.0);
        inc(cv, 4);
        end;
    for k := 0 to 1 do
      for l := 0 to 1 do
        if (k > 0) or (l > 0) then
          begin
          for i := 0 to 32 do
            for j := 0 to 32 do
              begin
              fFineVBO.Vertices[cv + 0] := Vector(12.8 * k + 0.4 * i,       0.0, 12.8 * l + 0.4 * j + 0.4);
              fFineVBO.Vertices[cv + 1] := Vector(12.8 * k + 0.4 * i + 0.4, 0.0, 12.8 * l + 0.4 * j + 0.4);
              fFineVBO.Vertices[cv + 2] := Vector(12.8 * k + 0.4 * i + 0.4, 0.0, 12.8 * l + 0.4 * j);
              fFineVBO.Vertices[cv + 3] := Vector(12.8 * k + 0.4 * i,       0.0, 12.8 * l + 0.4 * j);
              inc(cv, 4);
              end;
          end;
    fFineVBO.Unbind;
    fGoodVBO := TVBO.Create(32 * 32 * 4, GL_V3F, GL_QUADS);
    for i := 0 to 31 do
      for j := 0 to 31 do
        begin
        fGoodVBO.Vertices[4 * (32 * i + j) + 3] := Vector(0.2 * i, 0, 0.2 * j);
        fGoodVBO.Vertices[4 * (32 * i + j) + 2] := Vector(0.2 * i + 0.2, 0, 0.2 * j);
        fGoodVBO.Vertices[4 * (32 * i + j) + 1] := Vector(0.2 * i + 0.2, 0, 0.2 * j + 0.2);
        fGoodVBO.Vertices[4 * (32 * i + j) + 0] := Vector(0.2 * i, 0.0, 0.2 * j + 0.2);
        end;
    fGoodVBO.Unbind;
    fRawVBO := TVBO.Create(16 * 16 * 4, GL_V3F, GL_QUADS);
    for i := 0 to 15 do
      for j := 0 to 15 do
        begin
        fRawVBO.Vertices[4 * (16 * i + j) + 3] := Vector(0.2 * i, 0.0, 0.2 * j);
        fRawVBO.Vertices[4 * (16 * i + j) + 2] := Vector(0.2 * i + 0.2, 0.0, 0.2 * j);
        fRawVBO.Vertices[4 * (16 * i + j) + 1] := Vector(0.2 * i + 0.2, 0, 0.2 * j + 0.2);
        fRawVBO.Vertices[4 * (16 * i + j) + 0] := Vector(0.2 * i, 0.0, 0.2 * j + 0.2);
        end;
    fRawVBO.Unbind;
    for i := 0 to high(fAPVBOs) do
      fAPVBOs[i] := nil;
    EventManager.AddCallback('TTerrain.ApplyForcedHeightLine', @SetHeightLine);
    EventManager.AddCallback('GUIActions.terrain_edit.open', @ChangeTerrainEditorState);
    EventManager.AddCallback('GUIActions.terrain_edit.close', @ChangeTerrainEditorState);
    EventManager.AddCallback('TTerrain.Resize', @ApplyChanges);
    EventManager.AddCallback('TTerrain.Changed', @ApplyChanges);
    EventManager.AddCallback('TTerrain.ChangedTexmap', @ApplyChanges);
    EventManager.AddCallback('TTerrain.ChangedWater', @ApplyChanges);
    EventManager.AddCallback('TTerrain.ChangedCollection', @UpdateCollection);
  except
    ModuleManager.ModLog.AddError('Failed to create terrain renderer in OpenGL rendering module: Internal error');
  end;
  EventManager.AddCallback('TPark.RenderParts', @Render);
end;

procedure TRTerrain.Unload;
var
  i, j: Integer;
begin
  Terminate;
  Sync;
  for i := 0 to high(fAPVBOs) do
    if fAPVBOs[i] <> nil then
      fAPVBOs[i].Free;
  for i := 0 to high(fWaterLayerFBOs) do
    fWaterLayerFBOs[i].Free;
  EventManager.RemoveCallback(@ChangeTerrainEditorState);
  EventManager.RemoveCallback(@SetHeightLine);
  EventManager.RemoveCallback(@ApplyChanges);
  EventManager.RemoveCallback(@UpdateCollection);
  EventManager.RemoveCallback(@Render);
  fFineVBO.Free;
  fGoodVBO.Free;
  fRawVBO.Free;
  fShadowShader.Free;
  fShader.Free;
  fShaderTransformDepth.Free;
  fShaderTransformSunShadow.Free;
  fWaterShader.Free;
  fWaterShaderTransformDepth.Free;
  fWaterShaderTransformSunShadow.Free;
  fWaterBumpmap.Free;
  fAPShader.Free;
  if fBorderVBO <> nil then
    fBorderVBO.Free;
  if fWaterVBO <> nil then
    fWaterVBO.Free;
  if fHeightMap <> nil then
    fHeightMap.Free;
end;

end.