unit m_renderer_opengl_terrain;

interface

uses
  SysUtils, Classes, DGLOpenGL, m_renderer_opengl_classes, u_vectors, m_shdmng_class, m_texmng_class, u_math, math,
  m_renderer_opengl_interface;

type
  TRTerrain = class
    protected
      fFineVBO, fGoodVBO, fRawVBO: TVBO;
      fAPVBOs: Array[0..7] of TVBO;
      fAPCount: Array[0..7] of Integer;
      fAPPositions: Array[0..7] of Array of TVector2D;
      fShader, fShaderTransformDepth, fShaderTransformSunShadow, fShaderTransformShadow, fAPShader: TShader;
      fBoundingSphereRadius, fAvgHeight: Array of Array of Single;
      fTmpFineOffsetX, fTmpFineOffsetY: Word;
      fFineOffsetX, fFineOffsetY: Word;
      fPrevPos: TVector2D;
      fHeightMap: TFBO;
      fFrameCount: Byte;
      RenderStep: Single;
    public
      procedure Render;
      procedure UpdateCollection(Event: String; Data, Result: Pointer);
      procedure ApplyChanges(Event: String; Data, Result: Pointer);
      constructor Create;
      destructor Free;
    end;

implementation

uses
  g_park, u_events, m_varlist, u_files, u_graphics;

procedure TRTerrain.Render;
var
  fBoundShader: TShader;

  procedure RenderBlock(X, Y: Integer);
  begin
    try
      if (X >= 0) and (Y >= 0) and (X <= Park.pTerrain.SizeX div 256 - 1) and (Y <= Park.pTerrain.SizeY div 256 - 1) then
        if (ModuleManager.ModRenderer.Frustum.IsSphereWithin(25.6 + 51.2 * X, fAvgHeight[X, Y], 25.6 + 51.2 * Y, fBoundingSphereRadius[X, Y])) then
          begin
          fBoundShader.UniformF('VOffset', 256 * x / 5, 256 * y / 5);
          if VecLengthNoRoot(Vector(256 * x / 5, 0, 256 * y / 5) + Vector(25.6, 0.0, 25.6) - ModuleManager.ModCamera.ActiveCamera.Position * Vector(1, 0, 1)) < 13000 then
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
    fBoundShader := fShaderTransformSunShadow;
  fBoundShader.Bind;
  if fInterface.Options.Items['terrain:hd'] <> 'off' then
    fBoundShader.UniformF('offset', fFineOffsetX / 5, fFineOffsetY / 5)
  else
    fBoundShader.UniformF('offset', -10000, -10000);
  setLength(Blocks, Park.pTerrain.SizeX div 256 * Park.pTerrain.SizeY div 256);
  for i := 0 to Park.pTerrain.SizeX div 256 - 1 do
    for j := 0 to Park.pTerrain.SizeY div 256 - 1 do
      begin
      Blocks[Park.pTerrain.SizeY div 256 * i + j, 0] := Round(VecLengthNoRoot(Vector(256 * I / 5, 0, 256 * J / 5) + Vector(25.6, 0.0, 25.6) - ModuleManager.ModCamera.ActiveCamera.Position * Vector(1, 0, 1)));
      Blocks[Park.pTerrain.SizeY div 256 * i + j, 1] := i;
      Blocks[Park.pTerrain.SizeY div 256 * i + j, 2] := j;
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
    RenderBlock(Blocks[i, 1], Blocks[i, 2]);
  if fInterface.Options.Items['terrain:hd'] <> 'off' then
    begin
    fBoundShader.UniformI('LOD', 2);
    fBoundShader.UniformF('VOffset', fFineOffsetX / 5, fFineOffsetY / 5);
    fFineVBO.Bind;
    fFineVBO.Render;
    fFineVBO.Unbind;
    fBoundShader.Unbind;
    end;
  Park.pTerrain.Collection.Texture.UnBind;

  // Render autoplants
  if fInterface.Options.Items['terrain:autoplants'] <> 'off' then
    begin
    glDisable(GL_CULL_FACE);
    glColor4f(1, 1, 1, 1);
    glEnable(GL_BLEND);
    glEnable(GL_ALPHA_TEST);
    glAlphaFunc(GL_GREATER, 0.2);
    fAPShader.Bind;
    if fInterface.Options.Items['all:renderpass'] = '0' then
      begin
      inc(fFrameCount);
      if fFrameCount = AUTOPLANT_UPDATE_FRAMES then
        fFrameCount := 0;
      end;
    for i := 0 to high(fAPVBOs) do
      if fAPVBOs[i] <> nil then
        begin
        Park.pTerrain.Collection.Materials[i].AutoplantProperties.Texture.Bind(0);
        if (fInterface.Options.Items['all:renderpass'] = '0') then
          begin
          fAPVBOs[i].Bind;
          for j := 0 to high(fAPPositions[i]) * fFrameCount div AUTOPLANT_UPDATE_FRAMES do
            begin
            if VecLengthNoRoot(fAPPositions[i, j] - Vector(ModuleManager.ModCamera.ActiveCamera.Position.X, ModuleManager.ModCamera.ActiveCamera.Position.Z)) > 900 then
              begin
              fDeg := PI * 2 * Random;
              fRot := PI * 2 * Random;
              fTMP := Vector(Sin(fRot), Cos(fRot)) * 0.4;
              Position := Vector(ModuleManager.ModCamera.ActiveCamera.Position.X, ModuleManager.ModCamera.ActiveCamera.Position.Z) + Vector(Sin(fDeg), Cos(fDeg)) * (5 * Random + 25);
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
end;

procedure TRTerrain.ApplyChanges(Event: String; Data, Result: Pointer);
var
  i, j: Integer;
  procedure StartUpdate;
  begin
    glUseProgram(0);
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

    glDisable(GL_DEPTH_TEST);
    glBegin(GL_POINTS);
  end;

  procedure UpdateVertex(X, Y: Word);
  begin
    glColor4f(Park.pTerrain.TexMap[X / 5, Y / 5] / 8, 0.0, 0.0, Park.pTerrain.HeightMap[X / 5, Y / 5] / 256);
    glVertex3f(X, Y, -1);
  end;

  procedure EndUpdate;
  begin
    glEnd;
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_ALPHA_TEST);
    glPopMatrix;
    glMatrixMode(GL_PROJECTION);
    glPopMatrix;
    glMatrixMode(GL_MODELVIEW);
    fHeightMap.Unbind;
  end;

  procedure RecalcBoundingSpheres(X, Y: Integer);
  var
    i, j: Integer;
    avgh, temp: Single;
    a, b, c, d: Single;
  begin
    avgh := 0;
    for i := 0 to 255 do
      for j := 0 to 255 do
        begin
        temp := Park.pTerrain.HeightMap[51.2 * X + 0.2 * i, 51.2 * Y + 0.2 * j];
        if (i = 0) and (j = 0) then
          a := temp
        else if (i = 255) and (j = 0) then
          b := temp
        else if (i = 0) and (j = 255) then
          c := temp
        else if (i = 255) and (j = 255) then
          d := temp;
        avgh := avgh + temp;
        end;
    avgh := avgh / 256 / 256;
    fAvgHeight[X, Y] := avgh;
    fBoundingSphereRadius[X, Y] := VecLength(Vector(25.6, Max(Max(a, b), Max(c, d)) - avgh, 25.6));
  end;
begin
  if Event = 'TTerrain.Resize' then
    begin
    fShader.UniformF('TerrainSize', Park.pTerrain.SizeX, Park.pTerrain.SizeY);
    fShaderTransformDepth.UniformF('TerrainSize', Park.pTerrain.SizeX, Park.pTerrain.SizeY);
    fShaderTransformSunShadow.UniformF('TerrainSize', Park.pTerrain.SizeX, Park.pTerrain.SizeY);
    fAPShader.UniformF('TerrainSize', Park.pTerrain.SizeX, Park.pTerrain.SizeY);
    if fHeightMap <> nil then
      fHeightMap.Free;
    fHeightMap := TFBO.Create(Park.pTerrain.SizeX, Park.pTerrain.SizeY, true);
    fHeightMap.AddTexture(GL_RGBA16F, GL_NEAREST, GL_NEAREST);
    fHeightMap.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);
    fHeightMap.Unbind;
    SetLength(fAvgHeight, Park.pTerrain.SizeX div 256);
    SetLength(fBoundingSphereRadius, length(fAvgHeight));
    for i := 0 to high(fAvgHeight) do
      begin
      SetLength(fAvgHeight[i], Park.pTerrain.SizeY div 256);
      SetLength(fBoundingSphereRadius[i], length(fAvgHeight[i]));
      end;
    end;
  if (Data <> nil) and (Event = 'TTerrain.Changed') then
    begin
    i := Word(Data^);
    j := Word(Pointer(PtrUInt(Data) + 2)^);
    StartUpdate;
    UpdateVertex(i, j);
    EndUpdate;
    end;
  if (Event = 'TTerrain.ChangedAll') then
    begin
    writeln('Copying entire terrain to VRam');
    StartUpdate;
    for i := 0 to Park.pTerrain.SizeX do
      for j := 0 to Park.pTerrain.SizeY do
        UpdateVertex(i, j);
    EndUpdate;
    end;
  for i := 0 to Park.pTerrain.SizeX div 256 - 1 do
    for j := 0 to Park.pTerrain.SizeY div 256 - 1 do
      RecalcBoundingSpheres(i, j);
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
      fAPVBOs[i] := TVBO.Create(4 * Round(50000 * Park.pTerrain.Collection.Materials[i].AutoplantProperties.Factor), GL_T2F_V3F, GL_QUADS);
      setLength(fAPPositions[i], Round(50000 * Park.pTerrain.Collection.Materials[i].AutoplantProperties.Factor));
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
  i, j: Integer;
begin
  fFrameCount := 0;
  try
    writeln('Initializing terrain renderer');
    fHeightMap := nil;
    fShader := TShader.Create('rendereropengl/glsl/terrain/terrain.vs', 'rendereropengl/glsl/terrain/terrain.fs');
    fShader.UniformI('TerrainTexture', 0);
    fShader.UniformI('HeightMap', 1);
    fShader.UniformI('SunShadowMap', 7);
    fShader.UniformF('maxBumpDistance', fInterface.Option('terrain:bumpdist', 80));
    fShader.UniformF('lightdir', -1, 1, -1);
    fShaderTransformDepth := TShader.Create('rendereropengl/glsl/terrain/terrainTransform.vs', 'rendereropengl/glsl/simple.fs');
    fShaderTransformDepth.UniformI('HeightMap', 1);
    fShaderTransformSunShadow := TShader.Create('rendereropengl/glsl/terrain/terrainSunShadowTransform.vs', 'rendereropengl/glsl/shadows/shdGenSun.fs');
    fShaderTransformSunShadow.UniformI('HeightMap', 1);
    fAPShader := TShader.Create('rendereropengl/glsl/terrain/autoplant.vs', 'rendereropengl/glsl/terrain/autoplant.fs');
    fAPShader.UniformI('Autoplant', 0);
    fAPShader.UniformI('HeightMap', 1);
    fAPShader.UniformI('SunShadowMap', 7);
    fAPShader.UniformF('lightdir', -1, 1, -1);
    fFineOffsetX := 0;
    fFineOffsetY := 0;
    fFineVBO := TVBO.Create(256 * 256 * 4, GL_V3F, GL_QUADS);
    for i := 0 to 255 do
      for j := 0 to 255 do
        begin
        fFineVBO.Vertices[4 * (256 * i + j) + 3] := Vector(0.2 * i, 0.0, 0.2 * j);
        fFineVBO.Vertices[4 * (256 * i + j) + 2] := Vector(0.2 * i + 0.2, 0.1, 0.2 * j);
        fFineVBO.Vertices[4 * (256 * i + j) + 1] := Vector(0.2 * i + 0.2, 1.1, 0.2 * j + 0.2);
        fFineVBO.Vertices[4 * (256 * i + j) + 0] := Vector(0.2 * i, 1.0, 0.2 * j + 0.2);
        end;
    fFineVBO.Unbind;
    fGoodVBO := TVBO.Create(64 * 64 * 4, GL_V3F, GL_QUADS);
    for i := 0 to 63 do
      for j := 0 to 63 do
        begin
        fGoodVBO.Vertices[4 * (64 * i + j) + 3] := Vector(0.2 * i, 0.0, 0.2 * j);
        fGoodVBO.Vertices[4 * (64 * i + j) + 2] := Vector(0.2 * i + 0.2, 0.1, 0.2 * j);
        fGoodVBO.Vertices[4 * (64 * i + j) + 1] := Vector(0.2 * i + 0.2, 1.1, 0.2 * j + 0.2);
        fGoodVBO.Vertices[4 * (64 * i + j) + 0] := Vector(0.2 * i, 1.0, 0.2 * j + 0.2);
        end;
    fGoodVBO.Unbind;
    fRawVBO := TVBO.Create(16 * 16 * 4, GL_V3F, GL_QUADS);
    for i := 0 to 15 do
      for j := 0 to 15 do
        begin
        fRawVBO.Vertices[4 * (16 * i + j) + 3] := Vector(0.2 * i, 0.0, 0.2 * j);
        fRawVBO.Vertices[4 * (16 * i + j) + 2] := Vector(0.2 * i + 0.2, 0.1, 0.2 * j);
        fRawVBO.Vertices[4 * (16 * i + j) + 1] := Vector(0.2 * i + 0.2, 1.1, 0.2 * j + 0.2);
        fRawVBO.Vertices[4 * (16 * i + j) + 0] := Vector(0.2 * i, 1.0, 0.2 * j + 0.2);
        end;
    fRawVBO.Unbind;
    for i := 0 to high(fAPVBOs) do
      fAPVBOs[i] := nil;
    EventManager.AddCallback('TTerrain.Resize', @ApplyChanges);
    EventManager.AddCallback('TTerrain.Changed', @ApplyChanges);
    EventManager.AddCallback('TTerrain.ChangedAll', @ApplyChanges);
    EventManager.AddCallback('TTerrain.ChangedCollection', @UpdateCollection);
  except
    ModuleManager.ModLog.AddError('Failed to create terrain renderer in OpenGL rendering module: Internal error');
  end;
end;

destructor TRTerrain.Free;
var
  i: Integer;
begin
  for i := 0 to high(fAPVBOs) do
    if fAPVBOs[i] <> nil then
      fAPVBOs[i].Free;
  EventManager.RemoveCallback(@ApplyChanges);
  EventManager.RemoveCallback(@UpdateCollection);
  fFineVBO.Free;
  fGoodVBO.Free;
  fRawVBO.Free;
  fShader.Free;
  fShaderTransformDepth.Free;
  fShaderTransformSunShadow.Free;
  fAPShader.Free;
  if fHeightMap <> nil then
    fHeightMap.Free;
end;

end.