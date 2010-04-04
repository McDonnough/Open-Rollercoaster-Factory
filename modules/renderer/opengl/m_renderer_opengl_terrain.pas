unit m_renderer_opengl_terrain;

interface

uses
  SysUtils, Classes, DGLOpenGL, m_renderer_opengl_classes, u_vectors, m_shdmng_class, m_texmng_class, u_math, math;

type
  TRTerrain = class
    protected
      fFineVBO, fGoodVBO: TVBO;
      fShader: TShader;
      fTexture: TTexture;
      fTmpFineOffsetX, fTmpFineOffsetY: Word;
      fFineOffsetX, fFineOffsetY: Word;
      fMovingRow: Integer;
      fMVec: Array[0..4] of TVector2D;
      fPrevPos: TVector2D;
      fNormals: Array of Array of TVector3D;
      fHeightMap: TFBO;
      RenderStep: Single;
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

procedure TRTerrain.Render;
var
  i, j: integer;
  showHighest: Boolean;
begin
  glDisable(GL_BLEND);
  fFineOffsetX := 4 * Round(Clamp((ModuleManager.ModCamera.ActiveCamera.Position.X) * 5 - 128, 0, Park.pTerrain.SizeX - 256) / 4);
  fFineOffsetY := 4 * Round(Clamp((ModuleManager.ModCamera.ActiveCamera.Position.Z) * 5 - 128, 0, Park.pTerrain.SizeY - 256) / 4);
  showHighest := (VecLengthNoRoot(Vector(25.6 + fFineOffsetX / 5, 0, 25.6 + fFineOffsetY / 5) - Vector(1, 0, 1) * ModuleManager.ModCamera.ActiveCamera.Position) < (102.4 ** 2));
  fHeightMap.Textures[0].Bind(1);
  fTexture.Bind(0);
  fShader.Bind;
  fShader.UniformF('offset', fFineOffsetX / 5, fFineOffsetY / 5);
  fShader.UniformF('lightdir', sin(RenderStep), 1, cos(RenderStep));
  fShader.UniformI('LOD', 1);
  for i := 0 to Park.pTerrain.SizeX div 256 - 1 do
    for j := 0 to Park.pTerrain.SizeY div 256 - 1 do
      begin
      fShader.UniformF('VOffset', 256 * i / 5, 256 * j / 5);
      fGoodVBO.Render;
      end;
  fShader.UniformI('LOD', 2);
  fShader.UniformF('VOffset', fFineOffsetX / 5, fFineOffsetY / 5);
  fFineVBO.Bind;
  fFineVBO.Render;
  fFineVBO.Unbind;
  fShader.Unbind;
  fTexture.UnBind;
end;

procedure TRTerrain.ApplyChanges(Event: String; Data, Result: Pointer);
var
  i, j, k, l, m, n, o, p: Integer;
  procedure UpdateVertex(X, Y: Word);
  begin
  end;
var
  Normal: TVector3D;
begin
  if Event = 'TTerrain.Resize' then
    begin
    fShader.UniformF('TerrainSize', Park.pTerrain.SizeX, Park.pTerrain.SizeY);
    if fHeightMap <> nil then
      fHeightMap.Free;
    fHeightMap := TFBO.Create(Park.pTerrain.SizeX, Park.pTerrain.SizeY);
    fHeightMap.AddTexture(GL_RGBA32F, GL_NEAREST, GL_NEAREST);
    fHeightMap.Unbind;
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

    fHeightMap.Bind;
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
          Normal := GetNormal(i, j);
          glColor4f(Park.pTerrain.TexMap[i / 5, j / 5] / 8, 0.0, 0.0, Park.pTerrain.HeightMap[i / 5, j / 5] / 256);
          glVertex3f(i, j, -1);
          end;
    glEnd;
    glEnable(GL_DEPTH_TEST);

    glPopMatrix;
    glMatrixMode(GL_PROJECTION);
    glPopMatrix;
    glMatrixMode(GL_MODELVIEW);
    fHeightMap.Unbind;
    end;
end;

constructor TRTerrain.Create;
var
  i, j: Integer;
begin
  fHeightMap := nil;
  fTexture := TTexture.Create;
  fTexture.FromFile('terrain/defaultcollection.tga');
  fShader := TShader.Create('rendereropengl/glsl/terrain/terrain.vs', 'rendereropengl/glsl/terrain/terrain.fs');
  fShader.UniformI('TerrainTexture', 0);
  fShader.UniformI('HeightMap', 1);
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
  fGoodVBO := TVBO.Create(64 * 64 * 4, GL_V3F, GL_QUADS);
  for i := 0 to 63 do
    for j := 0 to 63 do
      begin
      fGoodVBO.Vertices[4 * (64 * i + j) + 0] := Vector(0.2 * i, 0, 0.2 * j);
      fGoodVBO.Vertices[4 * (64 * i + j) + 1] := Vector(0.2 * i + 0.2, 0, 0.2 * j);
      fGoodVBO.Vertices[4 * (64 * i + j) + 2] := Vector(0.2 * i + 0.2, 0, 0.2 * j + 0.2);
      fGoodVBO.Vertices[4 * (64 * i + j) + 3] := Vector(0.2 * i, 0, 0.2 * j + 0.2);
      end;
  fGoodVBO.Unbind;
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
  fGoodVBO.Free;
  fShader.Free;
  fTexture.Free;
  if fHeightMap <> nil then
    fHeightMap.Free;
end;

end.