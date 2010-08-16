unit m_renderer_opengl_terrain;

interface

uses
  SysUtils, Classes, DGLOpenGL, m_renderer_opengl_classes, u_vectors, m_shdmng_class, m_texmng_class, u_math, math,
  m_renderer_opengl_interface;

type
  TWaterLayerFBO = class
    public
      Height: Single;
      Query: TOcclusionQuery;
      RefractionFBO, ReflectionFBO: TFBO;
      Blocks: Array of Array of Boolean;
      constructor Create;
      destructor Free;
    end;

  TRTerrain = class
    protected
      fUpdatePlants: Boolean;
      fFineVBO, fGoodVBO, fRawVBO, fWaterVBO: TVBO;
      fAPVBOs: Array[0..7] of TVBO;
      fAPCount: Array[0..7] of Integer;
      fAPPositions: Array[0..7] of Array of TVector2D;
      fShader, fShaderTransformDepth, fShaderTransformSunShadow, fShaderTransformShadow, fAPShader: TShader;
      fWaterShader, fWaterShaderTransformDepth, fWaterShaderTransformSunShadow: TShader;
      fWaterBumpmap: TTexture;
      fWaterBumpmapOffset: TVector2D;
      fBoundingSphereRadius, fAvgHeight: Array of Array of Single;
      fHeightRanges: Array of Array of Array[0..1] of Single;
      fTmpFineOffsetX, fTmpFineOffsetY: Word;
      fFineOffsetX, fFineOffsetY: Word;
      fPrevPos: TVector2D;
      fHeightMap: TFBO;
      fFrameCount: Byte;
      RenderStep: Single;
    public
      fWaterLayerFBOs: Array of TWaterLayerFBO;
      procedure Render(Event: String; Data, Result: Pointer);
      procedure RecreateWaterVBO;
      procedure CheckWaterLayerVisibility;
      procedure RenderWaterSurfaces;
      procedure UpdateCollection(Event: String; Data, Result: Pointer);
      procedure ApplyChanges(Event: String; Data, Result: Pointer);
      constructor Create;
      destructor Free;
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
end;

destructor TWaterLayerFBO.Free;
begin
  RefractionFBO.Free;
  ReflectionFBO.Free;
  Query.Free;
end;


procedure TRTerrain.RecreateWaterVBO;
var
  i, j: Integer;
begin
  if fWaterVBO <> nil then
    fWaterVBO.Free;
  fWaterVBO := TVBO.Create(4 * (Park.pTerrain.SizeX div 128) * (Park.pTerrain.SizeY div 128), GL_V3F, GL_QUADS);
  fWaterVBO.Bind;
  for i := 0 to Park.pTerrain.SizeX div 128 - 1 do
    for j := 0 to Park.pTerrain.SizeY div 128 - 1 do
      begin
      fWaterVBO.Vertices[4 * (Park.pTerrain.SizeX div 128 * j + i) + 0] := Vector(128 * i / 5, 0, 128 * j / 5);
      fWaterVBO.Vertices[4 * (Park.pTerrain.SizeX div 128 * j + i) + 1] := Vector(128 * (i + 1) / 5, 0, 128 * j / 5);
      fWaterVBO.Vertices[4 * (Park.pTerrain.SizeX div 128 * j + i) + 2] := Vector(128 * (i + 1) / 5, 0, 128 * (j + 1) / 5);
      fWaterVBO.Vertices[4 * (Park.pTerrain.SizeX div 128 * j + i) + 3] := Vector(128 * i / 5, 0, 128 * (j + 1) / 5);
      end;
  fWaterVBO.Unbind;
end;

procedure TRTerrain.Render(Event: String; Data, Result: Pointer);
var
  fBoundShader: TShader;

  procedure RenderBlock(X, Y: Integer; Check: Boolean);
  begin
    try
      if (X >= 0) and (Y >= 0) and (X <= Park.pTerrain.SizeX div 128 - 1) and (Y <= Park.pTerrain.SizeY div 128 - 1) then
        if (ModuleManager.ModRenderer.Frustum.IsSphereWithin(12.8 + 25.6 * X, fAvgHeight[X, Y], 12.8 + 25.6 * Y, fBoundingSphereRadius[X, Y])) then
          begin
          if fInterface.Options.Items['water:mode'] = 'refraction' then
            if not fWaterLayerFBOs[StrToIntWD(fInterface.Options.Items['water:currlayer'], 0)].Blocks[X, Y] then
              exit;
          if (fHeightRanges[X, Y, 0] > StrToFloatWD(fInterface.Options.Items['all:below'], 256)) or (fHeightRanges[X, Y, 1] < StrToFloatWD(fInterface.Options.Items['all:above'], 0)) then
            exit;
          fBoundShader.UniformF('VOffset', 128 * x / 5, 128 * y / 5);
          if VecLengthNoRoot(Vector(128 * x / 5, 0, 128 * y / 5) + Vector(12.8, 0.0, 12.8) - ModuleManager.ModCamera.ActiveCamera.Position * Vector(1, 0, 1)) < 13000 then
            begin
            fBoundShader.UniformI('LOD', 1);
            fGoodVBO.Render;
            end
          else
            begin
            fBoundShader.UniformI('LOD', 0);
            fRawVBO.Render;
            end;
          end;
    except
      writeln('Exception: ', X, ' ', Y);
    end;
  end;
var
  i, j, k: integer;
  Blocks: Array of Array[0..2] of Integer;
  fDeg, fRot: Single;
  Position, fTmp: TVector2D;
  X1, X2, Y1, Y2: Float;
const
  AUTOPLANT_UPDATE_FRAMES = 10;
begin
  glDisable(GL_BLEND);
  fFineOffsetX := 4 * Round(Clamp((ModuleManager.ModCamera.ActiveCamera.Position.X) * 5 - 128, 0, Park.pTerrain.SizeX - 256) / 4);
  fFineOffsetY := 4 * Round(Clamp((ModuleManager.ModCamera.ActiveCamera.Position.Z) * 5 - 128, 0, Park.pTerrain.SizeY - 256) / 4);
  fHeightMap.Textures[0].Bind(1);
  Park.pTerrain.Collection.Texture.Bind(0);
  fBoundShader := fShader;
  if fInterface.Options.Items['shader:mode'] = 'transform:depth' then
    fBoundShader := fShaderTransformDepth
  else if fInterface.Options.Items['shader:mode'] = 'sunshadow:sunshadow' then
    fBoundShader := fShaderTransformSunShadow
  else
    begin
    if (Park.pTerrain.CurrMark.X >= 0) and (Park.pTerrain.CurrMark.Y >= 0) and (Park.pTerrain.CurrMark.X <= 0.2 * Park.pTerrain.SizeX) and (Park.pTerrain.CurrMark.Y <= 0.2 * Park.pTerrain.SizeY) then
      fBoundShader.UniformF('PointToHighlight', Park.pTerrain.CurrMark.X, Park.pTerrain.CurrMark.Y)
    else
      fBoundShader.UniformF('PointToHighlight', -1, -1);
    end;
  fBoundShader.Bind;
  if fInterface.Options.Items['terrain:hd'] <> 'off' then
    fBoundShader.UniformF('offset', fFineOffsetX / 5, fFineOffsetY / 5)
  else
    fBoundShader.UniformF('offset', -10000, -10000);
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
  for i := 0 to high(Blocks) do
    RenderBlock(Blocks[i, 1], Blocks[i, 2], fBoundShader = fShaderTransformDepth);
  if fInterface.Options.Items['terrain:hd'] <> 'off' then
    begin
    fBoundShader.UniformI('LOD', 2);
    fBoundShader.UniformF('VOffset', fFineOffsetX / 5, fFineOffsetY / 5);
    fFineVBO.Bind;
    fFineVBO.Render;
    fFineVBO.Unbind;
    end;
  fBoundShader.Unbind;
  Park.pTerrain.Collection.Texture.UnBind;

  if fInterface.Options.Items['all:renderpass'] = '0' then
    fUpdatePlants := true;

  // Render autoplants
  if fInterface.Options.Items['terrain:autoplants'] <> 'off' then
    begin
    glDisable(GL_CULL_FACE);
    glColor4f(1, 1, 1, 1);
    glEnable(GL_BLEND);
    glEnable(GL_ALPHA_TEST);
    glAlphaFunc(GL_GREATER, 0.2);
    fAPShader.Bind;
    if fUpdatePlants then
      begin
      inc(fFrameCount);
      if fFrameCount = AUTOPLANT_UPDATE_FRAMES then
        fFrameCount := 0;
      end;
    for i := 0 to high(fAPVBOs) do
      if fAPVBOs[i] <> nil then
        begin
        Park.pTerrain.Collection.Materials[i].AutoplantProperties.Texture.Bind(0);
        if fUpdatePlants then
          begin
          fUpdatePlants := false;
          fAPVBOs[i].Bind;
          for j := 0 to high(fAPPositions[i]) * fFrameCount div AUTOPLANT_UPDATE_FRAMES do
            begin
            if VecLengthNoRoot(fAPPositions[i, j] - Vector(ModuleManager.ModCamera.ActiveCamera.Position.X, ModuleManager.ModCamera.ActiveCamera.Position.Z)) > 400 then
              begin
              fDeg := PI * 2 * Random;
              fRot := PI * 2 * Random;
              fTMP := Vector(Sin(fRot), Cos(fRot)) * 0.4;
              Position := Vector(ModuleManager.ModCamera.ActiveCamera.Position.X, ModuleManager.ModCamera.ActiveCamera.Position.Z) + Vector(Sin(fDeg), Cos(fDeg)) * (2 * Random + 18);
              fAPPositions[i, j] := Position;
              inc(fAPCount[i]);
              if Park.pTerrain.TexMap[Position.X, Position.Y] = i then
                begin
                fAPVBOs[i].Vertices[4 * j + 0] := Vector(fAPPositions[i, j].X, 0, fAPPositions[i, j].Y);
                fAPVBOs[i].Vertices[4 * j + 1] := Vector(fAPPositions[i, j].X, 0.2, fAPPositions[i, j].Y);
                fAPVBOs[i].Vertices[4 * j + 2] := Vector(fAPPositions[i, j].X + fTMP.X, 0.2, fAPPositions[i, j].Y + fTMP.Y);
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
    end;
  glUseProgram(0);

  // Render marks - WILL BE REPLACED
  glDisable(GL_TEXTURE_2D);
  glDisable(GL_CULL_FACE);

  glBegin(GL_QUADS);
    glColor4f(1, 1, 1, 1);
    for i := 0 to Park.pTerrain.Marks.Height - 1 do
      begin
      glVertex3f(0.2 * Park.pTerrain.Marks.Value[0, i] - 0.1, 0.1 + Park.pTerrain.HeightMap[0.2 * Park.pTerrain.Marks.Value[0, i], 0.2 * Park.pTerrain.Marks.Value[1, i]], 0.2 * Park.pTerrain.Marks.Value[1, i] - 0.1);
      glVertex3f(0.2 * Park.pTerrain.Marks.Value[0, i] + 0.1, 0.1 + Park.pTerrain.HeightMap[0.2 * Park.pTerrain.Marks.Value[0, i], 0.2 * Park.pTerrain.Marks.Value[1, i]], 0.2 * Park.pTerrain.Marks.Value[1, i] - 0.1);
      glVertex3f(0.2 * Park.pTerrain.Marks.Value[0, i] + 0.1, 0.1 + Park.pTerrain.HeightMap[0.2 * Park.pTerrain.Marks.Value[0, i], 0.2 * Park.pTerrain.Marks.Value[1, i]], 0.2 * Park.pTerrain.Marks.Value[1, i] + 0.1);
      glVertex3f(0.2 * Park.pTerrain.Marks.Value[0, i] - 0.1, 0.1 + Park.pTerrain.HeightMap[0.2 * Park.pTerrain.Marks.Value[0, i], 0.2 * Park.pTerrain.Marks.Value[1, i]], 0.2 * Park.pTerrain.Marks.Value[1, i] + 0.1);
      end;
    if (Park.pTerrain.CurrMark.X >= 0) and (Park.pTerrain.CurrMark.Y >= 0) and (Park.pTerrain.CurrMark.X <= 0.2 * Park.pTerrain.SizeX) and (Park.pTerrain.CurrMark.Y <= 0.2 * Park.pTerrain.SizeY) then
      begin
      glColor4f(1, 0, 0, 1.0);
      glVertex3f(Park.pTerrain.CurrMark.X - 0.1, 0.1 + Park.pTerrain.HeightMap[Park.pTerrain.CurrMark.X, Park.pTerrain.CurrMark.Y], Park.pTerrain.CurrMark.Y - 0.1);
      glVertex3f(Park.pTerrain.CurrMark.X + 0.1, 0.1 + Park.pTerrain.HeightMap[Park.pTerrain.CurrMark.X, Park.pTerrain.CurrMark.Y], Park.pTerrain.CurrMark.Y - 0.1);
      glVertex3f(Park.pTerrain.CurrMark.X + 0.1, 0.1 + Park.pTerrain.HeightMap[Park.pTerrain.CurrMark.X, Park.pTerrain.CurrMark.Y], Park.pTerrain.CurrMark.Y + 0.1);
      glVertex3f(Park.pTerrain.CurrMark.X - 0.1, 0.1 + Park.pTerrain.HeightMap[Park.pTerrain.CurrMark.X, Park.pTerrain.CurrMark.Y], Park.pTerrain.CurrMark.Y + 0.1);
      end;
  glEnd;

  glBegin(GL_LINE_LOOP);
    glColor4f(1, 1, 1, 1);
    for i := 0 to Park.pTerrain.Marks.Height - 1 do
      begin
      glVertex3f(0.2 * Park.pTerrain.Marks.Value[0, i], 0.1 + Park.pTerrain.HeightMap[0.2 * Park.pTerrain.Marks.Value[0, i], 0.2 * Park.pTerrain.Marks.Value[1, i]], 0.2 * Park.pTerrain.Marks.Value[1, i]);
      end;
    if (Park.pTerrain.CurrMark.X >= 0) and (Park.pTerrain.CurrMark.Y >= 0) and (Park.pTerrain.CurrMark.X <= 0.2 * Park.pTerrain.SizeX) and (Park.pTerrain.CurrMark.Y <= 0.2 * Park.pTerrain.SizeY) then
      glVertex3f(Park.pTerrain.CurrMark.X, 0.1 + Park.pTerrain.HeightMap[Park.pTerrain.CurrMark.X, Park.pTerrain.CurrMark.Y], Park.pTerrain.CurrMark.Y);
  glEnd;

  glEnable(GL_TEXTURE_2D);
end;

procedure TRTerrain.CheckWaterLayerVisibility;
var
  i: Integer;
begin
  glDisable(GL_CULL_FACE);
  fWaterShaderTransformDepth.Bind;
  fHeightMap.Textures[0].Bind(0);
  for i := 0 to high(fWaterLayerFBOs) do
    begin
    glTexCoord3f(0, 0, fWaterLayerFBOs[i].Height);
    fWaterLayerFBOs[i].Query.StartCounter;
    glBegin(GL_QUADS);
      glVertex3f(0, 0, 0);
      glVertex3f(Park.pTerrain.SizeX / 5, 0, 0);
      glVertex3f(Park.pTerrain.SizeX / 5, 0, Park.pTerrain.SizeY / 5);
      glVertex3f(0, 0, Park.pTerrain.SizeY / 5);
    glEnd;
    fWaterLayerFBOs[i].Query.EndCounter;
    end;
  fHeightMap.Textures[0].Unbind;
  fWaterShaderTransformDepth.Unbind;
  glEnable(GL_CULL_FACE);
end;

procedure TRTerrain.RenderWaterSurfaces;
var
  i, j, k: Integer;
  fBoundShader: TShader;
begin
  glDisable(GL_BLEND);
  glDisable(GL_CULL_FACE);

  fBoundShader := fWaterShader;
  if fInterface.Options.Items['shader:mode'] = 'transform:depth' then
    fBoundShader := fWaterShaderTransformDepth
  else if fInterface.Options.Items['shader:mode'] = 'sunshadow:sunshadow' then
    fBoundShader := fWaterShaderTransformSunShadow;
  fBoundShader.Bind;

  fWaterBumpmapOffset := fWaterBumpmapOffset - Vector(0.00002, 0.00010) * FPSDisplay.MS;

  for k := 0 to high(fWaterLayerFBOs) do
    begin
    if fWaterLayerFBOs[k].Query.Result = 0 then
      continue;
    fWaterLayerFBOs[k].ReflectionFBO.Textures[0].Bind(1);
    fWaterLayerFBOs[k].RefractionFBO.Textures[0].Bind(2);
    fWaterBumpmap.Bind(3);
    fHeightMap.Textures[0].Bind(0);
    glTexCoord3f(fWaterBumpmapOffset.X, fWaterBumpmapOffset.Y, fWaterLayerFBOs[k].Height);
    fWaterVBO.Bind;
    fWaterVBO.Render;
    fWaterVBO.Unbind;
    end;

  fBoundShader.Unbind;

  glEnable(GL_CULL_FACE);
end;

procedure TRTerrain.ApplyChanges(Event: String; Data, Result: Pointer);
var
  i, j, k, l: Integer;
  Pixel: TVector4D;
  procedure StartUpdate;
  begin
{    glUseProgram(0);
    glBindTexture(GL_TEXTURE_2D, 0);
    fHeightMap.Bind;
    glClear(GL_COLOR_BUFFER_BIT);
    glMatrixMode(GL_PROJECTION);
    glDisable(GL_BLEND);
    glDisable(GL_ALPHA_TEST);
    glPushMatrix;
    glLoadIdentity;
    glOrtho(0, Park.pTerrain.SizeX, 0, Park.pTerrain.SizeY, 0, 255);
    glMatrixMode(GL_MODELVIEW);
    glPushMatrix;
    glLoadIdentity;

    glDisable(GL_DEPTH_TEST);}
    fHeightMap.Textures[0].Bind(0);
  end;

  procedure UpdateVertex(X, Y: Word);
  begin
    Pixel := Vector(Park.pTerrain.TexMap[X / 5, Y / 5] / 8, Park.pTerrain.WaterMap[X / 5, Y / 5] / 256, 0.0, Park.pTerrain.HeightMap[X / 5, Y / 5] / 256);
    glTexSubImage2D(GL_TEXTURE_2D, 0, X, Y, 1, 1, GL_RGBA, GL_FLOAT, @Pixel.X);
  end;

  procedure CheckWaterLevel(X, Y: Word);
  var
    i: integer;
  begin
    if Park.pTerrain.WaterMap[X / 5, Y / 5] = 0 then
      exit;
    for i := 0 to high(fWaterLayerFBOs) do
      if fWaterLayerFBOs[i].Height = Park.pTerrain.WaterMap[X / 5, Y / 5] then
        exit;
    setLength(fWaterLayerFBOs, length(fWaterLayerFBOs) + 1);
    fWaterLayerFBOs[high(fWaterLayerFBOs)] := TWaterLayerFBO.Create;
    fWaterLayerFBOs[high(fWaterLayerFBOs)].Height := Park.pTerrain.WaterMap[X / 5, Y / 5];
  end;

  procedure EndUpdate;
  begin
    fHeightMap.Textures[0].Unbind;
{    glEnable(GL_DEPTH_TEST);
    glEnable(GL_ALPHA_TEST);
    glPopMatrix;
    glMatrixMode(GL_PROJECTION);
    glPopMatrix;
    glMatrixMode(GL_MODELVIEW);
    fHeightMap.Unbind;}
  end;

  procedure RecalcBoundingSpheres(X, Y: Integer);
  var
    i, j, k: Integer;
    avgh, temp, temp2: Single;
    a, b, c, d: Single;
  begin
    avgh := 0;
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

        end;
    avgh := avgh / 129 / 129;
    fAvgHeight[X, Y] := avgh;
    fBoundingSphereRadius[X, Y] := VecLength(Vector(12.8, Max(Max(a, b), Max(c, d)) - avgh, 12.8));
  end;
begin
  if Event = 'TTerrain.Resize' then
    begin
    RecreateWaterVBO;
    fShader.UniformF('TerrainSize', Park.pTerrain.SizeX, Park.pTerrain.SizeY);
    fShaderTransformDepth.UniformF('TerrainSize', Park.pTerrain.SizeX, Park.pTerrain.SizeY);
    fShaderTransformSunShadow.UniformF('TerrainSize', Park.pTerrain.SizeX, Park.pTerrain.SizeY);
    fWaterShader.UniformF('TerrainSize', Park.pTerrain.SizeX, Park.pTerrain.SizeY);
    fWaterShaderTransformDepth.UniformF('TerrainSize', Park.pTerrain.SizeX, Park.pTerrain.SizeY);
    fWaterShaderTransformSunShadow.UniformF('TerrainSize', Park.pTerrain.SizeX, Park.pTerrain.SizeY);
    fAPShader.UniformF('TerrainSize', Park.pTerrain.SizeX, Park.pTerrain.SizeY);
    if fHeightMap <> nil then
      fHeightMap.Free;
    fHeightMap := TFBO.Create(Park.pTerrain.SizeX, Park.pTerrain.SizeY, true);
    fHeightMap.AddTexture(GL_RGBA16F, GL_NEAREST, GL_NEAREST);
    fHeightMap.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);
    fHeightMap.Unbind;
    SetLength(fAvgHeight, Park.pTerrain.SizeX div 128);
    SetLength(fHeightRanges, Park.pTerrain.SizeX div 128);
    SetLength(fBoundingSphereRadius, length(fAvgHeight));
    for i := 0 to high(fAvgHeight) do
      begin
      SetLength(fAvgHeight[i], Park.pTerrain.SizeY div 128);
      SetLength(fHeightRanges[i], Park.pTerrain.SizeY div 128);
      SetLength(fBoundingSphereRadius[i], length(fAvgHeight[i]));
      end;
    for i := 0 to high(fWaterLayerFBOs) do
      begin
      setLength(fWaterLayerFBOs[i].Blocks, Park.pTerrain.SizeX div 128);
      for j := 0 to high(fWaterLayerFBOs[i].Blocks) do
        setLength(fWaterLayerFBOs[i].Blocks[j], Park.pTerrain.SizeX div 128);
      end;
    for i := 0 to Park.pTerrain.SizeX div 128 - 1 do
      for j := 0 to Park.pTerrain.SizeY div 128 - 1 do
        RecalcBoundingSpheres(i, j);
    end;
  if (Data <> nil) and ((Event = 'TTerrain.Changed') or (Event = 'TTerrain.ChangedTexmap')) then
    begin
    k := Integer(Data^);
    StartUpdate;
    for i := 0 to k - 1 do
      UpdateVertex(Integer((Data + 8 * i + 4)^), Integer((Data + 8 * i + 8)^));
    EndUpdate;
    if Event <> 'TTerrain.ChangedTexmap' then
      begin
      for i := 0 to Park.pTerrain.SizeX do
        for j := 0 to Park.pTerrain.SizeY do
          CheckWaterLevel(i, j);
      for i := 0 to Park.pTerrain.SizeX div 128 - 1 do
        for j := 0 to Park.pTerrain.SizeY div 128 - 1 do
          RecalcBoundingSpheres(i, j);
      end;
    end;
  if (Event = 'TTerrain.ChangedAll') then
    begin
    writeln('Copying entire terrain to VRam');
    StartUpdate;
    for i := 0 to Park.pTerrain.SizeX do
      for j := 0 to Park.pTerrain.SizeY do
        UpdateVertex(i, j);
    EndUpdate;
    for i := 0 to Park.pTerrain.SizeX do
      for j := 0 to Park.pTerrain.SizeY do
        CheckWaterLevel(i, j);
    for i := 0 to Park.pTerrain.SizeX div 128 - 1 do
      for j := 0 to Park.pTerrain.SizeY div 128 - 1 do
        RecalcBoundingSpheres(i, j);
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
  fFrameCount := 0;
  fWaterVBO := nil;
  try
    writeln('Initializing terrain renderer');
    fHeightMap := nil;
    fShader := TShader.Create('rendereropengl/glsl/terrain/terrain.vs', 'rendereropengl/glsl/terrain/terrain.fs');
    fShader.UniformI('TerrainTexture', 0);
    fShader.UniformI('HeightMap', 1);
    fShader.UniformI('SunShadowMap', 7);
    fShader.UniformF('maxBumpDistance', fInterface.Option('terrain:bumpdist', 60));
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
    fFineVBO := TVBO.Create(130 * 130 * 4 + 8 * 32 * 32 * 4, GL_V3F, GL_QUADS);
    cv := 0;
    for i := -1 to 128 do
      for j := -1 to 128 do
        begin
        fFineVBO.Vertices[cv + 0] := Vector(12.8 + 0.2 * i, 1.0, 0.2 * j + 13.0);
        fFineVBO.Vertices[cv + 1] := Vector(13.0 + 0.2 * i, 1.1, 0.2 * j + 13.0);
        fFineVBO.Vertices[cv + 2] := Vector(13.0 + 0.2 * i, 0.1, 0.2 * j + 12.8);
        fFineVBO.Vertices[cv + 3] := Vector(12.8 + 0.2 * i, 0.0, 0.2 * j + 12.8);
        inc(cv, 4);
        end;
    for k := 0 to 3 do
      for l := 0 to 3 do
        if (k = 0) or (k = 3) or (l = 3) or (l = 0) then
          begin
          for i := 0 to 31 do
            for j := 0 to 31 do
              begin
              fFineVBO.Vertices[cv + 0] := Vector(12.8 * k + 0.4 * i,       1.0, 12.8 * l + 0.4 * j + 0.4);
              fFineVBO.Vertices[cv + 1] := Vector(12.8 * k + 0.4 * i + 0.4, 1.1, 12.8 * l + 0.4 * j + 0.4);
              fFineVBO.Vertices[cv + 2] := Vector(12.8 * k + 0.4 * i + 0.4, 0.1, 12.8 * l + 0.4 * j);
              fFineVBO.Vertices[cv + 3] := Vector(12.8 * k + 0.4 * i,       0.0, 12.8 * l + 0.4 * j);
              inc(cv, 4);
              end;
          end;
    fFineVBO.Unbind;
    fGoodVBO := TVBO.Create(32 * 32 * 4, GL_V3F, GL_QUADS);
    for i := 0 to 31 do
      for j := 0 to 31 do
        begin
        fGoodVBO.Vertices[4 * (32 * i + j) + 3] := Vector(0.2 * i, 0.0, 0.2 * j);
        fGoodVBO.Vertices[4 * (32 * i + j) + 2] := Vector(0.2 * i + 0.2, 0.1, 0.2 * j);
        fGoodVBO.Vertices[4 * (32 * i + j) + 1] := Vector(0.2 * i + 0.2, 1.1, 0.2 * j + 0.2);
        fGoodVBO.Vertices[4 * (32 * i + j) + 0] := Vector(0.2 * i, 1.0, 0.2 * j + 0.2);
        end;
    fGoodVBO.Unbind;
    fRawVBO := TVBO.Create(8 * 8 * 4, GL_V3F, GL_QUADS);
    for i := 0 to 7 do
      for j := 0 to 7 do
        begin
        fRawVBO.Vertices[4 * (8 * i + j) + 3] := Vector(0.2 * i, 0.0, 0.2 * j);
        fRawVBO.Vertices[4 * (8 * i + j) + 2] := Vector(0.2 * i + 0.2, 0.1, 0.2 * j);
        fRawVBO.Vertices[4 * (8 * i + j) + 1] := Vector(0.2 * i + 0.2, 1.1, 0.2 * j + 0.2);
        fRawVBO.Vertices[4 * (8 * i + j) + 0] := Vector(0.2 * i, 1.0, 0.2 * j + 0.2);
        end;
    fRawVBO.Unbind;
    for i := 0 to high(fAPVBOs) do
      fAPVBOs[i] := nil;
    EventManager.AddCallback('TTerrain.Resize', @ApplyChanges);
    EventManager.AddCallback('TTerrain.Changed', @ApplyChanges);
    EventManager.AddCallback('TTerrain.ChangedTexmap', @ApplyChanges);
    EventManager.AddCallback('TTerrain.ChangedAll', @ApplyChanges);
    EventManager.AddCallback('TTerrain.ChangedCollection', @UpdateCollection);
  except
    ModuleManager.ModLog.AddError('Failed to create terrain renderer in OpenGL rendering module: Internal error');
  end;
  EventManager.AddCallback('TPark.RenderParts', @Render);
end;

destructor TRTerrain.Free;
var
  i, j: Integer;
begin
  for i := 0 to high(fAPVBOs) do
    if fAPVBOs[i] <> nil then
      fAPVBOs[i].Free;
  for i := 0 to high(fWaterLayerFBOs) do
    fWaterLayerFBOs[i].Free;
  EventManager.RemoveCallback(@ApplyChanges);
  EventManager.RemoveCallback(@UpdateCollection);
  EventManager.RemoveCallback(@Render);
  fFineVBO.Free;
  fGoodVBO.Free;
  fRawVBO.Free;
  fShader.Free;
  fShaderTransformDepth.Free;
  fShaderTransformSunShadow.Free;
  fWaterShader.Free;
  fWaterShaderTransformDepth.Free;
  fWaterShaderTransformSunShadow.Free;
  fWaterBumpmap.Free;
  fAPShader.Free;
  if fWaterVBO <> nil then
    fWaterVBO.Free;
  if fHeightMap <> nil then
    fHeightMap.Free;
end;

end.