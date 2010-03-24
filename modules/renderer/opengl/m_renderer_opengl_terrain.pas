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
      procedure MoveHDTerrain;
    public
      procedure Render;
      procedure ApplyChanges(Event: String; Data, Result: Pointer);
      constructor Create;
      destructor Free;
    end;

implementation

uses
  g_park, u_events, m_varlist;

procedure TRTerrain.MoveHDTerrain;
var
  i, j: Integer;
  a: TVBO;
  Motion: TVector2D;
  tmpHeight: Single;

  procedure CalcMotion;
  begin
    Motion := (fMVec[0] + fMVec[1] + fMVec[2] + fMVec[3] + fMVec[4]) / 5 * 78;
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
      fTempVBO.Vertices[4 * (256 * i + j) + 0] := Vector(0.2 * i, Park.pTerrain.HeightMap[0.2 * (i + fTmpFineOffsetX), 0.2 * (j + fTmpFineOffsetY)], 0.2 * j);
      fTempVBO.Vertices[4 * (256 * i + j) + 1] := Vector(0.2 * i + 0.2, Park.pTerrain.HeightMap[0.2 * (i + fTmpFineOffsetX + 1), 0.2 * (j + fTmpFineOffsetY)], 0.2 * j);
      fTempVBO.Vertices[4 * (256 * i + j) + 2] := Vector(0.2 * i + 0.2, Park.pTerrain.HeightMap[0.2 * (i + fTmpFineOffsetX + 1), 0.2 * (j + fTmpFineOffsetY + 1)], 0.2 * j + 0.2);
      fTempVBO.Vertices[4 * (256 * i + j) + 3] := Vector(0.2 * i, Park.pTerrain.HeightMap[0.2 * (i + fTmpFineOffsetX), 0.2 * (j + fTmpFineOffsetY + 1)], 0.2 * j + 0.2);
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
    fTmpFineOffsetX := Round(Clamp((ModuleManager.ModCamera.ActiveCamera.Position.X + Motion.X) * 5 - 128, 0, Park.pTerrain.SizeX - 256));
    fTmpFineOffsetY := Round(Clamp((ModuleManager.ModCamera.ActiveCamera.Position.Z + Motion.Y) * 5 - 128, 0, Park.pTerrain.SizeY - 256));
    end;
end;

procedure TRTerrain.Render;
var
  i, j: integer;
begin
  MoveHDTerrain;
//   glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
  fTexture.Bind(0);
  fShader.Bind;
  fShader.UniformF('offset', fFineOffsetX / 5, fFineOffsetY / 5);
  fShader.UniformI('HighLOD', 0);
  for i := 0 to high(fVBOs) do
    for j := 0 to high(fVBOs[i]) do
      begin
      if VecLengthNoRoot(Vector(102.4 * (i + 0.5), 0, 102.4 * (j + 0.5)) - Vector(1, 0, 1) * ModuleManager.ModCamera.ActiveCamera.Position) < (2.5 * 102.4) ** 2 then
        fVBOs[i, j].Render
      else
        fRawVBOs[i, j].Render;
      end;
  fShader.UniformI('HighLOD', 1);
  fFineVBO.Bind;
  fFineVBO.Render;
  fFineVBO.Unbind;
  fShader.Unbind;
  fTexture.UnBind;
  glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
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
  var
    Height: TVector3D;
  begin
    Height := Vector(X / 5, Park.pTerrain.HeightMap[X / 5, Y / 5], Y / 5);
{    fFineVBO.Bind;
    if (X - fFineOffsetX >= 0) and (Y - fFineOffsetY >= 0) and (X - fFineOffsetX < 512) and (Y - fFineOffsetY < 512) then
      fFineVBO.Vertices[getVertexID(X - fFineOffsetX, Y - fFineOffsetY, 1)]               := Vector((X - fFineOffsetX) / 5, Height.Y, (Y - fFineOffsetY) / 5);
    if (X - fFineOffsetX > 0) and (Y - fFineOffsetY >= 0) and (X - fFineOffsetX <= 512) and (Y - fFineOffsetY < 512) then
      fFineVBO.Vertices[getVertexID(X - fFineOffsetX - 1, Y - fFineOffsetY, 1) + 1]       := Vector((X - fFineOffsetX) / 5, Height.Y, (Y - fFineOffsetY) / 5);
    if (X - fFineOffsetX > 0) and (Y - fFineOffsetY > 0) and (X - fFineOffsetX <= 512) and (Y - fFineOffsetY <= 512) then
      fFineVBO.Vertices[getVertexID(X - fFineOffsetX - 1, Y - fFineOffsetY - 1, 1) + 2]   := Vector((X - fFineOffsetX) / 5, Height.Y, (Y - fFineOffsetY) / 5);
    if (X - fFineOffsetX >= 0) and (Y - fFineOffsetY > 0) and (X - fFineOffsetX < 512) and (Y - fFineOffsetY <= 512) then
      fFineVBO.Vertices[getVertexID(X - fFineOffsetX, Y - fFineOffsetY - 1, 1) + 3]       := Vector((X - fFineOffsetX) / 5, Height.Y, (Y - fFineOffsetY) / 5);
    fFineVBO.Unbind;}
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
begin
  if (Event = 'TTerrain.Resize') or (Event = 'TTerrain.ChangedAll') then
    begin
    m := length(fVBOs);
    if m = 0 then
      n := 0
    else
      n := length(fVBOs[0]);
    k := Park.pTerrain.SizeX div 512;
    l := Park.pTerrain.SizeY div 512;
    for i := 0 to high(fVBOs) do
      for j := 0 to high(fVBOs[i]) do
        if (i >= k) or (j >= l) or (Event = 'TTerrain.ChangedAll') then
          fVBOs[i, j].Free;
    setLength(fVBOs, k);
    setLength(fRawVBOs, k);
    for i := 0 to k - 1 do
      begin
      setLength(fVBOs[i], l);
      setLength(fRawVBOs[i], l);
      for j := 0 to l - 1 do
        begin
        if (i >= m) or (j >= n) or (Event = 'TTerrain.ChangedAll') then
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
end;

constructor TRTerrain.Create;
var
  i, j: Integer;
begin
  fTexture := TTexture.Create;
  fTexture.FromFile('data/terrain/defaultcollection.tga');
  fShader := TShader.Create('rendereropengl/glsl/terrain/terrain.vs', 'rendereropengl/glsl/terrain/terrain.fs');
  fShader.UniformI('heightmap', 0);
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
end;

end.