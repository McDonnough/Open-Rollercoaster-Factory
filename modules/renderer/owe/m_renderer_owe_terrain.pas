unit m_renderer_owe_terrain;

interface

uses
  Classes, SysUtils, u_scene, m_texmng_class, m_shdmng_class, u_events, m_renderer_owe_classes, DGLOpenGL, u_vectors, math, u_math;

type
  TTerrainBlock = class
    protected
      fBlockCenter: TVector3D;
      fRadius: Single;
      fMinHeight, fMaxHeight: Single;
      fX, fY: Integer;
      fVisible, fShadowsVisible: Boolean;
    public
      Changed: Boolean;
      property Visible: Boolean read fVisible;
      property ShadowsVisible: Boolean read fShadowsVisible;
      property X: Integer read fX;
      property Y: Integer read fY;
      property Center: TVector3D read fBlockCenter;
      property Radius: Single read fRadius;
      property MinHeight: Single read fMinHeight;
      property MaxHeight: Single read fMaxHeight;
      procedure Update;
      procedure CheckVisibility;
      procedure RenderOneFace;
      procedure RenderRaw;
      procedure RenderFine;
      constructor Create(iX, iY: Integer);
    end;

  TIndexedTerrainVBO = class
    protected
      fVertexBuffer, fIndexBuffer, fQuads: GLUInt;
    public
      procedure Render;
      constructor Create(QuadCount: Integer; BlockSize, Offset: Single);
      destructor Free;
    end;

  TRTerrain = class(TThread)
    protected
      fForcedHeightLine: Single;
      fTerrainEditorIsOpen: Boolean;
      fTerrainMap: TTexture;
      fCanWork, fWorking: Boolean;
      fGeometryPassShader, fLightShadowPassShader, fSimpleGeometryPassShader, fShadowPassShader, fSelectionShader: TShader;
      fBorderVBO, fOuterHillVBO: TVBO;
      fRawVBO, fFineVBO, fHDVBO: TIndexedTerrainVBO;
      fXBlocks, fYBlocks: Integer;
      fRenderHDVBO: Integer;
      procedure Execute; override;
    public
      Blocks: Array of TTerrainBlock;
      CurrentShader: TShader;
      BorderEnabled: Boolean;
      Shaders: Array[0..4] of TShader;
      Uniforms: Array[0..4, 0..14] of GLUInt;
      property TerrainEditorIsOpen: Boolean read fTerrainEditorIsOpen;
      property TerrainMap: TTexture read fTerrainMap;
      property XBlocks: Integer read fXBlocks;
      property YBlocks: Integer read fYBlocks;
      property Working: Boolean read fWorking write fCanWork;
      property RawVBO: TIndexedTerrainVBO read fRawVBO;
      property FineVBO: TIndexedTerrainVBO read fFineVBO;
      property HDVBO: TIndexedTerrainVBO read fHDVBO;
      property GeometryPassShader: TShader read fGeometryPassShader;
      property ShadowPassShader: TShader read fShadowPassShader;
      property LightShadowPassShader: TShader read fLightShadowPassShader;
      procedure CheckVisibility;
      procedure CheckForHDVBO;
      procedure Sync;
      procedure RenderSelectable(Color: DWord);
      procedure Render;
      procedure ApplyChanges(Event: String; Data, Result: Pointer);
      procedure UpdateCollection(Event: String; Data, Result: Pointer);
      procedure ChangeTerrainEditorState(Event: String; Data, Result: Pointer);
      procedure SetHeightLine(Event: String; Data, Result: Pointer);
      function GetBlock(X, Y: Single): TTerrainBlock;
      procedure Clear;
      constructor Create;
    end;

const
  UNIFORM_TERRAIN_ANY_SHADOWSIZE = 13;
  UNIFORM_TERRAIN_ANY_SHADOWOFFSET = 14;

implementation

uses
  m_varlist, g_park;

const
  SHADER_GEOMETRY = 0;
  SHADER_LIGHT_SHADOW = 1;
  SHADER_SIMPLE_GEOMETRY = 2;
  SHADER_SHADOW_PASS = 3;
  SHADER_SELECTION = 4;

  UNIFORM_ANY_BORDER = 0;
  UNIFORM_ANY_TERRAINSIZE = 1;
  UNIFORM_ANY_TOFFSET = 2;
  UNIFORM_ANY_OFFSET = 3;
  UNIFORM_ANY_NORMALMOD = 4;
  UNIFORM_ANY_TERRAINTESSELATIONDISTANCE = 5;
  UNIFORM_ANY_TERRAINBUMPMAPDISTANCE = 6;
  UNIFORM_ANY_CAMERA = 7;
  UNIFORM_ANY_POINTTOHIGHLIGHT = 8;
  UNIFORM_ANY_HEIGHTLINE = 9;
  UNIFORM_ANY_MIN = 10;
  UNIFORM_ANY_MAX = 11;
  UNIFORM_ANY_SELECTIONMESHID = 12;

procedure TIndexedTerrainVBO.Render;
begin
  glBindBufferARB(GL_ARRAY_BUFFER, fVertexBuffer);
  glBindBufferARB(GL_ELEMENT_ARRAY_BUFFER, fIndexBuffer);
  glEnableClientState(GL_VERTEX_ARRAY);
  glVertexPointer(3, GL_FLOAT, 0, Pointer(0));

  glDrawElements(GL_QUADS, 4 * fQuads, GL_UNSIGNED_INT, nil);

  glDisableClientState(GL_VERTEX_ARRAY);
  glBindBufferARB(GL_ARRAY_BUFFER, 0);
  glBindBufferARB(GL_ELEMENT_ARRAY_BUFFER, 0);
end;

constructor TIndexedTerrainVBO.Create(QuadCount: Integer; BlockSize, Offset: Single);
var
  fIndexPointer: PGLInt;
  fVBOPointer: PVector3D;
  i, j: Integer;
begin
  fQuads := QuadCount * QuadCount;

  glGenBuffers(1, @fVertexBuffer);
  glGenBuffers(1, @fIndexBuffer);
  glBindBufferARB(GL_ARRAY_BUFFER, fVertexBuffer);
  glBindBufferARB(GL_ELEMENT_ARRAY_BUFFER, fIndexBuffer);

  glBufferData(GL_ARRAY_BUFFER, SizeOf(TVector3D) * (QuadCount + 1) * (QuadCount + 1), nil, GL_STATIC_DRAW);
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, 4 * Sizeof(GLUInt) * fQuads, nil, GL_STATIC_DRAW);

  fVBOPointer := glMapBuffer(GL_ARRAY_BUFFER, GL_WRITE_ONLY);
  fIndexPointer := glMapBuffer(GL_ELEMENT_ARRAY_BUFFER, GL_WRITE_ONLY);

  for I := 0 to QuadCount do
    for J := 0 to QuadCount do
      begin
      fVBOPointer^ := Vector(BlockSize * I + Offset, 1.0, BlockSize * J + Offset);
      inc(fVBOPointer);
      end;

  for I := 0 to QuadCount - 1 do
    for J := 0 to QuadCount - 1 do
      begin
      fIndexPointer^ := (QuadCount + 1) * I + J + 1; inc(fIndexPointer);
      fIndexPointer^ := (QuadCount + 1) * I + J + QuadCount + 2; inc(fIndexPointer);
      fIndexPointer^ := (QuadCount + 1) * I + J + QuadCount + 1; inc(fIndexPointer);
      fIndexPointer^ := (QuadCount + 1) * I + J; inc(fIndexPointer);
      end;

  glUnMapBuffer(GL_ELEMENT_ARRAY_BUFFER);
  glUnMapBuffer(GL_ARRAY_BUFFER);

  glBindBufferARB(GL_ARRAY_BUFFER, 0);
  glBindBufferARB(GL_ELEMENT_ARRAY_BUFFER, 0);
end;

destructor TIndexedTerrainVBO.Free;
begin
  glDeleteBuffers(1, @fVertexBuffer);
  glDeleteBuffers(1, @fIndexBuffer);
end;

procedure TTerrainBlock.RenderRaw;
begin
  with ModuleManager.ModRenderer.RTerrain do
    begin
    CurrentShader.UniformI(Uniforms[CurrentShader.Tag, UNIFORM_ANY_BORDER], 0);
    CurrentShader.UniformF(Uniforms[CurrentShader.Tag, UNIFORM_ANY_TERRAINSIZE], 0.2 * Park.pTerrain.SizeX, 0.2 * Park.pTerrain.SizeY);
    CurrentShader.UniformF(Uniforms[CurrentShader.Tag, UNIFORM_ANY_TOFFSET], 0.5 / Park.pTerrain.SizeX, 0.5 / Park.pTerrain.SizeY);
    CurrentShader.UniformF(Uniforms[CurrentShader.Tag, UNIFORM_ANY_OFFSET], 25.6 * fX, 25.6 * fY);
    CurrentShader.UniformF(Uniforms[CurrentShader.Tag, UNIFORM_ANY_NORMALMOD], 0, 0, 0, 0);
    RawVBO.Render;
    end;
end;

procedure TTerrainBlock.RenderFine;
begin
  with ModuleManager.ModRenderer.RTerrain do
    begin
    CurrentShader.UniformI(Uniforms[CurrentShader.Tag, UNIFORM_ANY_BORDER], 0);
    CurrentShader.UniformF(Uniforms[CurrentShader.Tag, UNIFORM_ANY_TERRAINSIZE], 0.2 * Park.pTerrain.SizeX, 0.2 * Park.pTerrain.SizeY);
    CurrentShader.UniformF(Uniforms[CurrentShader.Tag, UNIFORM_ANY_TOFFSET], 0.5 / Park.pTerrain.SizeX, 0.5 / Park.pTerrain.SizeY);
    CurrentShader.UniformF(Uniforms[CurrentShader.Tag, UNIFORM_ANY_OFFSET], 25.6 * fX, 25.6 * fY);
    CurrentShader.UniformF(Uniforms[CurrentShader.Tag, UNIFORM_ANY_NORMALMOD], 0, 0, 0, 0);
    FineVBO.Render;
    end;
end;

procedure TTerrainBlock.RenderOneFace;
begin
  with ModuleManager.ModRenderer.RTerrain do
    begin
    CurrentShader.UniformI(Uniforms[CurrentShader.Tag, UNIFORM_ANY_BORDER], 0);
    CurrentShader.UniformF(Uniforms[CurrentShader.Tag, UNIFORM_ANY_TERRAINSIZE], 0.2 * Park.pTerrain.SizeX, 0.2 * Park.pTerrain.SizeY);
    CurrentShader.UniformF(Uniforms[CurrentShader.Tag, UNIFORM_ANY_TOFFSET], 0.5 / Park.pTerrain.SizeX, 0.5 / Park.pTerrain.SizeY);
    CurrentShader.UniformF(Uniforms[CurrentShader.Tag, UNIFORM_ANY_OFFSET], 25.6 * fX, 25.6 * fY);
    CurrentShader.UniformF(Uniforms[CurrentShader.Tag, UNIFORM_ANY_NORMALMOD], 0, 0, 0, 0);
    end;

  glBegin(GL_QUADS);
    glTexCoord2f(0, 25.6);    glVertex3f(0, 1, 25.6);
    glTexCoord2f(25.6, 25.6); glVertex3f(25.6, 1, 25.6);
    glTexCoord2f(25.6, 0);    glVertex3f(25.6, 1, 0);
    glTexCoord2f(0, 0);       glVertex3f(0, 1, 0);
  glEnd;
end;

procedure TTerrainBlock.Update;
var
  i, j: Integer;
begin
  Changed := False;
  fMaxHeight := 0;
  fMinHeight := 256;
  for i := 0 to 127 do
    for j := 0 to 127 do
      begin
      fMaxHeight := Max(fMaxHeight, Park.pTerrain.ExactHeightMap[128 * fX + i, 128 * fY + j] / 256);
      fMinHeight := Min(fMinHeight, Park.pTerrain.ExactHeightMap[128 * fX + i, 128 * fY + j] / 256);
      end;
  fBlockCenter.Y := (fMaxHeight + fMinHeight) / 2;
  fRadius := VecLength(Vector(12.8, (fMaxHeight - fMinHeight) / 2, 12.8));
end;

procedure TTerrainBlock.CheckVisibility;
begin
  fShadowsVisible := true;
  fVisible := false;
  if VecLengthNoRoot(ModuleManager.ModRenderer.ViewPoint - Center) - Radius * Radius < ModuleManager.ModRenderer.MaxRenderDistance * ModuleManager.ModRenderer.MaxRenderDistance then
    fVisible := ModuleManager.ModRenderer.Frustum.IsSphereWithin(fBlockCenter.X, fBlockCenter.Y, fBlockCenter.Z, fRadius);
end;

constructor TTerrainBlock.Create(iX, iY: Integer);
begin
  fX := iX;
  fY := iY;
  fRadius := 1.41 * 12.8;
  fMinHeight := 64;
  fMaxHeight := 64;
  fVisible := true;
  fShadowsVisible := true;
  fBlockCenter := Vector(12.8 + 25.6 * X, 64, 12.8 + 25.6 * Y);
  Changed := True;
end;


procedure TRTerrain.CheckVisibility;
var
  i: Integer;
begin
  for i := 0 to high(Blocks) do
    Blocks[i].CheckVisibility;
end;

procedure TRTerrain.CheckForHDVBO;
var
  i, j: Integer;
  MinBlock, MaxBlock, CBlock: TTerrainBlock;
begin
  for i := 0 to high(Blocks) do
    Blocks[i].CheckVisibility;

  fRenderHDVBO := 0;

  MinBlock := GetBlock(ModuleManager.ModCamera.ActiveCamera.Position.X - ModuleManager.ModRenderer.CurrentTerrainTesselationDistance, ModuleManager.ModCamera.ActiveCamera.Position.Z - ModuleManager.ModRenderer.CurrentTerrainTesselationDistance);
  MaxBlock := GetBlock(ModuleManager.ModCamera.ActiveCamera.Position.X + ModuleManager.ModRenderer.CurrentTerrainTesselationDistance, ModuleManager.ModCamera.ActiveCamera.Position.Z + ModuleManager.ModRenderer.CurrentTerrainTesselationDistance);
  for i := MinBlock.X to MaxBlock.X do
    for j := MinBlock.Y to MaxBlock.Y do
      begin
      CBlock := GetBlock(25.6 * i + 12.8, 25.6 * j + 12.8);
      if CBlock.MinHeight <> CBlock.MaxHeight then
        fRenderHDVBO := 1;
      end;
end;

procedure TRTerrain.Sync;
begin
  while Working do
    sleep(1);
end;

procedure TRTerrain.Execute;
var
  i: Integer;
begin
  fCanWork := False;
  fWorking := False;
  while not Terminated do
    begin
    if fCanWork then
      begin
      fCanWork := False;
      fWorking := True;

      for i := 0 to high(Blocks) do
//         if Blocks[i].Changed then
          Blocks[i].Update;

      end;
    fWorking := False;
    sleep(1);
    end;
  writeln('Hint: Terminated terrain renderer thread');
end;

procedure TRTerrain.RenderSelectable(Color: DWord);
var
  i, j: Integer;
  BlockIDs: Array of Integer;
  DistanceValues: Array of Single;
  tmps: Single;
  tmpi: Integer;
begin
  fTerrainMap.Bind(0);
  fTerrainMap.SetFilter(GL_NEAREST, GL_NEAREST);
  fSelectionShader.Bind;
  CurrentShader := fSelectionShader;
  CurrentShader.UniformI(Uniforms[CurrentShader.Tag, UNIFORM_ANY_SELECTIONMESHID], ((Color and $00FF0000) shr 16), ((Color and $0000FF00) shr 8), ((Color and $000000FF)));

  SetLength(BlockIDs, length(Blocks));
  SetLength(DistanceValues, length(Blocks));

  for i := 0 to high(Blocks) do
    begin
    BlockIDs[i] := i;
    DistanceValues[i] := VecLength(ModuleManager.ModCamera.ActiveCamera.Position - Blocks[i].Center);
    end;

  for i := 0 to high(Blocks) - 1 do
    for j := i + 1 to high(Blocks) do
      if DistanceValues[i] > DistanceValues[j] then
        begin
        tmpS := DistanceValues[i]; DistanceValues[i] := DistanceValues[j]; DistanceValues[j] := tmpS;
        tmpI := BlockIDs[i]; BlockIDs[i] := BlockIDs[j]; BlockIDs[j] := tmpI;
        end;

  for i := 0 to high(Blocks) do
    if Blocks[BlockIDs[i]].Visible then
      if Blocks[BlockIDs[i]].MinHeight = Blocks[BlockIDs[i]].MaxHeight then
        Blocks[BlockIDs[i]].RenderOneFace
      else if VecLengthNoRoot(Blocks[BlockIDs[i]].Center - ModuleManager.ModCamera.ActiveCamera.Position) > (ModuleManager.ModRenderer.CurrentTerrainDetailDistance * ModuleManager.ModRenderer.CurrentTerrainDetailDistance) then
        Blocks[BlockIDs[i]].RenderRaw
      else
        Blocks[BlockIDs[i]].RenderFine;

  fSelectionShader.Unbind;
  fTerrainMap.Unbind;
end;

procedure TRTerrain.Render;
var
  i, j: Integer;
  BlockIDs: Array of Integer;
  DistanceValues: Array of Single;
  tmps: Single;
  tmpi: Integer;
begin
  Park.pTerrain.Collection.Texture.Bind(1);
  fTerrainMap.Bind(0);
  fTerrainMap.SetFilter(GL_NEAREST, GL_NEAREST);

  setLength(BlockIDs, length(Blocks));
  setLength(DistanceValues, length(Blocks));

  glNormal3f(1, 1, 1);

  for i := 0 to high(Blocks) do
    begin
    BlockIDs[i] := i;
    DistanceValues[i] := VecLength(ModuleManager.ModCamera.ActiveCamera.Position - Blocks[i].Center);
    end;

  for i := 0 to high(Blocks) - 1 do
    for j := i + 1 to high(Blocks) do
      if DistanceValues[i] > DistanceValues[j] then
        begin
        tmpS := DistanceValues[i]; DistanceValues[i] := DistanceValues[j]; DistanceValues[j] := tmpS;
        tmpI := BlockIDs[i]; BlockIDs[i] := BlockIDs[j]; BlockIDs[j] := tmpI;
        end;

  CurrentShader.Bind;
  CurrentShader.UniformF(Uniforms[CurrentShader.Tag, UNIFORM_ANY_TERRAINTESSELATIONDISTANCE], ModuleManager.ModRenderer.CurrentTerrainTesselationDistance * fRenderHDVBO);
  CurrentShader.UniformF(Uniforms[CurrentShader.Tag, UNIFORM_ANY_TERRAINBUMPMAPDISTANCE], ModuleManager.ModRenderer.CurrentTerrainBumpmapDistance);
  CurrentShader.UniformF(Uniforms[CurrentShader.Tag, UNIFORM_ANY_CAMERA], ModuleManager.ModCamera.ActiveCamera.Position.x, ModuleManager.ModCamera.ActiveCamera.Position.z);

  if (Park.pTerrain.CurrMark.X >= 0) and (Park.pTerrain.CurrMark.Y >= 0) and (Park.pTerrain.CurrMark.X <= 0.2 * Park.pTerrain.SizeX) and (Park.pTerrain.CurrMark.Y <= 0.2 * Park.pTerrain.SizeY) and (Park.pTerrain.MarkMode = 0) then
    CurrentShader.UniformF(Uniforms[CurrentShader.Tag, UNIFORM_ANY_POINTTOHIGHLIGHT], Park.pTerrain.CurrMark.X, Park.pTerrain.CurrMark.Y)
  else
    CurrentShader.UniformF(Uniforms[CurrentShader.Tag, UNIFORM_ANY_POINTTOHIGHLIGHT], -15000, -15000);
  if (Park.pTerrain.MarkMode = 1) then
    CurrentShader.UniformF(Uniforms[CurrentShader.Tag, UNIFORM_ANY_HEIGHTLINE], 0.1 + Round(10 * Park.pTerrain.HeightMap[Park.pTerrain.CurrMark.X, Park.pTerrain.CurrMark.Y]) / 10)
  else
    CurrentShader.UniformF(Uniforms[CurrentShader.Tag, UNIFORM_ANY_HEIGHTLINE], fForcedHeightLine);
  if fTerrainEditorIsOpen then
    begin
    CurrentShader.UniformF(Uniforms[CurrentShader.Tag, UNIFORM_ANY_MIN], 0, 0);
    CurrentShader.UniformF(Uniforms[CurrentShader.Tag, UNIFORM_ANY_MAX], Park.pTerrain.SizeX / 5, Park.pTerrain.SizeY / 5);
    end
  else
    begin
    CurrentShader.UniformF(Uniforms[CurrentShader.Tag, UNIFORM_ANY_MIN], -15000, -15000);
    CurrentShader.UniformF(Uniforms[CurrentShader.Tag, UNIFORM_ANY_MAX], 15000, 15000);
    end;

  ModuleManager.ModTexMng.ActivateTexUnit(0);

  for i := 0 to high(Blocks) do
    if ((Blocks[BlockIDs[i]].Visible) and ((CurrentShader = fGeometryPassShader) or (CurrentShader = fLightShadowPassShader))) or ((Blocks[BlockIDs[i]].ShadowsVisible) and (CurrentShader = fShadowPassShader)) then
      if Blocks[BlockIDs[i]].MinHeight = Blocks[BlockIDs[i]].MaxHeight then
        begin
        if (CurrentShader <> fLightShadowPassShader) and (CurrentShader <> fShadowPassShader) then
          Blocks[BlockIDs[i]].RenderOneFace;
        end
      else if VecLengthNoRoot(Blocks[BlockIDs[i]].Center - ModuleManager.ModCamera.ActiveCamera.Position) > (ModuleManager.ModRenderer.CurrentTerrainDetailDistance * ModuleManager.ModRenderer.CurrentTerrainDetailDistance) then
        Blocks[BlockIDs[i]].RenderRaw
      else
        Blocks[BlockIDs[i]].RenderFine;


  if (ModuleManager.ModRenderer.CurrentTerrainTesselationDistance > 0) and (ModuleManager.ModRenderer.MaxRenderDistance >= VecLength(ModuleManager.ModRenderer.ViewPoint - ModuleManager.ModCamera.ActiveCamera.Position + Vector(0, -ModuleManager.ModCamera.ActiveCamera.Position.Y + Park.pTerrain.HeightMap[ModuleManager.ModCamera.ActiveCamera.Position.X, ModuleManager.ModCamera.ActiveCamera.Position.Z], 0)) - 1.732 * ModuleManager.ModRenderer.CurrentTerrainTesselationDistance) and (fRenderHDVBO = 1) then
    begin
    CurrentShader.UniformI(Uniforms[CurrentShader.Tag, UNIFORM_ANY_BORDER], 2);
    CurrentShader.UniformF(Uniforms[CurrentShader.Tag, UNIFORM_ANY_TERRAINSIZE], 0.2 * Park.pTerrain.SizeX, 0.2 * Park.pTerrain.SizeY);
    CurrentShader.UniformF(Uniforms[CurrentShader.Tag, UNIFORM_ANY_TOFFSET], 0.5 / Park.pTerrain.SizeX, 0.5 / Park.pTerrain.SizeY);
    CurrentShader.UniformF(Uniforms[CurrentShader.Tag, UNIFORM_ANY_OFFSET], Clamp(0.2 * Round(5 * (-ModuleManager.ModRenderer.CurrentTerrainTesselationDistance + ModuleManager.ModCamera.ActiveCamera.Position.x)), 0, 0.2 * Park.pTerrain.SizeX - 2 * ModuleManager.ModRenderer.CurrentTerrainTesselationDistance), Clamp(0.2 * Round(5 * (-ModuleManager.ModRenderer.CurrentTerrainTesselationDistance + ModuleManager.ModCamera.ActiveCamera.Position.z)), 0, 0.2 * Park.pTerrain.SizeY - 2 * ModuleManager.ModRenderer.CurrentTerrainTesselationDistance));
    CurrentShader.UniformF(Uniforms[CurrentShader.Tag, UNIFORM_ANY_NORMALMOD], 0, 0, 0, 0);
    fHDVBO.Render;
    end;

  if (BorderEnabled) and (CurrentShader <> fShadowPassShader) then
    if (ModuleManager.ModRenderer.ViewPoint.X < ModuleManager.ModRenderer.MaxRenderDistance) or (ModuleManager.ModRenderer.ViewPoint.Z < ModuleManager.ModRenderer.MaxRenderDistance) or
       (0.2 * Park.pTerrain.SizeX - ModuleManager.ModRenderer.ViewPoint.X < ModuleManager.ModRenderer.MaxRenderDistance) or (0.2 * Park.pTerrain.SizeY - ModuleManager.ModRenderer.ViewPoint.Z < ModuleManager.ModRenderer.MaxRenderDistance) then
      begin
      CurrentShader.UniformI(Uniforms[CurrentShader.Tag, UNIFORM_ANY_BORDER], 1);
      CurrentShader.UniformF(Uniforms[CurrentShader.Tag, UNIFORM_ANY_TERRAINSIZE], 0.2 * Park.pTerrain.SizeX, 0.2 * Park.pTerrain.SizeY);
      CurrentShader.UniformF(Uniforms[CurrentShader.Tag, UNIFORM_ANY_TOFFSET], 0.5 / Park.pTerrain.SizeX, 0.5 / Park.pTerrain.SizeY);
      CurrentShader.UniformF(Uniforms[CurrentShader.Tag, UNIFORM_ANY_OFFSET], 0, 0);
      CurrentShader.UniformF(Uniforms[CurrentShader.Tag, UNIFORM_ANY_NORMALMOD], 0, 0, 0, 0);

      fBorderVBO.Bind;
      fBorderVBO.Render;
      fBorderVBO.Unbind;
      end;

  CurrentShader.UnBind;

  if (BorderEnabled) and (CurrentShader = GeometryPassShader) then
    begin
    fSimpleGeometryPassShader.Bind;

    fOuterHillVBO.Bind;
    fOuterHillVBO.Render;
    fOuterHillVBO.Unbind;
    
    fSimpleGeometryPassShader.Unbind;
    end;
end;

procedure TRTerrain.ApplyChanges(Event: String; Data, Result: Pointer);
var
  Pixel: Array[0..2] of Word;
  HasBlock: Array of Array of Boolean;
  i, j, k, x, y, h, w: Integer;
  Radius1, Radius2, Random1, Random2: Single;
  Center: TVector3D;

  procedure StartUpdate;
  begin
    fTerrainMap.Bind(0);
  end;

  procedure UpdateVertex(X, Y: Word);
  begin
    Pixel[0] := Park.pTerrain.ExactTexMap[X, Y];
    Pixel[1] := Park.pTerrain.ExactWaterMap[X, Y];
    Pixel[2] := Park.pTerrain.ExactHeightMap[X, Y];

    glTexSubImage2D(GL_TEXTURE_2D, 0, X, Y, 1, 1, GL_RGB, GL_UNSIGNED_SHORT, @Pixel[0]);
  end;

  procedure UpdateQuad(X, Y, W, H: Word);
  var
    Pixels: Array of Array[0..2] of Word;
    i, j: Integer;
  begin
    setLength(Pixels, W * H);
    for i := 0 to W - 1 do
      for j := 0 to H - 1 do
        begin
        Pixels[j * W + i, 0] := Park.pTerrain.ExactTexMap[X + I, Y + J];
        Pixels[j * W + i, 1] := Park.pTerrain.ExactWaterMap[X + I, Y + J];
        Pixels[j * W + i, 2] := Park.pTerrain.ExactHeightMap[X + I, Y + J];
        end;
    glTexSubImage2D(GL_TEXTURE_2D, 0, X, Y, W, H, GL_RGB, GL_UNSIGNED_SHORT, @Pixels[0, 0]);
    setLength(Pixels, 0);
  end;

  procedure EndUpdate;
  begin
    fTerrainMap.Unbind;
  end;

begin
  if Event = 'TTerrain.Resize' then
    begin
    Sync;
    if fTerrainMap <> nil then
      fTerrainMap.Free;
    fTerrainMap := TTexture.Create;
    fTerrainMap.CreateNew(Park.pTerrain.SizeX, Park.pTerrain.SizeY, GL_RGB16);
    fTerrainMap.SetClamp(GL_MIRRORED_REPEAT, GL_MIRRORED_REPEAT);
    fTerrainMap.Unbind;
    if fBorderVBO <> nil then
      fBorderVBO.Free;
    fBorderVBO := TVBO.Create(4 * (2 * Park.pTerrain.SizeX div 16 * 32 + 2 * Park.pTerrain.SizeY div 16 * 32 + 4 * 32 * 32 + 16), GL_T2F_N3F_V3F, GL_QUADS);
    begin
      k := 0;
      for i := 0 to (Park.pTerrain.SizeX div 16) - 1 do
        for j := 0 to 31 do
          begin
          fBorderVBO.TexCoords[k + 0] := Vector(16 * (i + 0) / 5, Park.pTerrain.SizeY / 5 - (j + 1) / 5 * (j + 1) / 8);
          fBorderVBO.Normals[k + 0] := Vector(1, 1, -1);
          fBorderVBO.Vertices[k + 0] := Vector(3.2 * (i + 0), 1 - ((j + 1) / 32) * ((j + 1) / 32), (j + 1) * (j + 1) / 5 + Park.pTerrain.SizeY / 5);
          fBorderVBO.TexCoords[k + 1] := Vector(16 * (i + 1) / 5, Park.pTerrain.SizeY / 5 - (j + 1) / 5 * (j + 1) / 8);
          fBorderVBO.Normals[k + 1] := Vector(1, 1, -1);
          fBorderVBO.Vertices[k + 1] := Vector(3.2 * (i + 1), 1 - ((j + 1) / 32) * ((j + 1) / 32), (j + 1) * (j + 1) / 5 + Park.pTerrain.SizeY / 5);
          fBorderVBO.TexCoords[k + 2] := Vector(16 * (i + 1) / 5, Park.pTerrain.SizeY / 5 - (j + 0) / 5 * (j + 0) / 8);
          fBorderVBO.Normals[k + 2] := Vector(1, 1, -1);
          fBorderVBO.Vertices[k + 2] := Vector(3.2 * (i + 1), 1 - ((j + 0) / 32) * ((j + 0) / 32), (j + 0) * (j + 0) / 5 + Park.pTerrain.SizeY / 5);
          fBorderVBO.TexCoords[k + 3] := Vector(16 * (i + 0) / 5, Park.pTerrain.SizeY / 5 - (j + 0) / 5 * (j + 0) / 8);
          fBorderVBO.Normals[k + 3] := Vector(1, 1, -1);
          fBorderVBO.Vertices[k + 3] := Vector(3.2 * (i + 0), 1 - ((j + 0) / 32) * ((j + 0) / 32), (j + 0) * (j + 0) / 5 + Park.pTerrain.SizeY / 5);
          inc(k, 4);

          fBorderVBO.TexCoords[k + 0] := Vector(16 * (i + 0) / 5, (j + 0) / 5 * (j + 0) / 8);
          fBorderVBO.Normals[k + 0] := Vector(1, 1, -1);
          fBorderVBO.Vertices[k + 0] := Vector(3.2 * (i + 0), 1 - ((j + 0) / 32) * ((j + 0) / 32), (j + 0) * (j + 0) / -5);
          fBorderVBO.TexCoords[k + 1] := Vector(16 * (i + 1) / 5, (j + 0) / 5 * (j + 0) / 8);
          fBorderVBO.Normals[k + 1] := Vector(1, 1, -1);
          fBorderVBO.Vertices[k + 1] := Vector(3.2 * (i + 1), 1 - ((j + 0) / 32) * ((j + 0) / 32), (j + 0) * (j + 0) / -5);
          fBorderVBO.TexCoords[k + 2] := Vector(16 * (i + 1) / 5, (j + 1) / 5 * (j + 1) / 8);
          fBorderVBO.Normals[k + 2] := Vector(1, 1, -1);
          fBorderVBO.Vertices[k + 2] := Vector(3.2 * (i + 1), 1 - ((j + 1) / 32) * ((j + 1) / 32), (j + 1) * (j + 1) / -5);
          fBorderVBO.TexCoords[k + 3] := Vector(16 * (i + 0) / 5, (j + 1) / 5 * (j + 1) / 8);
          fBorderVBO.Normals[k + 3] := Vector(1, 1, -1);
          fBorderVBO.Vertices[k + 3] := Vector(3.2 * (i + 0), 1 - ((j + 1) / 32) * ((j + 1) / 32), (j + 1) * (j + 1) / -5);
          inc(k, 4);
          end;

      for i := 0 to (Park.pTerrain.SizeY div 16) - 1 do
        for j := 0 to 31 do
          begin
          fBorderVBO.TexCoords[k + 0] := Vector(Park.pTerrain.SizeX / 5 - (j + 0) / 5 * (j + 0) / 8, 16 * (i + 0) / 5);
          fBorderVBO.Normals[k + 0] := Vector(-1, 1, 1);
          fBorderVBO.Vertices[k + 0] := Vector((j + 0) * (j + 0) / 5 + Park.pTerrain.SizeX / 5, 1 - ((j + 0) / 32) * ((j + 0) / 32), 3.2 * (i + 0));
          fBorderVBO.TexCoords[k + 1] := Vector(Park.pTerrain.SizeX / 5 - (j + 0) / 5 * (j + 0) / 8, 16 * (i + 1) / 5);
          fBorderVBO.Normals[k + 1] := Vector(-1, 1, 1);
          fBorderVBO.Vertices[k + 1] := Vector((j + 0) * (j + 0) / 5 + Park.pTerrain.SizeX / 5, 1 - ((j + 0) / 32) * ((j + 0) / 32), 3.2 * (i + 1));
          fBorderVBO.TexCoords[k + 2] := Vector(Park.pTerrain.SizeX / 5 - (j + 1) / 5 * (j + 1) / 8, 16 * (i + 1) / 5);
          fBorderVBO.Normals[k + 2] := Vector(-1, 1, 1);
          fBorderVBO.Vertices[k + 2] := Vector((j + 1) * (j + 1) / 5 + Park.pTerrain.SizeX / 5, 1 - ((j + 1) / 32) * ((j + 1) / 32), 3.2 * (i + 1));
          fBorderVBO.TexCoords[k + 3] := Vector(Park.pTerrain.SizeX / 5 - (j + 1) / 5 * (j + 1) / 8, 16 * (i + 0) / 5);
          fBorderVBO.Normals[k + 3] := Vector(-1, 1, 1);
          fBorderVBO.Vertices[k + 3] := Vector((j + 1) * (j + 1) / 5 + Park.pTerrain.SizeX / 5, 1 - ((j + 1) / 32) * ((j + 1) / 32), 3.2 * (i + 0));
          inc(k, 4);

          fBorderVBO.TexCoords[k + 0] := Vector((j + 1) / 5 * (j + 1) / 8, 16 * (i + 0) / 5);
          fBorderVBO.Normals[k + 0] := Vector(-1, 1, 1);
          fBorderVBO.Vertices[k + 0] := Vector((j + 1) * (j + 1) / -5, 1 - ((j + 1) / 32) * ((j + 1) / 32), 3.2 * (i + 0));
          fBorderVBO.TexCoords[k + 1] := Vector((j + 1) / 5 * (j + 1) / 8, 16 * (i + 1) / 5);
          fBorderVBO.Normals[k + 1] := Vector(-1, 1, 1);
          fBorderVBO.Vertices[k + 1] := Vector((j + 1) * (j + 1) / -5, 1 - ((j + 1) / 32) * ((j + 1) / 32), 3.2 * (i + 1));
          fBorderVBO.TexCoords[k + 2] := Vector((j + 0) / 5 * (j + 0) / 8, 16 * (i + 1) / 5);
          fBorderVBO.Normals[k + 2] := Vector(-1, 1, 1);
          fBorderVBO.Vertices[k + 2] := Vector((j + 0) * (j + 0) / -5, 1 - ((j + 0) / 32) * ((j + 0) / 32), 3.2 * (i + 1));
          fBorderVBO.TexCoords[k + 3] := Vector((j + 0) / 5 * (j + 0) / 8, 16 * (i + 0) / 5);
          fBorderVBO.Normals[k + 3] := Vector(-1, 1, 1);
          fBorderVBO.Vertices[k + 3] := Vector((j + 0) * (j + 0) / -5, 1 - ((j + 0) / 32) * ((j + 0) / 32), 3.2 * (i + 0));
          inc(k, 4);
          end;

      for i := 0 to 31 do
        for j := 0 to 31 do
          begin
          fBorderVBO.TexCoords[k + 0] := Vector(Park.pTerrain.SizeX / 5 - (i + 0) / 5 * (i + 0) / 8, Park.pTerrain.SizeY / 5 - (j + 1) / 5 * (j + 1) / 8);
          fBorderVBO.Normals[k + 0] := Vector(-1, 1, -1);
          fBorderVBO.Vertices[k + 0] := Vector((i + 0) * (i + 0) / 5 + Park.pTerrain.SizeX / 5, Max(0, 1 - VecLength(Vector(((i + 0) / 32) * ((i + 0) / 32), ((j + 1) / 32) * ((j + 1) / 32)))), (j + 1) * (j + 1) / 5 + Park.pTerrain.SizeY / 5);
          fBorderVBO.TexCoords[k + 1] := Vector(Park.pTerrain.SizeX / 5 - (i + 1) / 5 * (i + 1) / 8, Park.pTerrain.SizeY / 5 - (j + 1) / 5 * (j + 1) / 8);
          fBorderVBO.Normals[k + 1] := Vector(-1, 1, -1);
          fBorderVBO.Vertices[k + 1] := Vector((i + 1) * (i + 1) / 5 + Park.pTerrain.SizeX / 5, Max(0, 1 - VecLength(Vector(((i + 1) / 32) * ((i + 1) / 32), ((j + 1) / 32) * ((j + 1) / 32)))), (j + 1) * (j + 1) / 5 + Park.pTerrain.SizeY / 5);
          fBorderVBO.TexCoords[k + 2] := Vector(Park.pTerrain.SizeX / 5 - (i + 1) / 5 * (i + 1) / 8, Park.pTerrain.SizeY / 5 - (j + 0) / 5 * (j + 0) / 8);
          fBorderVBO.Normals[k + 2] := Vector(-1, 1, -1);
          fBorderVBO.Vertices[k + 2] := Vector((i + 1) * (i + 1) / 5 + Park.pTerrain.SizeX / 5, Max(0, 1 - VecLength(Vector(((i + 1) / 32) * ((i + 1) / 32), ((j + 0) / 32) * ((j + 0) / 32)))), (j + 0) * (j + 0) / 5 + Park.pTerrain.SizeY / 5);
          fBorderVBO.TexCoords[k + 3] := Vector(Park.pTerrain.SizeX / 5 - (i + 0) / 5 * (i + 0) / 8, Park.pTerrain.SizeY / 5 - (j + 0) / 5 * (j + 0) / 8);
          fBorderVBO.Normals[k + 3] := Vector(-1, 1, -1);
          fBorderVBO.Vertices[k + 3] := Vector((i + 0) * (i + 0) / 5 + Park.pTerrain.SizeX / 5, Max(0, 1 - VecLength(Vector(((i + 0) / 32) * ((i + 0) / 32), ((j + 0) / 32) * ((j + 0) / 32)))), (j + 0) * (j + 0) / 5 + Park.pTerrain.SizeY / 5);
          inc(k, 4);

          fBorderVBO.TexCoords[k + 0] := Vector((i + 0) / 5 * (i + 0) / 8, (j + 1) / 5 * (j + 1) / 8);
          fBorderVBO.Normals[k + 0] := Vector(-1, 1, -1);
          fBorderVBO.Vertices[k + 0] := Vector((i + 0) * (i + 0) / -5, Max(0, 1 - VecLength(Vector(((i + 0) / 32) * ((i + 0) / 32), ((j + 1) / 32) * ((j + 1) / 32)))), (j + 1) * (j + 1) / -5);
          fBorderVBO.TexCoords[k + 1] := Vector((i + 1) / 5 * (i + 1) / 8, (j + 1) / 5 * (j + 1) / 8);
          fBorderVBO.Normals[k + 1] := Vector(-1, 1, -1);
          fBorderVBO.Vertices[k + 1] := Vector((i + 1) * (i + 1) / -5, Max(0, 1 - VecLength(Vector(((i + 1) / 32) * ((i + 1) / 32), ((j + 1) / 32) * ((j + 1) / 32)))), (j + 1) * (j + 1) / -5);
          fBorderVBO.TexCoords[k + 2] := Vector((i + 1) / 5 * (i + 1) / 8, (j + 0) / 5 * (j + 0) / 8);
          fBorderVBO.Normals[k + 2] := Vector(-1, 1, -1);
          fBorderVBO.Vertices[k + 2] := Vector((i + 1) * (i + 1) / -5, Max(0, 1 - VecLength(Vector(((i + 1) / 32) * ((i + 1) / 32), ((j + 0) / 32) * ((j + 0) / 32)))), (j + 0) * (j + 0) / -5);
          fBorderVBO.TexCoords[k + 3] := Vector((i + 0) / 5 * (i + 0) / 8, (j + 0) / 5 * (j + 0) / 8);
          fBorderVBO.Normals[k + 3] := Vector(-1, 1, -1);
          fBorderVBO.Vertices[k + 3] := Vector((i + 0) * (i + 0) / -5, Max(0, 1 - VecLength(Vector(((i + 0) / 32) * ((i + 0) / 32), ((j + 0) / 32) * ((j + 0) / 32)))), (j + 0) * (j + 0) / -5);
          inc(k, 4);

          fBorderVBO.TexCoords[k + 0] := Vector((i + 0) / 5 * (i + 0) / 8, Park.pTerrain.SizeY / 5 - (j + 0) / 5 * (j + 0) / 8);
          fBorderVBO.Normals[k + 0] := Vector(-1, 1, -1);
          fBorderVBO.Vertices[k + 0] := Vector((i + 0) * (i + 0) / -5, Max(0, 1 - VecLength(Vector(((i + 0) / 32) * ((i + 0) / 32), ((j + 0) / 32) * ((j + 0) / 32)))), (j + 0) * (j + 0) / 5 + Park.pTerrain.SizeY / 5);
          fBorderVBO.TexCoords[k + 1] := Vector((i + 1) / 5 * (i + 1) / 8, Park.pTerrain.SizeY / 5 - (j + 0) / 5 * (j + 0) / 8);
          fBorderVBO.Normals[k + 1] := Vector(-1, 1, -1);
          fBorderVBO.Vertices[k + 1] := Vector((i + 1) * (i + 1) / -5, Max(0, 1 - VecLength(Vector(((i + 1) / 32) * ((i + 1) / 32), ((j + 0) / 32) * ((j + 0) / 32)))), (j + 0) * (j + 0) / 5 + Park.pTerrain.SizeY / 5);
          fBorderVBO.TexCoords[k + 2] := Vector((i + 1) / 5 * (i + 1) / 8, Park.pTerrain.SizeY / 5 - (j + 1) / 5 * (j + 1) / 8);
          fBorderVBO.Normals[k + 2] := Vector(-1, 1, -1);
          fBorderVBO.Vertices[k + 2] := Vector((i + 1) * (i + 1) / -5, Max(0, 1 - VecLength(Vector(((i + 1) / 32) * ((i + 1) / 32), ((j + 1) / 32) * ((j + 1) / 32)))), (j + 1) * (j + 1) / 5 + Park.pTerrain.SizeY / 5);
          fBorderVBO.TexCoords[k + 3] := Vector((i + 0) / 5 * (i + 0) / 8, Park.pTerrain.SizeY / 5 - (j + 1) / 5 * (j + 1) / 8);
          fBorderVBO.Normals[k + 3] := Vector(-1, 1, -1);
          fBorderVBO.Vertices[k + 3] := Vector((i + 0) * (i + 0) / -5, Max(0, 1 - VecLength(Vector(((i + 0) / 32) * ((i + 0) / 32), ((j + 1) / 32) * ((j + 1) / 32)))), (j + 1) * (j + 1) / 5 + Park.pTerrain.SizeY / 5);
          inc(k, 4);

          fBorderVBO.TexCoords[k + 0] := Vector(Park.pTerrain.SizeX / 5 - (i + 0) / 5 * (i + 0) / 8, (j + 0) / 5 * (j + 0) / 8);
          fBorderVBO.Normals[k + 0] := Vector(-1, 1, -1);
          fBorderVBO.Vertices[k + 0] := Vector((i + 0) * (i + 0) / 5 + Park.pTerrain.SizeX / 5, Max(0, 1 - VecLength(Vector(((i + 0) / 32) * ((i + 0) / 32), ((j + 0) / 32) * ((j + 0) / 32)))), (j + 0) * (j + 0) / -5);
          fBorderVBO.TexCoords[k + 1] := Vector(Park.pTerrain.SizeX / 5 - (i + 1) / 5 * (i + 1) / 8, (j + 0) / 5 * (j + 0) / 8);
          fBorderVBO.Normals[k + 1] := Vector(-1, 1, -1);
          fBorderVBO.Vertices[k + 1] := Vector((i + 1) * (i + 1) / 5 + Park.pTerrain.SizeX / 5, Max(0, 1 - VecLength(Vector(((i + 1) / 32) * ((i + 1) / 32), ((j + 0) / 32) * ((j + 0) / 32)))), (j + 0) * (j + 0) / -5);
          fBorderVBO.TexCoords[k + 2] := Vector(Park.pTerrain.SizeX / 5 - (i + 1) / 5 * (i + 1) / 8, (j + 1) / 5 * (j + 1) / 8);
          fBorderVBO.Normals[k + 2] := Vector(-1, 1, -1);
          fBorderVBO.Vertices[k + 2] := Vector((i + 1) * (i + 1) / 5 + Park.pTerrain.SizeX / 5, Max(0, 1 - VecLength(Vector(((i + 1) / 32) * ((i + 1) / 32), ((j + 1) / 32) * ((j + 1) / 32)))), (j + 1) * (j + 1) / -5);
          fBorderVBO.TexCoords[k + 3] := Vector(Park.pTerrain.SizeX / 5 - (i + 0) / 5 * (i + 0) / 8, (j + 1) / 5 * (j + 1) / 8);
          fBorderVBO.Normals[k + 3] := Vector(-1, 1, -1);
          fBorderVBO.Vertices[k + 3] := Vector((i + 0) * (i + 0) / 5 + Park.pTerrain.SizeX / 5, Max(0, 1 - VecLength(Vector(((i + 0) / 32) * ((i + 0) / 32), ((j + 1) / 32) * ((j + 1) / 32)))), (j + 1) * (j + 1) / -5);
          inc(k, 4);
          end;

      fBorderVBO.TexCoords[k + 0] := Vector(25.6, 25.6);
      fBorderVBO.Normals[k + 0] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 0] := Vector(-204.8, 0, -204.8);
      fBorderVBO.TexCoords[k + 1] := Vector(25.6, 25.6);
      fBorderVBO.Normals[k + 1] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 1] := Vector(-204.8, 0, -10000);
      fBorderVBO.TexCoords[k + 2] := Vector(25.6, 25.6);
      fBorderVBO.Normals[k + 2] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 2] := Vector(-10000, 0, -10000);
      fBorderVBO.TexCoords[k + 3] := Vector(25.6, 25.6);
      fBorderVBO.Normals[k + 3] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 3] := Vector(-10000, 0, -204.8);
      inc(k, 4);

      fBorderVBO.TexCoords[k + 0] := Vector(Park.pTerrain.SizeX / 5 - 25.6, Park.pTerrain.SizeY / 5 - 25.6);
      fBorderVBO.Normals[k + 0] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 0] := Vector(Park.pTerrain.SizeX / 5 + 204.8, 0, Park.pTerrain.SizeY / 5 + 204.8);
      fBorderVBO.TexCoords[k + 1] := Vector(Park.pTerrain.SizeX / 5 - 25.6, Park.pTerrain.SizeY / 5 - 25.6);
      fBorderVBO.Normals[k + 1] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 1] := Vector(Park.pTerrain.SizeX / 5 + 204.8, 0, Park.pTerrain.SizeY / 5 + 10000);
      fBorderVBO.TexCoords[k + 2] := Vector(Park.pTerrain.SizeX / 5 - 25.6, Park.pTerrain.SizeY / 5 - 25.6);
      fBorderVBO.Normals[k + 2] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 2] := Vector(Park.pTerrain.SizeX / 5 + 10000, 0, Park.pTerrain.SizeY / 5 + 10000);
      fBorderVBO.TexCoords[k + 3] := Vector(Park.pTerrain.SizeX / 5 - 25.6, Park.pTerrain.SizeY / 5 - 25.6);
      fBorderVBO.Normals[k + 3] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 3] := Vector(Park.pTerrain.SizeX / 5 + 10000, 0, Park.pTerrain.SizeY / 5 + 204.8);
      inc(k, 4);

      fBorderVBO.TexCoords[k + 0] := Vector(Park.pTerrain.SizeX / 5 - 25.6, 25.6);
      fBorderVBO.Normals[k + 0] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 0] := Vector(Park.pTerrain.SizeX / 5 + 10000, 0, -204.8);
      fBorderVBO.TexCoords[k + 1] := Vector(Park.pTerrain.SizeX / 5 - 25.6, 25.6);
      fBorderVBO.Normals[k + 1] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 1] := Vector(Park.pTerrain.SizeX / 5 + 10000, 0, -10000);
      fBorderVBO.TexCoords[k + 2] := Vector(Park.pTerrain.SizeX / 5 - 25.6, 25.6);
      fBorderVBO.Normals[k + 2] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 2] := Vector(Park.pTerrain.SizeX / 5 + 204.8, 0, -10000);
      fBorderVBO.TexCoords[k + 3] := Vector(Park.pTerrain.SizeX / 5 - 25.6, 25.6);
      fBorderVBO.Normals[k + 3] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 3] := Vector(Park.pTerrain.SizeX / 5 + 204.8, 0, -204.8);
      inc(k, 4);

      fBorderVBO.TexCoords[k + 0] := Vector(25.6, Park.pTerrain.SizeY / 5 - 25.6);
      fBorderVBO.Normals[k + 0] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 0] := Vector(-10000, 0, Park.pTerrain.SizeY / 5 + 204.8);
      fBorderVBO.TexCoords[k + 1] := Vector(25.6, Park.pTerrain.SizeY / 5 - 25.6);
      fBorderVBO.Normals[k + 1] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 1] := Vector(-10000, 0, Park.pTerrain.SizeY / 5 + 10000);
      fBorderVBO.TexCoords[k + 2] := Vector(25.6, Park.pTerrain.SizeY / 5 - 25.6);
      fBorderVBO.Normals[k + 2] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 2] := Vector(-204.8, 0, Park.pTerrain.SizeY / 5 + 10000);
      fBorderVBO.TexCoords[k + 3] := Vector(25.6, Park.pTerrain.SizeY / 5 - 25.6);
      fBorderVBO.Normals[k + 3] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 3] := Vector(-204.8, 0, Park.pTerrain.SizeY / 5 + 204.8);
      inc(k, 4);

      fBorderVBO.TexCoords[k + 3] := Vector(25.6, 25.6);
      fBorderVBO.Normals[k + 3] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 3] := Vector(-204.8, 0, -204.8);
      fBorderVBO.TexCoords[k + 2] := Vector(25.6, 25.6);
      fBorderVBO.Normals[k + 2] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 2] := Vector(-204.8, 0, -10000);
      fBorderVBO.TexCoords[k + 1] := Vector(0, 25.6);
      fBorderVBO.Normals[k + 1] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 1] := Vector(0, 0, -10000);
      fBorderVBO.TexCoords[k + 0] := Vector(0, 25.6);
      fBorderVBO.Normals[k + 0] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 0] := Vector(0, 0, -204.8);
      inc(k, 4);
      fBorderVBO.TexCoords[k + 0] := Vector(Park.pTerrain.SizeX / 5, 25.6);
      fBorderVBO.Normals[k + 0] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 0] := Vector(Park.pTerrain.SizeX / 5, 0, -204.8);
      fBorderVBO.TexCoords[k + 1] := Vector(Park.pTerrain.SizeX / 5, 25.6);
      fBorderVBO.Normals[k + 1] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 1] := Vector(Park.pTerrain.SizeX / 5, 0, -10000);
      fBorderVBO.TexCoords[k + 2] := Vector(0, 25.6);
      fBorderVBO.Normals[k + 2] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 2] := Vector(0, 0, -10000);
      fBorderVBO.TexCoords[k + 3] := Vector(0, 25.6);
      fBorderVBO.Normals[k + 3] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 3] := Vector(0, 0, -204.8);
      inc(k, 4);
      fBorderVBO.TexCoords[k + 3] := Vector(Park.pTerrain.SizeX / 5, 25.6);
      fBorderVBO.Normals[k + 3] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 3] := Vector(Park.pTerrain.SizeX / 5, 0, -204.8);
      fBorderVBO.TexCoords[k + 2] := Vector(Park.pTerrain.SizeX / 5, 25.6);
      fBorderVBO.Normals[k + 2] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 2] := Vector(Park.pTerrain.SizeX / 5, 0, -10000);
      fBorderVBO.TexCoords[k + 1] := Vector(Park.pTerrain.SizeX / 5 - 25.6, 25.6);
      fBorderVBO.Normals[k + 1] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 1] := Vector(Park.pTerrain.SizeX / 5 + 204.8, 0, -10000);
      fBorderVBO.TexCoords[k + 0] := Vector(Park.pTerrain.SizeX / 5 - 25.6, 25.6);
      fBorderVBO.Normals[k + 0] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 0] := Vector(Park.pTerrain.SizeX / 5 + 204.8, 0, -204.8);
      inc(k, 4);

      fBorderVBO.TexCoords[k + 0] := Vector(25.6, Park.pTerrain.SizeY / 5 - 25.6);
      fBorderVBO.Normals[k + 0] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 0] := Vector(-204.8, 0, Park.pTerrain.SizeY / 5 + 204.8);
      fBorderVBO.TexCoords[k + 1] := Vector(25.6, Park.pTerrain.SizeY / 5 - 25.6);
      fBorderVBO.Normals[k + 1] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 1] := Vector(-204.8, 0, Park.pTerrain.SizeY / 5 + 10000);
      fBorderVBO.TexCoords[k + 2] := Vector(0, Park.pTerrain.SizeY / 5 - 25.6);
      fBorderVBO.Normals[k + 2] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 2] := Vector(0, 0, Park.pTerrain.SizeY / 5 + 10000);
      fBorderVBO.TexCoords[k + 3] := Vector(0, Park.pTerrain.SizeY / 5 - 25.6);
      fBorderVBO.Normals[k + 3] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 3] := Vector(0, 0, Park.pTerrain.SizeY / 5 + 204.8);
      inc(k, 4);
      fBorderVBO.TexCoords[k + 0] := Vector(0, Park.pTerrain.SizeY / 5 - 25.6);
      fBorderVBO.Normals[k + 0] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 0] := Vector(0, 0, Park.pTerrain.SizeY / 5 + 204.8);
      fBorderVBO.TexCoords[k + 1] := Vector(0, Park.pTerrain.SizeY / 5 - 25.6);
      fBorderVBO.Normals[k + 1] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 1] := Vector(0, 0, Park.pTerrain.SizeY / 5 + 10000);
      fBorderVBO.TexCoords[k + 2] := Vector(Park.pTerrain.SizeX / 5, Park.pTerrain.SizeY / 5 - 25.6);
      fBorderVBO.Normals[k + 2] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 2] := Vector(Park.pTerrain.SizeX / 5, 0, Park.pTerrain.SizeY / 5 + 10000);
      fBorderVBO.TexCoords[k + 3] := Vector(Park.pTerrain.SizeX / 5, Park.pTerrain.SizeY / 5 - 25.6);
      fBorderVBO.Normals[k + 3] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 3] := Vector(Park.pTerrain.SizeX / 5, 0, Park.pTerrain.SizeY / 5 + 204.8);
      inc(k, 4);
      fBorderVBO.TexCoords[k + 0] := Vector(Park.pTerrain.SizeX / 5, Park.pTerrain.SizeY / 5 - 25.6);
      fBorderVBO.Normals[k + 0] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 0] := Vector(Park.pTerrain.SizeX / 5, 0, Park.pTerrain.SizeY / 5 + 204.8);
      fBorderVBO.TexCoords[k + 1] := Vector(Park.pTerrain.SizeX / 5, Park.pTerrain.SizeY / 5 - 25.6);
      fBorderVBO.Normals[k + 1] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 1] := Vector(Park.pTerrain.SizeX / 5, 0, Park.pTerrain.SizeY / 5 + 10000);
      fBorderVBO.TexCoords[k + 2] := Vector(Park.pTerrain.SizeX / 5 - 25.6, Park.pTerrain.SizeY / 5 - 25.6);
      fBorderVBO.Normals[k + 2] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 2] := Vector(Park.pTerrain.SizeX / 5 + 204.8, 0, Park.pTerrain.SizeY / 5 + 10000);
      fBorderVBO.TexCoords[k + 3] := Vector(Park.pTerrain.SizeX / 5 - 25.6, Park.pTerrain.SizeY / 5 - 25.6);
      fBorderVBO.Normals[k + 3] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 3] := Vector(Park.pTerrain.SizeX / 5 + 204.8, 0, Park.pTerrain.SizeY / 5 + 204.8);
      inc(k, 4);

      fBorderVBO.TexCoords[k + 0] := Vector(25.6, 25.6);
      fBorderVBO.Normals[k + 0] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 0] := Vector(-204.8, 0, -204.8);
      fBorderVBO.TexCoords[k + 1] := Vector(25.6, 25.6);
      fBorderVBO.Normals[k + 1] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 1] := Vector(-10000, 0, -204.8);
      fBorderVBO.TexCoords[k + 2] := Vector(25.6, 0);
      fBorderVBO.Normals[k + 2] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 2] := Vector(-10000, 0, 0);
      fBorderVBO.TexCoords[k + 3] := Vector(25.6, 0);
      fBorderVBO.Normals[k + 3] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 3] := Vector(-204.8, 0, 0);
      inc(k, 4);
      fBorderVBO.TexCoords[k + 0] := Vector(25.6, 0);
      fBorderVBO.Normals[k + 0] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 0] := Vector(-204.8, 0, 0);
      fBorderVBO.TexCoords[k + 1] := Vector(25.6, 0);
      fBorderVBO.Normals[k + 1] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 1] := Vector(-10000, 0, 0);
      fBorderVBO.TexCoords[k + 2] := Vector(25.6, Park.pTerrain.SizeY / 5);
      fBorderVBO.Normals[k + 2] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 2] := Vector(-10000, 0, Park.pTerrain.SizeY / 5);
      fBorderVBO.TexCoords[k + 3] := Vector(25.6, Park.pTerrain.SizeY / 5);
      fBorderVBO.Normals[k + 3] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 3] := Vector(-204.8, 0, Park.pTerrain.SizeY / 5);
      inc(k, 4);
      fBorderVBO.TexCoords[k + 0] := Vector(25.6, Park.pTerrain.SizeY / 5);
      fBorderVBO.Normals[k + 0] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 0] := Vector(-204.8, 0, Park.pTerrain.SizeY / 5);
      fBorderVBO.TexCoords[k + 1] := Vector(25.6, Park.pTerrain.SizeY / 5);
      fBorderVBO.Normals[k + 1] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 1] := Vector(-10000, 0, Park.pTerrain.SizeY / 5);
      fBorderVBO.TexCoords[k + 2] := Vector(25.6, Park.pTerrain.SizeY / 5 - 25.6);
      fBorderVBO.Normals[k + 2] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 2] := Vector(-10000, 0, Park.pTerrain.SizeY / 5 + 204.8);
      fBorderVBO.TexCoords[k + 3] := Vector(25.6, Park.pTerrain.SizeY / 5 - 25.6);
      fBorderVBO.Normals[k + 3] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 3] := Vector(-204.8, 0, Park.pTerrain.SizeY / 5 + 204.8);
      inc(k, 4);

      fBorderVBO.TexCoords[k + 3] := Vector(Park.pTerrain.SizeX / 5 - 25.6, 25.6);
      fBorderVBO.Normals[k + 3] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 3] := Vector(Park.pTerrain.SizeX / 5 + 204.8, 0, -204.8);
      fBorderVBO.TexCoords[k + 2] := Vector(Park.pTerrain.SizeX / 5 - 25.6, 25.6);
      fBorderVBO.Normals[k + 2] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 2] := Vector(Park.pTerrain.SizeX / 5 + 10000, 0, -204.8);
      fBorderVBO.TexCoords[k + 1] := Vector(Park.pTerrain.SizeX / 5 - 25.6, 0);
      fBorderVBO.Normals[k + 1] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 1] := Vector(Park.pTerrain.SizeX / 5 + 10000, 0, 0);
      fBorderVBO.TexCoords[k + 0] := Vector(Park.pTerrain.SizeX / 5 - 25.6, 0);
      fBorderVBO.Normals[k + 0] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 0] := Vector(Park.pTerrain.SizeX / 5 + 204.8, 0, 0);
      inc(k, 4);
      fBorderVBO.TexCoords[k + 3] := Vector(Park.pTerrain.SizeX / 5 - 25.6, 0);
      fBorderVBO.Normals[k + 3] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 3] := Vector(Park.pTerrain.SizeX / 5 + 204.8, 0, 0);
      fBorderVBO.TexCoords[k + 2] := Vector(Park.pTerrain.SizeX / 5 - 25.6, 0);
      fBorderVBO.Normals[k + 2] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 2] := Vector(Park.pTerrain.SizeX / 5 + 10000, 0, 0);
      fBorderVBO.TexCoords[k + 1] := Vector(Park.pTerrain.SizeX / 5 - 25.6, Park.pTerrain.SizeY / 5);
      fBorderVBO.Normals[k + 1] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 1] := Vector(Park.pTerrain.SizeX / 5 + 10000, 0, Park.pTerrain.SizeY / 5);
      fBorderVBO.TexCoords[k + 0] := Vector(Park.pTerrain.SizeX / 5 - 25.6, Park.pTerrain.SizeY / 5);
      fBorderVBO.Normals[k + 0] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 0] := Vector(Park.pTerrain.SizeX / 5 + 204.8, 0, Park.pTerrain.SizeY / 5);
      inc(k, 4);
      fBorderVBO.TexCoords[k + 3] := Vector(Park.pTerrain.SizeX / 5 - 25.6, Park.pTerrain.SizeY / 5);
      fBorderVBO.Normals[k + 3] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 3] := Vector(Park.pTerrain.SizeX / 5 + 204.8, 0, Park.pTerrain.SizeY / 5);
      fBorderVBO.TexCoords[k + 2] := Vector(Park.pTerrain.SizeX / 5 - 25.6, Park.pTerrain.SizeY / 5);
      fBorderVBO.Normals[k + 2] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 2] := Vector(Park.pTerrain.SizeX / 5 + 10000, 0, Park.pTerrain.SizeY / 5);
      fBorderVBO.TexCoords[k + 1] := Vector(Park.pTerrain.SizeX / 5 - 25.6, Park.pTerrain.SizeY / 5 - 25.6);
      fBorderVBO.Normals[k + 1] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 1] := Vector(Park.pTerrain.SizeX / 5 + 10000, 0, Park.pTerrain.SizeY / 5 + 204.8);
      fBorderVBO.TexCoords[k + 0] := Vector(Park.pTerrain.SizeX / 5 - 25.6, Park.pTerrain.SizeY / 5 - 25.6);
      fBorderVBO.Normals[k + 0] := Vector(0, 1, 0);
      fBorderVBO.Vertices[k + 0] := Vector(Park.pTerrain.SizeX / 5 + 204.8, 0, Park.pTerrain.SizeY / 5 + 204.8);
      inc(k, 4);
    end;
    fBorderVBO.Unbind;

    if fOuterHillVBO <> nil then
      fOuterHillVBO.Free;
    fOuterHillVBO := TVBO.Create(90 * 4 * 4, GL_V3F, GL_QUADS);

    Center := Vector(Park.pTerrain.SizeX, 64, Park.pTerrain.SizeY) * 0.1;

    k := 0;

    for i := 0 to 3 do
      begin
      Radius1 := 1500 * Power(1.5, i);
      Radius2 := 1500 * Power(1.5, i + 0.5);
      Random2 := 0;
      for j := 0 to 89 do
        begin
        Random1 := Random2;
        Random2 := Random;
        if j = 89 then
          Random2 := 0;
        fOuterHillVBO.Vertices[k + 0] := Center + Vector(sin(DegToRad(4 * (j + 0))), 0, cos(DegToRad(4 * (j + 0)))) * Radius2 + Vector(0, Power(2.3, i) * 18, 0) * (0.8 + 0.4 * Random1);
        fOuterHillVBO.Vertices[k + 1] := Center + Vector(sin(DegToRad(4 * (j + 1))), 0, cos(DegToRad(4 * (j + 1)))) * Radius2 + Vector(0, Power(2.3, i) * 18, 0) * (0.8 + 0.4 * Random2);
        fOuterHillVBO.Vertices[k + 2] := Center + Vector(sin(DegToRad(4 * (j + 1))), 0, cos(DegToRad(4 * (j + 1)))) * Radius1;
        fOuterHillVBO.Vertices[k + 3] := Center + Vector(sin(DegToRad(4 * (j + 0))), 0, cos(DegToRad(4 * (j + 0)))) * Radius1;
        
        inc(k, 4);
        end;
      end;

    fOuterHillVBO.Unbind;
    
    SetLength(HasBlock, Park.pTerrain.SizeX div 128);
    for i := 0 to high(HasBlock) do
      begin
      SetLength(HasBlock[i], Park.pTerrain.SizeY div 128);
      for j := 0 to high(HasBlock[i]) do
        HasBlock[i, j] := false;
      end;

    for i := 0 to high(Blocks) do
      if (Blocks[i].X > Park.pTerrain.SizeX div 128) or (Blocks[i].Y > Park.pTerrain.SizeY div 128) then
        begin
        Blocks[i].Free;
        Blocks[i] := nil;
        end
      else
        HasBlock[Blocks[i].X, Blocks[i].Y] := True;

    for i := 0 to high(Blocks) do
      if i <= high(Blocks) then
        begin
        while Blocks[i] = nil do
          begin
          Blocks[i] := Blocks[high(Blocks)];
          SetLength(Blocks, Length(Blocks) - 1);
          if i > high(Blocks) then
            break;
          end;
        end;

    for i := 0 to high(HasBlock) do
      for j := 0 to high(HasBlock[i]) do
        if not HasBlock[i, j] then
          begin
          SetLength(Blocks, length(Blocks) + 1);
          Blocks[high(Blocks)] := TTerrainBlock.Create(i, j);
          end;

    StartUpdate;
//     for i := 0 to Park.pTerrain.SizeX - 1 do
//       for j := 0 to Park.pTerrain.SizeY - 1 do
//         UpdateVertex(I, J);
    UpdateQuad(0, 0, Park.pTerrain.SizeX, Park.pTerrain.SizeY);
    EndUpdate;
    end;

  if (Data <> nil) and ((Event = 'TTerrain.Changed') or (Event = 'TTerrain.ChangedTexmap') or (Event = 'TTerrain.ChangedWater')) then
    begin
    k := Integer(Data^);
    if k > 0 then
      begin
//       x := Park.pTerrain.SizeX + 1; y := Park.pTerrain.SizeY + 1; w := -1; h := -1;
      StartUpdate;

      for i := 0 to k - 1 do
        begin
        UpdateVertex(Integer((Data + 2 * sizeof(Integer) * i + sizeof(Integer))^), Integer((Data + 2 * sizeof(Integer) * i + 2 * sizeof(Integer))^));
//         X := Min(X, Integer((Data + 2 * sizeof(Integer) * i + sizeof(Integer))^));
//         W := Max(X, Integer((Data + 2 * sizeof(Integer) * i + sizeof(Integer))^));
//         Y := Min(Y, Integer((Data + 2 * sizeof(Integer) * i + 2 * sizeof(Integer))^));
//         H := Max(H, Integer((Data + 2 * sizeof(Integer) * i + 2 * sizeof(Integer))^));
        end;

//       if (X < Park.pTerrain.SizeX) and (Y < Park.pTerrain.SizeY) and (W > -1) and (H > -1) then
//         UpdateQuad(X, Y, W - X + 1, H - Y + 1);
        
      EndUpdate;
      if Event <> 'TTerrain.ChangedTexmap' then
        fCanWork := True;
      end;
    end;

end;

procedure TRTerrain.UpdateCollection(Event: String; Data, Result: Pointer);
begin

end;

procedure TRTerrain.ChangeTerrainEditorState(Event: String; Data, Result: Pointer);
begin
  fTerrainEditorIsOpen := not fTerrainEditorIsOpen;
end;

procedure TRTerrain.SetHeightLine(Event: String; Data, Result: Pointer);
begin
  fForcedHeightLine := Single(Data^);
end;

function TRTerrain.GetBlock(X, Y: Single): TTerrainBlock;
var
  i, r: Integer;
  d: Single;
begin
  r := 0;
  d := VecLength(Vector(Blocks[0].Center.X, Blocks[0].Center.Z) - Vector(X, Y));
  for i := 0 to high(Blocks) do
    if VecLength(Vector(Blocks[i].Center.X, Blocks[i].Center.Z) - Vector(X, Y)) < d then
      begin
      r := i;
      d := VecLength(Vector(Blocks[i].Center.X, Blocks[i].Center.Z) - Vector(X, Y));
      end;
  Result := Blocks[r];
end;

procedure TRTerrain.Clear;
var
  i, j: Integer;
begin
  EventManager.RemoveCallback(@SetHeightLine);
  EventManager.RemoveCallback(@ChangeTerrainEditorState);
  EventManager.RemoveCallback(@ApplyChanges);
  EventManager.RemoveCallback(@UpdateCollection);
  Terminate;
  Sync;
  fSelectionShader.Free;
  fLightShadowPassShader.Free;
  fShadowPassShader.Free;
  fSimpleGeometryPassShader.Free;
  fGeometryPassShader.Free;
  if fTerrainMap <> nil then
    fTerrainMap.Free;
  fBorderVBO.Free;
  fRawVBO.Free;
  fFineVBO.Free;
  fHDVBO.Free;
  for i := 0 to high(Blocks) do
    Blocks[i].Free;
  sleep(100);
end;

constructor TRTerrain.Create;
var
  i: Integer;
begin
  writeln('Hint: Initializing terrain renderer');
  fTerrainMap := nil;

  fTerrainEditorIsOpen := false;
  fForcedHeightLine := -1;

  fXBlocks := 0;
  fYBlocks := 0;

  fRenderHDVBO := 1;

  fGeometryPassShader := TShader.Create('orcf-world-engine/scene/terrain/terrain.vs', 'orcf-world-engine/scene/terrain/terrain.fs');
  fGeometryPassShader.UniformI('TerrainMap', 0);
  fGeometryPassShader.UniformI('HeightLine', -1);
  fGeometryPassShader.UniformI('TerrainTexture', 1);
  fGeometryPassShader.Tag := SHADER_GEOMETRY;

  fSimpleGeometryPassShader := TShader.Create('orcf-world-engine/scene/terrain/terrainSimple.vs', 'orcf-world-engine/scene/terrain/terrainSimple.fs');
  fSimpleGeometryPassShader.UniformI('TerrainTexture', 1);
  fSimpleGeometryPassShader.Tag := SHADER_SIMPLE_GEOMETRY;

  fShadowPassShader := TShader.Create('orcf-world-engine/scene/terrain/terrainShadow.vs', 'orcf-world-engine/scene/terrain/terrainShadow.fs');
  fShadowPassShader.UniformI('TerrainMap', 0);
  fShadowPassShader.Tag := SHADER_SHADOW_PASS;

  fLightShadowPassShader := TShader.Create('orcf-world-engine/scene/terrain/terrainLightShadow.vs', 'orcf-world-engine/scene/terrain/terrainLightShadow.fs');
  fLightShadowPassShader.UniformI('TerrainMap', 0);
  fLightShadowPassShader.Tag := SHADER_LIGHT_SHADOW;

  fSelectionShader := TShader.Create('orcf-world-engine/scene/terrain/terrain.vs', 'orcf-world-engine/inferred/selection.fs');
  fSelectionShader.UniformI('TerrainMap', 0);
  fSelectionShader.Tag := SHADER_SELECTION;

  Shaders[SHADER_GEOMETRY] := fGeometryPassShader;
  Shaders[SHADER_LIGHT_SHADOW] := fLightShadowPassShader;
  Shaders[SHADER_SIMPLE_GEOMETRY] := fSimpleGeometryPassShader;
  Shaders[SHADER_SHADOW_PASS] := fShadowPassShader;
  Shaders[SHADER_SELECTION] := fSelectionShader;

  for I := 0 to high(Shaders) do
    begin
    Uniforms[I, UNIFORM_ANY_BORDER] := Shaders[I].GetUniformLocation('Border');
    Uniforms[I, UNIFORM_ANY_TERRAINSIZE] := Shaders[I].GetUniformLocation('TerrainSize');
    Uniforms[I, UNIFORM_ANY_TOFFSET] := Shaders[I].GetUniformLocation('TOffset');
    Uniforms[I, UNIFORM_ANY_OFFSET] := Shaders[I].GetUniformLocation('Offset');
    Uniforms[I, UNIFORM_ANY_NORMALMOD] := Shaders[I].GetUniformLocation('NormalMod');
    Uniforms[I, UNIFORM_ANY_TERRAINTESSELATIONDISTANCE] := Shaders[I].GetUniformLocation('TerrainTesselationDistance');
    Uniforms[I, UNIFORM_ANY_TERRAINBUMPMAPDISTANCE] := Shaders[I].GetUniformLocation('TerrainBumpmapDistance');
    Uniforms[I, UNIFORM_ANY_CAMERA] := Shaders[I].GetUniformLocation('Camera');
    Uniforms[I, UNIFORM_ANY_POINTTOHIGHLIGHT] := Shaders[I].GetUniformLocation('PointToHighlight');
    Uniforms[I, UNIFORM_ANY_HEIGHTLINE] := Shaders[I].GetUniformLocation('HeightLine');
    Uniforms[I, UNIFORM_ANY_MIN] := Shaders[I].GetUniformLocation('Min');
    Uniforms[I, UNIFORM_ANY_MAX] := Shaders[I].GetUniformLocation('Max');
    Uniforms[I, UNIFORM_ANY_SELECTIONMESHID] := Shaders[I].GetUniformLocation('SelectionMeshID');
    Uniforms[I, UNIFORM_TERRAIN_ANY_SHADOWSIZE] := Shaders[I].GetUniformLocation('ShadowSize');
    Uniforms[I, UNIFORM_TERRAIN_ANY_SHADOWOFFSET] := Shaders[I].GetUniformLocation('ShadowOffset');
    end;

  fFineVBO := TIndexedTerrainVBO.Create(34, 0.8, -0.8);
  fRawVBO := TIndexedTerrainVBO.Create(18, 1.6, -1.6);
  fHDVBO := TIndexedTerrainVBO.Create(Round(ModuleManager.ModRenderer.TerrainTesselationDistance * 10), 0.2, 0);

  fBorderVBO := nil;
  fOuterHillVBO := nil;

  CurrentShader := nil;

  EventManager.AddCallback('TTerrain.ApplyForcedHeightLine', @SetHeightLine);
  EventManager.AddCallback('GUIActions.terrain_edit.open', @ChangeTerrainEditorState);
  EventManager.AddCallback('GUIActions.terrain_edit.close', @ChangeTerrainEditorState);
  EventManager.AddCallback('GUIActions.object_builder.open', @ChangeTerrainEditorState);
  EventManager.AddCallback('GUIActions.object_builder.close', @ChangeTerrainEditorState);
  EventManager.AddCallback('TTerrain.Resize', @ApplyChanges);
  EventManager.AddCallback('TTerrain.Changed', @ApplyChanges);
  EventManager.AddCallback('TTerrain.ChangedTexmap', @ApplyChanges);
  EventManager.AddCallback('TTerrain.ChangedWater', @ApplyChanges);
  EventManager.AddCallback('TTerrain.ChangedCollection', @UpdateCollection);

  inherited Create(false);
end;

end.