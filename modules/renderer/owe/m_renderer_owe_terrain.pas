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

  TRTerrain = class(TThread)
    protected
      fForcedHeightLine: Single;
      fTerrainEditorIsOpen: Boolean;
      fTerrainMap: TTexture;
      fCanWork, fWorking: Boolean;
      fGeometryPassShader, fLightShadowPassShader, fSimpleGeometryPassShader, fShadowPassShader: TShader;
      fRawVBO, fFineVBO, fHDVBO, fBorderVBO, fOuterHillVBO: TVBO;
      fXBlocks, fYBlocks: Integer;
      procedure Execute; override;
    public
      Blocks: Array of TTerrainBlock;
      CurrentShader: TShader;
      BorderEnabled: Boolean;
      property TerrainMap: TTexture read fTerrainMap;
      property XBlocks: Integer read fXBlocks;
      property YBlocks: Integer read fYBlocks;
      property Working: Boolean read fWorking write fCanWork;
      property RawVBO: TVBO read fRawVBO;
      property FineVBO: TVBO read fFineVBO;
      property HDVBO: TVBO read fHDVBO;
      property GeometryPassShader: TShader read fGeometryPassShader;
      property ShadowPassShader: TShader read fShadowPassShader;
      property LightShadowPassShader: TShader read fLightShadowPassShader;
      procedure CheckVisibility;
      procedure Sync;
      procedure Render;
      procedure ApplyChanges(Event: String; Data, Result: Pointer);
      procedure UpdateCollection(Event: String; Data, Result: Pointer);
      procedure ChangeTerrainEditorState(Event: String; Data, Result: Pointer);
      procedure SetHeightLine(Event: String; Data, Result: Pointer);
      function GetBlock(X, Y: Single): TTerrainBlock;
      constructor Create;
      destructor Free;
    end;

implementation

uses
  m_varlist, g_park;

procedure TTerrainBlock.RenderRaw;
begin
  ModuleManager.ModRenderer.RTerrain.CurrentShader.UniformI('Border', 0);
  ModuleManager.ModRenderer.RTerrain.CurrentShader.UniformF('TerrainSize', 0.2 * Park.pTerrain.SizeX, 0.2 * Park.pTerrain.SizeY);
  ModuleManager.ModRenderer.RTerrain.CurrentShader.UniformF('TOffset', 0.5 / Park.pTerrain.SizeX, 0.5 / Park.pTerrain.SizeY);
  ModuleManager.ModRenderer.RTerrain.CurrentShader.UniformF('Offset', 25.6 * fX, 25.6 * fY);
  ModuleManager.ModRenderer.RTerrain.CurrentShader.UniformF('NormalMod', 0, 0, 0, 0);
  ModuleManager.ModRenderer.RTerrain.RawVBO.Bind;
  ModuleManager.ModRenderer.RTerrain.RawVBO.Render;
  ModuleManager.ModRenderer.RTerrain.RawVBO.UnBind;
end;

procedure TTerrainBlock.RenderFine;
begin
  ModuleManager.ModRenderer.RTerrain.CurrentShader.UniformI('Border', 0);
  ModuleManager.ModRenderer.RTerrain.CurrentShader.UniformF('TerrainSize', 0.2 * Park.pTerrain.SizeX, 0.2 * Park.pTerrain.SizeY);
  ModuleManager.ModRenderer.RTerrain.CurrentShader.UniformF('TOffset', 0.5 / Park.pTerrain.SizeX, 0.5 / Park.pTerrain.SizeY);
  ModuleManager.ModRenderer.RTerrain.CurrentShader.UniformF('Offset', 25.6 * fX, 25.6 * fY);
  ModuleManager.ModRenderer.RTerrain.CurrentShader.UniformF('NormalMod', 0, 0, 0, 0);
  ModuleManager.ModRenderer.RTerrain.FineVBO.Bind;
  ModuleManager.ModRenderer.RTerrain.FineVBO.Render;
  ModuleManager.ModRenderer.RTerrain.FineVBO.UnBind;
end;

procedure TTerrainBlock.RenderOneFace;
begin
  ModuleManager.ModRenderer.RTerrain.CurrentShader.UniformI('Border', 0);
  ModuleManager.ModRenderer.RTerrain.CurrentShader.UniformF('TerrainSize', 0.2 * Park.pTerrain.SizeX, 0.2 * Park.pTerrain.SizeY);
  ModuleManager.ModRenderer.RTerrain.CurrentShader.UniformF('TOffset', 0.5 / Park.pTerrain.SizeX, 0.5 / Park.pTerrain.SizeY);
  ModuleManager.ModRenderer.RTerrain.CurrentShader.UniformF('Offset', 25.6 * fX, 25.6 * fY);
  ModuleManager.ModRenderer.RTerrain.CurrentShader.UniformF('NormalMod', 0, 1, 0, 1);

  glBegin(GL_QUADS);
    glVertex3f(0, 1, 25.6); glTexCoord2f(0, 25.6);
    glVertex3f(25.6, 1, 25.6); glTexCoord2f(25.6, 25.6);
    glVertex3f(25.6, 1, 0); glTexCoord2f(25.6, 0);
    glVertex3f(0, 1, 0); glTexCoord2f(0, 0);
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
  CurrentShader.UniformF('TerrainTesselationDistance', ModuleManager.ModRenderer.CurrentTerrainTesselationDistance);
  CurrentShader.UniformF('TerrainBumpmapDistance', ModuleManager.ModRenderer.CurrentTerrainBumpmapDistance);
  CurrentShader.UniformF('Camera', ModuleManager.ModCamera.ActiveCamera.Position.x, ModuleManager.ModCamera.ActiveCamera.Position.z);

  if (Park.pTerrain.CurrMark.X >= 0) and (Park.pTerrain.CurrMark.Y >= 0) and (Park.pTerrain.CurrMark.X <= 0.2 * Park.pTerrain.SizeX) and (Park.pTerrain.CurrMark.Y <= 0.2 * Park.pTerrain.SizeY) and (Park.pTerrain.MarkMode = 0) then
    CurrentShader.UniformF('PointToHighlight', Park.pTerrain.CurrMark.X, Park.pTerrain.CurrMark.Y)
  else
    CurrentShader.UniformF('PointToHighlight', -15000, -15000);
  if (Park.pTerrain.MarkMode = 1) then
    CurrentShader.UniformF('HeightLine', 0.1 + Round(10 * Park.pTerrain.HeightMap[Park.pTerrain.CurrMark.X, Park.pTerrain.CurrMark.Y]) / 10)
  else
    CurrentShader.UniformF('HeightLine', fForcedHeightLine);
  if fTerrainEditorIsOpen then
    begin
    CurrentShader.UniformF('Min', 0, 0);
    CurrentShader.UniformF('Max', Park.pTerrain.SizeX / 5, Park.pTerrain.SizeY / 5);
    end
  else
    begin
    CurrentShader.UniformF('Min', -15000, -15000);
    CurrentShader.UniformF('Max', 15000, 15000);
    end;

  ModuleManager.ModTexMng.ActivateTexUnit(0);
  
  for i := 0 to high(Blocks) do
    if ((Blocks[BlockIDs[i]].Visible) and ((CurrentShader = fGeometryPassShader) or (CurrentShader = fLightShadowPassShader))) or ((Blocks[BlockIDs[i]].ShadowsVisible) and (CurrentShader = fShadowPassShader)) then
      if Blocks[BlockIDs[i]].MinHeight = Blocks[BlockIDs[i]].MaxHeight then
        begin
        if (CurrentShader <> fLightShadowPassShader) and (CurrentShader <> fShadowPassShader) then
          Blocks[BlockIDs[i]].RenderOneFace;
        end
      else if VecLengthNoRoot(Blocks[BlockIDs[i]].Center - ModuleManager.ModCamera.ActiveCamera.Position) > (ModuleManager.ModRenderer.CurrentTerrainDetailDistance) * (4 * ModuleManager.ModRenderer.CurrentTerrainTesselationDistance) then
        Blocks[BlockIDs[i]].RenderRaw
      else
        Blocks[BlockIDs[i]].RenderFine;

  CurrentShader.UniformI('Border', 2);
  CurrentShader.UniformF('TerrainSize', 0.2 * Park.pTerrain.SizeX, 0.2 * Park.pTerrain.SizeY);
  CurrentShader.UniformF('TOffset', 0.5 / Park.pTerrain.SizeX, 0.5 / Park.pTerrain.SizeY);
  CurrentShader.UniformF('Offset', Clamp(0.2 * Round(5 * (-ModuleManager.ModRenderer.CurrentTerrainTesselationDistance + ModuleManager.ModCamera.ActiveCamera.Position.x)), 0, 0.2 * Park.pTerrain.SizeX - 2 * ModuleManager.ModRenderer.CurrentTerrainTesselationDistance), Clamp(0.2 * Round(5 * (-ModuleManager.ModRenderer.CurrentTerrainTesselationDistance + ModuleManager.ModCamera.ActiveCamera.Position.z)), 0, 0.2 * Park.pTerrain.SizeY - 2 * ModuleManager.ModRenderer.CurrentTerrainTesselationDistance));
  CurrentShader.UniformF('NormalMod', 0, 0, 0, 0);

  if ModuleManager.ModRenderer.CurrentTerrainTesselationDistance > 0 then
    begin
    fHDVBO.Bind;
    fHDVBO.Render;
    fHDVBO.Unbind;
    end;

  if (BorderEnabled) and (CurrentShader <> fShadowPassShader) then
    if (ModuleManager.ModRenderer.ViewPoint.X < ModuleManager.ModRenderer.MaxRenderDistance) or (ModuleManager.ModRenderer.ViewPoint.Z < ModuleManager.ModRenderer.MaxRenderDistance) or
       (0.2 * Park.pTerrain.SizeX - ModuleManager.ModRenderer.ViewPoint.X < ModuleManager.ModRenderer.MaxRenderDistance) or (0.2 * Park.pTerrain.SizeY - ModuleManager.ModRenderer.ViewPoint.Z < ModuleManager.ModRenderer.MaxRenderDistance) then
      begin
      CurrentShader.UniformI('Border', 1);
      CurrentShader.UniformF('TerrainSize', 0.2 * Park.pTerrain.SizeX, 0.2 * Park.pTerrain.SizeY);
      CurrentShader.UniformF('TOffset', 0.5 / Park.pTerrain.SizeX, 0.5 / Park.pTerrain.SizeY);
      CurrentShader.UniformF('Offset', 0, 0);
      CurrentShader.UniformF('NormalMod', 0, 0, 0, 0);

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
  i, j, k: Integer;
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
    if VecLength(Vector(Blocks[0].Center.X, Blocks[0].Center.Z) - Vector(X, Y)) < d then
      begin
      r := i;
      d := VecLength(Vector(Blocks[0].Center.X, Blocks[0].Center.Z) - Vector(X, Y));
      end;
  Result := Blocks[i];
end;

constructor TRTerrain.Create;
var
  i, j: Integer;
begin
  writeln('Hint: Initializing terrain renderer');
  fTerrainMap := nil;

  fTerrainEditorIsOpen := false;
  fForcedHeightLine := -1;

  fXBlocks := 0;
  fYBlocks := 0;

  fGeometryPassShader := TShader.Create('orcf-world-engine/scene/terrain/terrain.vs', 'orcf-world-engine/scene/terrain/terrain.fs');
  fGeometryPassShader.UniformI('TerrainMap', 0);
  fGeometryPassShader.UniformI('HeightLine', -1);
  fGeometryPassShader.UniformI('TerrainTexture', 1);

  fSimpleGeometryPassShader := TShader.Create('orcf-world-engine/scene/terrain/terrainSimple.vs', 'orcf-world-engine/scene/terrain/terrainSimple.fs');
  fSimpleGeometryPassShader.UniformI('TerrainTexture', 1);

  fShadowPassShader := TShader.Create('orcf-world-engine/scene/terrain/terrainShadow.vs', 'orcf-world-engine/scene/terrain/terrainShadow.fs');
  fShadowPassShader.UniformI('TerrainMap', 0);

  fLightShadowPassShader := TShader.Create('orcf-world-engine/scene/terrain/terrainLightShadow.vs', 'orcf-world-engine/scene/terrain/terrainLightShadow.fs');
  fLightShadowPassShader.UniformI('TerrainMap', 0);

  fFineVBO := TVBO.Create(34 * 34 * 4, GL_T2F_V3F, GL_QUADS);
  for i := 0 to 33 do
    for j := 0 to 33 do
      begin
      fFineVBO.TexCoords[4 * (34 * i + j) + 3] := Vector(0.8 * i - 0.8,      0.8 * j - 0.8);
      fFineVBO.Vertices[4 * (34 * i + j) + 3]  := Vector(0.8 * i - 0.8, 1.0, 0.8 * j - 0.8);
      fFineVBO.TexCoords[4 * (34 * i + j) + 2] := Vector(0.8 * i - 0.0,      0.8 * j - 0.8);
      fFineVBO.Vertices[4 * (34 * i + j) + 2]  := Vector(0.8 * i + 0.0, 1.0, 0.8 * j - 0.8);
      fFineVBO.TexCoords[4 * (34 * i + j) + 1] := Vector(0.8 * i - 0.0,      0.8 * j - 0.0);
      fFineVBO.Vertices[4 * (34 * i + j) + 1]  := Vector(0.8 * i + 0.0, 1.0, 0.8 * j + 0.0);
      fFineVBO.TexCoords[4 * (34 * i + j) + 0] := Vector(0.8 * i - 0.8,      0.8 * j - 0.0);
      fFineVBO.Vertices[4 * (34 * i + j) + 0]  := Vector(0.8 * i - 0.8, 1.0, 0.8 * j + 0.0);
      end;
  fFineVBO.Unbind;

  fRawVBO := TVBO.Create(18 * 18 * 4, GL_T2F_V3F, GL_QUADS);
  for i := 0 to 17 do
    for j := 0 to 17 do
      begin
      fRawVBO.TexCoords[4 * (18 * i + j) + 3] := Vector(1.6 * i - 1.6,      1.6 * j - 1.6);
      fRawVBO.Vertices[4 * (18 * i + j) + 3]  := Vector(1.6 * i - 1.6, 1.0, 1.6 * j - 1.6);
      fRawVBO.TexCoords[4 * (18 * i + j) + 2] := Vector(1.6 * i + 0.0,      1.6 * j - 1.6);
      fRawVBO.Vertices[4 * (18 * i + j) + 2]  := Vector(1.6 * i + 0.0, 1.0, 1.6 * j - 1.6);
      fRawVBO.TexCoords[4 * (18 * i + j) + 1] := Vector(1.6 * i + 0.0,      1.6 * j + 0.0);
      fRawVBO.Vertices[4 * (18 * i + j) + 1]  := Vector(1.6 * i + 0.0, 1.0, 1.6 * j + 0.0);
      fRawVBO.TexCoords[4 * (18 * i + j) + 0] := Vector(1.6 * i - 1.6,      1.6 * j + 0.0);
      fRawVBO.Vertices[4 * (18 * i + j) + 0]  := Vector(1.6 * i - 1.6, 1.0, 1.6 * j + 0.0);
      end;
  fRawVBO.Unbind;

  fHDVBO := TVBO.Create(Round(ModuleManager.ModRenderer.TerrainTesselationDistance * 10) * Round(ModuleManager.ModRenderer.TerrainTesselationDistance * 10) * 4, GL_T2F_V3F, GL_QUADS);
  for i := 0 to Round(10 * ModuleManager.ModRenderer.TerrainTesselationDistance) - 1 do
    for j := 0 to Round(10 * ModuleManager.ModRenderer.TerrainTesselationDistance) - 1 do
      begin
      fHDVBO.TexCoords[4 * (Round(10 * ModuleManager.ModRenderer.TerrainTesselationDistance) * i + j) + 3] := Vector(0.2 * i - 0.2,      0.2 * j - 0.2);
      fHDVBO.Vertices[4 * (Round(10 * ModuleManager.ModRenderer.TerrainTesselationDistance) * i + j) + 3]  := Vector(0.2 * i - 0.2, 1.0, 0.2 * j - 0.2);
      fHDVBO.TexCoords[4 * (Round(10 * ModuleManager.ModRenderer.TerrainTesselationDistance) * i + j) + 2] := Vector(0.2 * i + 0.0,      0.2 * j - 0.2);
      fHDVBO.Vertices[4 * (Round(10 * ModuleManager.ModRenderer.TerrainTesselationDistance) * i + j) + 2]  := Vector(0.2 * i + 0.0, 1.0, 0.2 * j - 0.2);
      fHDVBO.TexCoords[4 * (Round(10 * ModuleManager.ModRenderer.TerrainTesselationDistance) * i + j) + 1] := Vector(0.2 * i + 0.0,      0.2 * j + 0.0);
      fHDVBO.Vertices[4 * (Round(10 * ModuleManager.ModRenderer.TerrainTesselationDistance) * i + j) + 1]  := Vector(0.2 * i + 0.0, 1.0, 0.2 * j + 0.0);
      fHDVBO.TexCoords[4 * (Round(10 * ModuleManager.ModRenderer.TerrainTesselationDistance) * i + j) + 0] := Vector(0.2 * i - 0.2,      0.2 * j + 0.0);
      fHDVBO.Vertices[4 * (Round(10 * ModuleManager.ModRenderer.TerrainTesselationDistance) * i + j) + 0]  := Vector(0.2 * i - 0.2, 1.0, 0.2 * j + 0.0);
      end;
  fHDVBO.Unbind;

  fBorderVBO := nil;
  fOuterHillVBO := nil;

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

end.