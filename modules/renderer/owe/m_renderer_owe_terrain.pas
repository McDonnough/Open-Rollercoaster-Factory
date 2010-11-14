unit m_renderer_owe_terrain;

interface

uses
  Classes, SysUtils, u_scene, m_texmng_class, m_shdmng_class, u_events, m_renderer_owe_classes, DGLOpenGL, u_vectors, math;

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

  TRTerrain = class(TThread)
    protected
      fTerrainMap: TTexture;
      fCanWork, fWorking: Boolean;
      fGeometryPassShader, fShadowPassShader: TShader;
      fRawVBO, fFineVBO: TVBO;
      fXBlocks, fYBlocks: Integer;
      procedure Execute; override;
    public
      Blocks: Array of TTerrainBlock;
      CurrentShader: TShader;
      property TerrainMap: TTexture read fTerrainMap;
      property XBlocks: Integer read fXBlocks;
      property YBlocks: Integer read fYBlocks;
      property Working: Boolean read fWorking write fCanWork;
      property RawVBO: TVBO read fRawVBO;
      property FineVBO: TVBO read fFineVBO;
      property GeometryPassShader: TShader read fGeometryPassShader;
      property ShadowPassShader: TShader read fShadowPassShader;
      procedure CheckVisibility;
      procedure Sync;
      procedure Render;
      procedure ApplyChanges(Event: String; Data, Result: Pointer);
      procedure UpdateCollection(Event: String; Data, Result: Pointer);
      procedure ChangeTerrainEditorState(Event: String; Data, Result: Pointer);
      procedure SetHeightLine(Event: String; Data, Result: Pointer);
      constructor Create;
      destructor Free;
    end;

implementation

uses
  m_varlist, g_park;

procedure TTerrainBlock.RenderRaw;
begin
  ModuleManager.ModRenderer.RTerrain.CurrentShader.UniformI('Tesselation', 0);
  ModuleManager.ModRenderer.RTerrain.CurrentShader.UniformF('TerrainSize', 0.2 * Park.pTerrain.SizeX, 0.2 * Park.pTerrain.SizeY);
  ModuleManager.ModRenderer.RTerrain.CurrentShader.UniformF('TOffset', 0.3 / Park.pTerrain.SizeX, 0.5 / Park.pTerrain.SizeY);
  ModuleManager.ModRenderer.RTerrain.CurrentShader.UniformF('Offset', 25.6 * fX, 25.6 * fY);
  ModuleManager.ModRenderer.RTerrain.RawVBO.Bind;
  ModuleManager.ModRenderer.RTerrain.RawVBO.Render;
  ModuleManager.ModRenderer.RTerrain.RawVBO.UnBind;
end;

procedure TTerrainBlock.RenderFine;
begin
  ModuleManager.ModRenderer.RTerrain.CurrentShader.UniformI('Tesselation', 1);
  ModuleManager.ModRenderer.RTerrain.CurrentShader.UniformF('TerrainSize', 0.2 * Park.pTerrain.SizeX, 0.2 * Park.pTerrain.SizeY);
  ModuleManager.ModRenderer.RTerrain.CurrentShader.UniformF('TOffset', 0.3 / Park.pTerrain.SizeX, 0.5 / Park.pTerrain.SizeY);
  ModuleManager.ModRenderer.RTerrain.CurrentShader.UniformF('Offset', 25.6 * fX, 25.6 * fY);
  ModuleManager.ModRenderer.RTerrain.FineVBO.Bind;
  ModuleManager.ModRenderer.RTerrain.FineVBO.Render;
  ModuleManager.ModRenderer.RTerrain.FineVBO.UnBind;
end;

procedure TTerrainBlock.RenderOneFace;
begin
  ModuleManager.ModRenderer.RTerrain.CurrentShader.UniformI('Tesselation', 0);
  ModuleManager.ModRenderer.RTerrain.CurrentShader.UniformF('TerrainSize', 0.2 * Park.pTerrain.SizeX, 0.2 * Park.pTerrain.SizeY);
  ModuleManager.ModRenderer.RTerrain.CurrentShader.UniformF('TOffset', 0.3 / Park.pTerrain.SizeX, 0.5 / Park.pTerrain.SizeY);
  ModuleManager.ModRenderer.RTerrain.CurrentShader.UniformF('Offset', 25.6 * fX, 25.6 * fY);
  glBegin(GL_QUADS);
    glVertex3f(0, 0, 25.6);
    glVertex3f(25.6, 0, 25.6);
    glVertex3f(25.6, 0, 0);
    glVertex3f(0, 0, 0);
  glEnd;
end;

procedure TTerrainBlock.Update;
var
  i, j: Integer;
begin
  Changed := False;
  fMaxHeight := 0;
  fMinHeight := 256;
  for i := 0 to 128 do
    for j := 0 to 128 do
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
    sleep(10);
    end;
  writeln('Hint: Terminated terrain renderer thread');
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
  for i := 0 to high(Blocks) do
    if ((Blocks[BlockIDs[i]].Visible) and (CurrentShader = fGeometryPassShader)) or ((Blocks[BlockIDs[i]].ShadowsVisible) and (CurrentShader = fShadowPassShader)) then
      if Blocks[BlockIDs[i]].MinHeight = Blocks[BlockIDs[i]].MaxHeight then
        Blocks[BlockIDs[i]].RenderOneFace
      else if VecLengthNoRoot(Blocks[BlockIDs[i]].Center - ModuleManager.ModCamera.ActiveCamera.Position) > (ModuleManager.ModRenderer.TerrainDetailDistance) * (4 * ModuleManager.ModRenderer.TerrainTesselationDistance) then
        Blocks[BlockIDs[i]].RenderRaw
      else
        Blocks[BlockIDs[i]].RenderFine;
  CurrentShader.UnBind;
end;

procedure TRTerrain.ApplyChanges(Event: String; Data, Result: Pointer);
var
  Pixel: Array[0..2] of Word;
  HasBlock: Array of Array of Boolean;
  i, j, k: Integer;

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
    fTerrainMap.SetClamp(GL_CLAMP, GL_CLAMP);
    fTerrainMap.Unbind;
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
    for i := 0 to Park.pTerrain.SizeX - 1 do
      for j := 0 to Park.pTerrain.SizeY - 1 do
        UpdateVertex(I, J);
    EndUpdate;
    end;

  if (Data <> nil) and ((Event = 'TTerrain.Changed') or (Event = 'TTerrain.ChangedTexmap') or (Event = 'TTerrain.ChangedWater')) then
    begin
    k := Integer(Data^);
    StartUpdate;
    for i := 0 to k - 1 do
      UpdateVertex(Integer((Data + 2 * sizeof(Integer) * i + sizeof(Integer))^), Integer((Data + 2 * sizeof(Integer) * i + 2 * sizeof(Integer))^));
    EndUpdate;
    if Event <> 'TTerrain.ChangedTexmap' then
      fCanWork := True;
    end;

end;

procedure TRTerrain.UpdateCollection(Event: String; Data, Result: Pointer);
begin

end;

procedure TRTerrain.ChangeTerrainEditorState(Event: String; Data, Result: Pointer);
begin

end;

procedure TRTerrain.SetHeightLine(Event: String; Data, Result: Pointer);
begin

end;

constructor TRTerrain.Create;
var
  i, j: Integer;
begin
  writeln('Hint; Initializing terrain renderer');
  fTerrainMap := nil;

  fXBlocks := 0;
  fYBlocks := 0;

  fGeometryPassShader := TShader.Create('orcf-world-engine/scene/terrain/terrain.vs', 'orcf-world-engine/scene/terrain/terrain.fs', 'orcf-world-engine/scene/terrain/terrain.gs', 24);
  fGeometryPassShader.UniformF('TerrainTesselationDistance', ModuleManager.ModRenderer.TerrainTesselationDistance);
  fGeometryPassShader.UniformF('TerrainBumpmapDistance', ModuleManager.ModRenderer.TerrainBumpmapDistance);
  fGeometryPassShader.UniformI('TerrainMap', 0);
  fGeometryPassShader.UniformI('HeightLine', -1);
  fGeometryPassShader.UniformI('TerrainTexture', 1);

  fShadowPassShader := TShader.Create('orcf-world-engine/scene/terrain/terrain.vs', 'orcf-world-engine/inferred/shadow.fs', 'orcf-world-engine/scene/terrain/terrainShadow.gs', 240);
  fShadowPassShader.UniformF('TerrainTesselationDistance', ModuleManager.ModRenderer.TerrainTesselationDistance);
  fShadowPassShader.UniformI('TerrainMap', 0);

  fFineVBO := TVBO.Create(32 * 32 * 4, GL_V3F, GL_QUADS);
  for i := 0 to 31 do
    for j := 0 to 31 do
      begin
      fFineVBO.Vertices[4 * (32 * i + j) + 3] := Vector(0.8 * i,       0.0, 0.8 * j);
      fFineVBO.Vertices[4 * (32 * i + j) + 2] := Vector(0.8 * i + 0.8, 0.0, 0.8 * j);
      fFineVBO.Vertices[4 * (32 * i + j) + 1] := Vector(0.8 * i + 0.8, 0.0, 0.8 * j + 0.8);
      fFineVBO.Vertices[4 * (32 * i + j) + 0] := Vector(0.8 * i,       0.0, 0.8 * j + 0.8);
      end;
  fFineVBO.Unbind;

  fRawVBO := TVBO.Create(16 * 16 * 4, GL_V3F, GL_QUADS);
  for i := 0 to 15 do
    for j := 0 to 15 do
      begin
      fRawVBO.Vertices[4 * (16 * i + j) + 3] := Vector(1.6 * i,       0.0, 1.6 * j);
      fRawVBO.Vertices[4 * (16 * i + j) + 2] := Vector(1.6 * i + 1.6, 0.0, 1.6 * j);
      fRawVBO.Vertices[4 * (16 * i + j) + 1] := Vector(1.6 * i + 1.6, 0.0, 1.6 * j + 1.6);
      fRawVBO.Vertices[4 * (16 * i + j) + 0] := Vector(1.6 * i,       0.0, 1.6 * j + 1.6);
      end;
  fRawVBO.Unbind;

  CurrentShader := nil;

  EventManager.AddCallback('TTerrain.ApplyForcedHeightLine', @SetHeightLine);
  EventManager.AddCallback('GUIActions.terrain_edit.open', @ChangeTerrainEditorState);
  EventManager.AddCallback('GUIActions.terrain_edit.close', @ChangeTerrainEditorState);
  EventManager.AddCallback('TTerrain.Resize', @ApplyChanges);
  EventManager.AddCallback('TTerrain.Changed', @ApplyChanges);
  EventManager.AddCallback('TTerrain.ChangedTexmap', @ApplyChanges);
  EventManager.AddCallback('TTerrain.ChangedWater', @ApplyChanges);
  EventManager.AddCallback('TTerrain.ChangedCollection', @UpdateCollection);

  inherited Create(false);
end;

destructor TRTerrain.Free;
var
  i, j: Integer;
begin
  EventManager.RemoveCallback(@SetHeightLine);
  EventManager.RemoveCallback(@ChangeTerrainEditorState);
  EventManager.RemoveCallback(@ApplyChanges);
  EventManager.RemoveCallback(@UpdateCollection);
  Terminate;
  Sync;
  fShadowPassShader.Free;
  fGeometryPassShader.Free;
  if fTerrainMap <> nil then
    fTerrainMap.Free;
  fRawVBO.Free;
  fFineVBO.Free;
  for i := 0 to high(Blocks) do
    Blocks[i].Free;
  sleep(100);
end;

end.