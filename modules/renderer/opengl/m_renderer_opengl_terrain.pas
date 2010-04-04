unit m_renderer_opengl_terrain;

interface

uses
  SysUtils, Classes, DGLOpenGL, m_renderer_opengl_classes, u_vectors, m_shdmng_class, m_texmng_class, u_math, math;

type
  TRTerrain = class
    protected
      fVBOs: Array of Array of TVBO;
      fRawVBOs: Array of Array of TVBO;
      fTempVBO, fFineVBO: TVBO;
      fShader: TShader;
      fTexture: TTexture;
      fTmpFineOffsetX, fTmpFineOffsetY: Word;
      fFineOffsetX, fFineOffsetY: Word;
      fMovingRow: Integer;
      fMVec: Array[0..4] of TVector2D;
      fPrevPos: TVector2D;
      fNormals: Array of Array of TVector3D;
      fNormalMap, fLayerMap: TFBO;
      RenderStep: Single;
      procedure MoveHDTerrain;
      function GetNormal(X, Y: Single; force: Boolean = false): TVector3D;
    public
      procedure Render;
      procedure ApplyChanges(Event: String; Data, Result: Pointer);
      constructor Create;
      destructor Free;
    end;

implementation

uses
  g_park, u_events, m_varlist;

function TRTerrain.GetNormal(X, Y: Single; force: Boolean = false): TVector3D;
var
  h: Single;
  Available: Boolean;
begin
  Available := False;
  if (X < high(fNormals)) and (X >= 0) then
    if (Y < high(fNormals[Round(X)])) and (Y >= 0) then
      Available := fNormals[Round(X), Round(Y)].Y <> 0;
  Available := Available and not force;
  if not Available then
    begin
    X := X / 5;
    Y := Y / 5;
    h := Park.pTerrain.HeightMap[X, Y];
    Result := Normalize(
      Normal(Vector(+0.0, Park.pTerrain.HeightMap[X + 0.0, Y - 0.2] - h, -0.2), Vector(-0.2, Park.pTerrain.HeightMap[X - 0.2, Y + 0.0] - h, +0.0))
    + Normal(Vector(+0.2, Park.pTerrain.HeightMap[X + 0.2, Y + 0.0] - h, +0.0), Vector(+0.0, Park.pTerrain.HeightMap[X + 0.0, Y - 0.2] - h, -0.2))
    + Normal(Vector(+0.0, Park.pTerrain.HeightMap[X + 0.0, Y + 0.2] - h, +0.2), Vector(+0.2, Park.pTerrain.HeightMap[X + 0.2, Y + 0.0] - h, -0.0))
    + Normal(Vector(-0.2, Park.pTerrain.HeightMap[X - 0.2, Y + 0.0] - h, +0.0), Vector(+0.0, Park.pTerrain.HeightMap[X + 0.0, Y + 0.2] - h, +0.2)))
    / 4;
    if (5 * X < high(fNormals)) and (X >= 0) then
      if (5 * Y < high(fNormals[Round(5 * X)])) and (Y >= 0) then
        fNormals[Round(5 * X), Round(5 * Y)] := Result;
    end
  else
    Result := fNormals[Round(X), Round(Y)];
end;

procedure TRTerrain.MoveHDTerrain;
var
  i, j: Integer;
  a: TVBO;
  Motion: TVector2D;
  TexMap: TVector4D;

  procedure CalcMotion;
  begin
    Motion := (fMVec[0] + fMVec[1] + fMVec[2] + fMVec[3] + fMVec[4]) / 5 * 78;
  end;

  function InterpolateHeightMap(X, Y: Single): Single;
  begin
    Result := -1;
    if (Round(Y - fTmpFineOffsetY) <= 0) or (Round(Y - fTmpFineOffsetY) >= 256) then
      Result := Mix(Park.pTerrain.HeightMap[0.8 * Floor(X / 4), Y / 5], Park.pTerrain.HeightMap[0.8 * Ceil(X / 4), Y / 5], FPart(X / 4))
    else if (Round(X - fTmpFineOffsetX) <= 0) or (Round(X - fTmpFineOffsetX) >= 256) then
      Result := Mix(Park.pTerrain.HeightMap[X / 5, 0.8 * Floor(Y / 4)], Park.pTerrain.HeightMap[X / 5, 0.8 * Ceil(Y / 4)], FPart(Y / 4))
    else
      Result := Park.pTerrain.HeightMap[X / 5, Y / 5];
  end;

begin
  fMVec[4] := fMVec[3];
  fMVec[3] := fMVec[2];
  fMVec[2] := fMVec[1];
  fMVec[1] := fMVec[0];
  fMVec[0] := Vector(ModuleManager.ModCamera.ActiveCamera.Position.X, ModuleManager.ModCamera.ActiveCamera.Position.Z) - fPrevPos;
  fPrevPos := Vector(ModuleManager.ModCamera.ActiveCamera.Position.X, ModuleManager.ModCamera.ActiveCamera.Position.Z);
  fTempVBO.Bind;
  for i := fMovingRow to min(255, fMovingRow + 4) do
    for j := 0 to 255 do
      begin
      fTempVBO.Vertices[4 * (256 * i + j) + 0] := Vector(0.2 * i, InterpolateHeightMap((i + fTmpFineOffsetX), (j + fTmpFineOffsetY)), 0.2 * j);
      fTempVBO.Vertices[4 * (256 * i + j) + 1] := Vector(0.2 * i + 0.2, InterpolateHeightMap((i + fTmpFineOffsetX + 1), (j + fTmpFineOffsetY)), 0.2 * j);
      fTempVBO.Vertices[4 * (256 * i + j) + 2] := Vector(0.2 * i + 0.2, InterpolateHeightMap((i + fTmpFineOffsetX + 1), (j + fTmpFineOffsetY + 1)), 0.2 * j + 0.2);
      fTempVBO.Vertices[4 * (256 * i + j) + 3] := Vector(0.2 * i, InterpolateHeightMap((i + fTmpFineOffsetX), (j + fTmpFineOffsetY + 1)), 0.2 * j + 0.2);

      TexMap := Vector(
        Park.pTerrain.TexMap[(i + fTmpFineOffsetX) / 5, (j + fTmpFineOffsetY) / 5],
        Park.pTerrain.TexMap[(i + fTmpFineOffsetX + 1) / 5, (j + fTmpFineOffsetY) / 5],
        Park.pTerrain.TexMap[(i + fTmpFineOffsetX) / 5, (j + fTmpFineOffsetY + 1) / 5],
        Park.pTerrain.TexMap[(i + fTmpFineOffsetX + 1) / 5, (j + fTmpFineOffsetY + 1) / 5]);
      end;
  fTempVBO.Unbind;
  fMovingRow := fMovingRow + 5;
  if fMovingRow > 255 then
    begin
    fMovingRow := 0;
    if (VecLengthNoRoot(Vector(fTmpFineOffsetX, fTmpFineOffsetY) + 128 - fPrevPos * 5) <= 1.1 * VecLengthNoRoot(Vector(fFineOffsetX, fFineOffsetY) + 128 - fPrevPos * 5)) then
      begin
      a := fTempVBO;
      fTempVBO := fFineVBO;
      fFineVBO := a;
      fFineOffsetX := fTmpFineOffsetX;
      fFineOffsetY := fTmpFineOffsetY;
      end;
    calcMotion;
    fTmpFineOffsetX := 4 * Round(Clamp((ModuleManager.ModCamera.ActiveCamera.Position.X + Motion.X) * 5 - 128, 0, Park.pTerrain.SizeX - 256) / 4);
    fTmpFineOffsetY := 4 * Round(Clamp((ModuleManager.ModCamera.ActiveCamera.Position.Z + Motion.Y) * 5 - 128, 0, Park.pTerrain.SizeY - 256) / 4);
    end;
end;

procedure TRTerrain.Render;
var
  i, j: integer;
  showHighest: Boolean;

  function InterpolateHeightMap(X, Y: Single): Single;
  begin
    Result := -1;
    if (Y - fTmpFineOffsetY = 0) or (Y - fTmpFineOffsetY = 256) then
      Result := Mix(Park.pTerrain.HeightMap[0.8 * Floor(X / 4), Y / 5], Park.pTerrain.HeightMap[0.8 * Ceil(X / 4), Y / 5], FPart(X / 4))
    else if (X - fTmpFineOffsetX = 0) or (X - fTmpFineOffsetX = 256) then
      Result := Mix(Park.pTerrain.HeightMap[X / 5, 0.8 * Floor(Y / 4)], Park.pTerrain.HeightMap[X / 5, 0.8 * Ceil(Y / 4)], FPart(Y / 4))
    else
      Result := Park.pTerrain.HeightMap[X / 5, Y / 5];
  end;
begin
  glDisable(GL_BLEND);
  MoveHDTerrain;
  showHighest := (VecLengthNoRoot(Vector(25.6 + fFineOffsetX / 5, 0, 25.6 + fFineOffsetY / 5) - Vector(1, 0, 1) * ModuleManager.ModCamera.ActiveCamera.Position) < (102.4 ** 2));
  fNormalMap.Textures[0].Bind(1);
  fLayerMap.Textures[0].Bind(2);
  fTexture.Bind(0);
  fShader.Bind;
  fShader.UniformF('lightdir', sin(RenderStep), 1, cos(RenderStep));
//   RenderStep := RenderStep + 0.01;
  if showHighest then
    begin
    fShader.UniformF('offset', fFineOffsetX / 5, fFineOffsetY / 5);
    end
  else
    begin
    fShader.UniformF('offset', -1000, -1000);
    end;
  for i := 0 to high(fVBOs) do
    for j := 0 to high(fVBOs[i]) do
      begin
      if VecLengthNoRoot(Vector(102.4 * (i + 0.5), 0, 102.4 * (j + 0.5)) - Vector(1, 0, 1) * ModuleManager.ModCamera.ActiveCamera.Position) < (2.5 * 102.4) ** 2 then
        begin
        fShader.UniformI('LOD', 1);
        fVBOs[i, j].Render;
        end
      else
        begin
        fShader.UniformI('LOD', 0);
        fRawVBOs[i, j].Render;
        end;
      end;
  if showHighest then
    begin
    fShader.UniformI('LOD', 2);
    fFineVBO.Bind;
    fFineVBO.Render;
    fFineVBO.Unbind;
    end;
  fShader.Unbind;
  fTexture.UnBind;
end;

procedure TRTerrain.ApplyChanges(Event: String; Data, Result: Pointer);
var
  i, j, k, l, m, n, o, p: Integer;
  procedure UpdateVertex(X, Y: Word);
  var
    AppropriateVBO: TVBO;
    AppropriateRawVBO: TVBO;
    procedure FindVBO(X, Y: Word);
    begin
      k := x div 512;
      l := y div 512;
      AppropriateVBO := fVBOs[k, l];
      AppropriateRawVBO := fRawVBOs[k, l];
    end;

    function getVertexID(X, Y: Word; Factor: Single): Integer;
    begin
      X := Round((512 / Factor) * FPart(X / Factor / (512 / Factor)));
      Y := Round((512 / Factor) * FPart(Y / Factor / (512 / Factor)));
      Result := Round(4 * (512 / Factor * X + Y));
    end;

    function InterpolateHeightMap(X, Y: Single): Single;
    begin
      Result := -1;
      if (FPart(X / 512) = 0) then
        Result := Mix(Park.pTerrain.HeightMap[X / 5, 16 * Floor(Y / 16) / 5], Park.pTerrain.HeightMap[X / 5, 16 * Ceil(Y / 16) / 5], FPart(Y / 16))
      else if (FPart(Y / 512) = 0) then
        Result := Mix(Park.pTerrain.HeightMap[16 * Floor(X / 16) / 5, Y / 5], Park.pTerrain.HeightMap[16 * Ceil(X / 16) / 5, Y / 5], FPart(X / 16))
      else
        Result := Park.pTerrain.HeightMap[X / 5, Y / 5];
    end;
  var
    Height: TVector3D;
  begin
    Height := Vector(X / 5, InterpolateHeightMap(X, Y), Y / 5);
    if (X >= 0) and (Y >= 0) and (X < Park.pTerrain.SizeX) and (Y < Park.pTerrain.SizeY) then
      begin
      FindVBO(X, Y);
      if (X div 16 = X / 16) and (Y div 16 = Y / 16) then
        begin
        AppropriateRawVBO.Bind;
        AppropriateRawVBO.Vertices[getVertexID(X, Y, 16)] := Height;
        AppropriateRawVBO.UnBind;
        end;
      if (X div 4 = X / 4) and (Y div 4 = Y / 4) then
        begin
        AppropriateVBO.Bind;
        AppropriateVBO.Vertices[getVertexID(X, Y, 4)] := Height;
        AppropriateVBO.UnBind;
        end;
      end;
    if (X > 0) and (Y >= 0) and (X <= Park.pTerrain.SizeX) and (Y < Park.pTerrain.SizeY) then
      begin
      FindVBO(X - 1, Y);
      if (X div 16 = X / 16) and (Y div 16 = Y / 16) then
        begin
        AppropriateRawVBO.Bind;
        AppropriateRawVBO.Vertices[getVertexID(X - 16, Y, 16) + 1] := Height;
        AppropriateRawVBO.UnBind;
        end;
      if (X div 4 = X / 4) and (Y div 4 = Y / 4) then
        begin
        AppropriateVBO.Bind;
        AppropriateVBO.Vertices[getVertexID(X - 4, Y, 4) + 1] := Height;
        AppropriateVBO.UnBind;
        end;
      end;
    if (X > 0) and (Y > 0) and (X <= Park.pTerrain.SizeX) and (Y <= Park.pTerrain.SizeY) then
      begin
      FindVBO(X - 1, Y - 1);
      if (X div 16 = X / 16) and (Y div 16 = Y / 16) then
        begin
        AppropriateRawVBO.Bind;
        AppropriateRawVBO.Vertices[getVertexID(X - 16, Y - 16, 16) + 2] := Height;
        AppropriateRawVBO.UnBind;
        end;
      if (X div 4 = X / 4) and (Y div 4 = Y / 4) then
        begin
        AppropriateVBO.Bind;
        AppropriateVBO.Vertices[getVertexID(X - 4, Y - 4, 4) + 2] := Height;
        AppropriateVBO.UnBind;
        end;
      end;
    if (X >= 0) and (Y > 0) and (X < Park.pTerrain.SizeX) and (Y <= Park.pTerrain.SizeY) then
      begin
      FindVBO(X, Y - 1);
      if (X div 16 = X / 16) and (Y div 16 = Y / 16) then
        begin
        AppropriateRawVBO.Bind;
        AppropriateRawVBO.Vertices[getVertexID(X, Y - 16, 16) + 3] := Height;
        AppropriateRawVBO.UnBind;
        end;
      if (X div 4 = X / 4) and (Y div 4 = Y / 4) then
        begin
        AppropriateVBO.Bind;
        AppropriateVBO.Vertices[getVertexID(X, Y - 4, 4) + 3] := Height;
        AppropriateVBO.UnBind;
        end;
      end;
  end;
var
  Normal: TVector3D;
begin
  if Event = 'TTerrain.Resize' then
    begin
    fShader.UniformF('TerrainSize', Park.pTerrain.SizeX, Park.pTerrain.SizeY);
    if (fLayerMap <> nil) and (fNormalMap <> nil) then
      begin
      fLayerMap.Free;
      fNormalMap.Free;
      end;
    fLayerMap := TFBO.Create(Park.pTerrain.SizeX, Park.pTerrain.SizeY);
    fLayerMap.AddTexture(GL_RGBA, GL_NEAREST, GL_NEAREST);
    fNormalMap := TFBO.Create(Park.pTerrain.SizeX, Park.pTerrain.SizeY);
    fNormalMap.AddTexture(GL_RGB, GL_LINEAR, GL_LINEAR);
    fNormalMap.Unbind;
    m := length(fVBOs);
    if m = 0 then
      n := 0
    else
      n := length(fVBOs[0]);
    k := Park.pTerrain.SizeX div 512;
    l := Park.pTerrain.SizeY div 512;
    SetLength(fNormals, Park.pTerrain.SizeX);
    for i := 0 to high(fNormals) do
      begin
      SetLength(fNormals[i], Park.pTerrain.SizeY);
      for j := 0 to high(fNormals[i]) do
        if (i >= 512 * k) or (j >= 512 * l) then
          fNormals[i, j] := Vector(0, 0, 0);
      end;
    for i := 0 to high(fVBOs) do
      for j := 0 to high(fVBOs[i]) do
        if (i >= k) or (j >= l) then
          fVBOs[i, j].Free;
    setLength(fVBOs, k);
    setLength(fRawVBOs, k);
    for i := 0 to k - 1 do
      begin
      setLength(fVBOs[i], l);
      setLength(fRawVBOs[i], l);
      for j := 0 to l - 1 do
        begin
        if (i >= m) or (j >= n) then
          begin
          fVBOs[i, j] := TVBO.Create(128 * 128 * 4, GL_V3F, GL_QUADS);
          for o := 0 to 127 do
            for p := 0 to 127 do
              begin
              fVBOs[i, j].Vertices[4 * (128 * o + p) + 0] := Vector(0.8 * 128 * i + 0.8 * o + 0.0, Park.pTerrain.HeightMap[0.8 * 128 * i + 0.8 * o + 0.0, 0.8 * 128 * j + 0.8 * p + 0.0], 0.8 * 128 * j + 0.8 * p + 0.0);
              fVBOs[i, j].Vertices[4 * (128 * o + p) + 1] := Vector(0.8 * 128 * i + 0.8 * o + 0.8, Park.pTerrain.HeightMap[0.8 * 128 * i + 0.8 * o + 0.8, 0.8 * 128 * j + 0.8 * p + 0.0], 0.8 * 128 * j + 0.8 * p + 0.0);
              fVBOs[i, j].Vertices[4 * (128 * o + p) + 2] := Vector(0.8 * 128 * i + 0.8 * o + 0.8, Park.pTerrain.HeightMap[0.8 * 128 * i + 0.8 * o + 0.8, 0.8 * 128 * j + 0.8 * p + 0.8], 0.8 * 128 * j + 0.8 * p + 0.8);
              fVBOs[i, j].Vertices[4 * (128 * o + p) + 3] := Vector(0.8 * 128 * i + 0.8 * o + 0.0, Park.pTerrain.HeightMap[0.8 * 128 * i + 0.8 * o + 0.0, 0.8 * 128 * j + 0.8 * p + 0.8], 0.8 * 128 * j + 0.8 * p + 0.8);
              end;
          fVBOs[i, j].UnBind;
          fRawVBOs[i, j] := TVBO.Create(32 * 32 * 4, GL_V3F, GL_QUADS);
          for o := 0 to 31 do
            for p := 0 to 31 do
              begin
              fRawVBOs[i, j].Vertices[4 * (32 * o + p) + 0] := Vector(3.2 * 32 * i + 3.2 * o + 0.0, Park.pTerrain.HeightMap[3.2 * 32 * i + 3.2 * o + 0.0, 3.2 * 32 * j + 3.2 * p + 0.0], 3.2 * 32 * j + 3.2 * p + 0.0);
              fRawVBOs[i, j].Vertices[4 * (32 * o + p) + 1] := Vector(3.2 * 32 * i + 3.2 * o + 3.2, Park.pTerrain.HeightMap[3.2 * 32 * i + 3.2 * o + 3.2, 3.2 * 32 * j + 3.2 * p + 0.0], 3.2 * 32 * j + 3.2 * p + 0.0);
              fRawVBOs[i, j].Vertices[4 * (32 * o + p) + 2] := Vector(3.2 * 32 * i + 3.2 * o + 3.2, Park.pTerrain.HeightMap[3.2 * 32 * i + 3.2 * o + 3.2, 3.2 * 32 * j + 3.2 * p + 3.2], 3.2 * 32 * j + 3.2 * p + 3.2);
              fRawVBOs[i, j].Vertices[4 * (32 * o + p) + 3] := Vector(3.2 * 32 * i + 3.2 * o + 0.0, Park.pTerrain.HeightMap[3.2 * 32 * i + 3.2 * o + 0.0, 3.2 * 32 * j + 3.2 * p + 3.2], 3.2 * 32 * j + 3.2 * p + 3.2);
              end;
          fRawVBOs[i, j].UnBind;
          end;
        end;
      end;
    end;
  if (Data <> nil) and (Event = 'TTerrain.Changed') then
    begin
    i := Word(Data^);
    j := Word(Pointer(PtrUInt(Data) + 2)^);
    UpdateVertex(i, j);
    end;
  if Event = 'TTerrain.ChangedAll' then
    begin
    for i := 0 to Park.pTerrain.SizeX - 1 do
      for j := 0 to Park.pTerrain.SizeY - 1 do
        UpdateVertex(i, j);
    glUseProgram(0);
    glBindTexture(GL_TEXTURE_2D, 0);

    fNormalMap.Bind;
    glMatrixMode(GL_PROJECTION);
    glPushMatrix;
    glLoadIdentity;
    glOrtho(0, Park.pTerrain.SizeX, 0, Park.pTerrain.SizeY, 0, 255);
    glMatrixMode(GL_MODELVIEW);
    glPushMatrix;
    glLoadIdentity;

    glDisable(GL_DEPTH_TEST);
    glBegin(GL_POINTS);
      for i := 0 to Park.pTerrain.SizeX do
        for j := 0 to Park.pTerrain.SizeY do
          begin
          Normal := GetNormal(i, j);
          glColor3f(0.5 + 0.5 * Normal.X, 0.5 + 0.5 * Normal.Y, 0.5 + 0.5 * Normal.Z);
          glVertex3f(i, j, -1);
          end;
    glEnd;
    glEnable(GL_DEPTH_TEST);

    glPopMatrix;
    glMatrixMode(GL_PROJECTION);
    glPopMatrix;
    glMatrixMode(GL_MODELVIEW);
    fNormalMap.Unbind;

    fLayerMap.Bind;
    glClear(GL_COLOR_BUFFER_BIT);
    glMatrixMode(GL_PROJECTION);
    glDisable(GL_BLEND);
    glPushMatrix;
    glLoadIdentity;
    glOrtho(0, Park.pTerrain.SizeX, 0, Park.pTerrain.SizeY, 0, 255);
    glMatrixMode(GL_MODELVIEW);
    glPushMatrix;
    glLoadIdentity;

    glDisable(GL_DEPTH_TEST);
    glBegin(GL_POINTS);
      for i := 0 to Park.pTerrain.SizeX do
        for j := 0 to Park.pTerrain.SizeY do
          begin
          glColor4f(Park.pTerrain.TexMap[i / 5, j / 5] / 8, 0, 0, 1);
          glVertex3f(i, j, -1);
          end;
    glEnd;
    glEnable(GL_DEPTH_TEST);

    glPopMatrix;
    glMatrixMode(GL_PROJECTION);
    glPopMatrix;
    glMatrixMode(GL_MODELVIEW);
    fLayerMap.Unbind;
    end;
end;

constructor TRTerrain.Create;
var
  i, j: Integer;
begin
  fLayerMap := nil;
  fNormalMap := nil;
  fTexture := TTexture.Create;
  fTexture.FromFile('terrain/defaultcollection.tga');
  fShader := TShader.Create('rendereropengl/glsl/terrain/terrain.vs', 'rendereropengl/glsl/terrain/terrain.fs');
  fShader.UniformI('TerrainTexture', 0);
  fShader.UniformI('NormalTexture', 1);
  fShader.UniformI('LayerTexture', 2);
  fShader.UniformF('maxBumpDistance', 40);
  fShader.UniformF('lightdir', -1, 1, -1);
  fFineOffsetX := 0;
  fFineOffsetY := 0;
  fFineVBO := TVBO.Create(256 * 256 * 4, GL_V3F, GL_QUADS);
  for i := 0 to 255 do
    for j := 0 to 255 do
      begin
      fFineVBO.Vertices[4 * (256 * i + j) + 0] := Vector(0.2 * i, 0, 0.2 * j);
      fFineVBO.Vertices[4 * (256 * i + j) + 1] := Vector(0.2 * i + 0.2, 0, 0.2 * j);
      fFineVBO.Vertices[4 * (256 * i + j) + 2] := Vector(0.2 * i + 0.2, 0, 0.2 * j + 0.2);
      fFineVBO.Vertices[4 * (256 * i + j) + 3] := Vector(0.2 * i, 0, 0.2 * j + 0.2);
      end;
  fFineVBO.Unbind;
  fTempVBO := TVBO.Create(256 * 256 * 4, GL_V3F, GL_QUADS);
  for i := 0 to 255 do
    for j := 0 to 255 do
      begin
      fTempVBO.Vertices[4 * (256 * i + j) + 0] := Vector(0.2 * i, 0, 0.2 * j);
      fTempVBO.Vertices[4 * (256 * i + j) + 1] := Vector(0.2 * i + 0.2, 0, 0.2 * j);
      fTempVBO.Vertices[4 * (256 * i + j) + 2] := Vector(0.2 * i + 0.2, 0, 0.2 * j + 0.2);
      fTempVBO.Vertices[4 * (256 * i + j) + 3] := Vector(0.2 * i, 0, 0.2 * j + 0.2);
      end;
  fTempVBO.Unbind;
  fMovingRow := 0;
  EventManager.AddCallback('TTerrain.Resize', @ApplyChanges);
  EventManager.AddCallback('TTerrain.Changed', @ApplyChanges);
  EventManager.AddCallback('TTerrain.ChangedAll', @ApplyChanges);
end;

destructor TRTerrain.Free;
var
  i, j: Integer;
begin
  EventManager.RemoveCallback(@ApplyChanges);
  fFineVBO.Free;
  fTempVBO.Free;
  for i := 0 to high(fVBOs) do
    for j := 0 to high(fVBOs[i]) do
      begin
      fVBOs[i, j].Free;
      fRawVBOs[i, j].Free;
      end;
  fShader.Free;
  fTexture.Free;
  if fNormalMap <> nil then
    fNormalMap.Free;
  if fLayerMap <> nil then
    fLayerMap.Free;
end;

end.