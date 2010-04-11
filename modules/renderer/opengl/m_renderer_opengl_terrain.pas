unit m_renderer_opengl_terrain;

interface

uses
  SysUtils, Classes, DGLOpenGL, m_renderer_opengl_classes, u_vectors, m_shdmng_class, m_texmng_class, u_math, math;

type
  TRTerrain = class
    protected
      fFineVBO, fGoodVBO, fRawVBO: TVBO;
      fShader: TShader;
      fTexture: TTexture;
      fTmpFineOffsetX, fTmpFineOffsetY: Word;
      fFineOffsetX, fFineOffsetY: Word;
      fPrevPos: TVector2D;
      fHeightMap: TFBO;
      RenderStep: Single;
    public
      procedure Render;
      procedure ApplyChanges(Event: String; Data, Result: Pointer);
      constructor Create;
      destructor Free;
    end;

implementation

uses
  g_park, u_events, m_varlist;

procedure TRTerrain.Render;
  procedure RenderBlock(X, Y: Integer);
  begin
    try
      if (X >= 0) and (Y >= 0) and (X <= Park.pTerrain.SizeX div 256 - 1) and (Y <= Park.pTerrain.SizeY div 256 - 1) then
        begin
        fShader.UniformF('VOffset', 256 * x / 5, 256 * y / 5);
        if VecLengthNoRoot(Vector(256 * x / 5, 0, 256 * y / 5) + Vector(25.6, 0.0, 25.6) - ModuleManager.ModCamera.ActiveCamera.Position * Vector(1, 0, 1)) < 13000 then
          begin
          fShader.UniformI('LOD', 1);
          fGoodVBO.Render;
          end
        else
          begin
          fShader.UniformI('LOD', 0);
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
begin
//   glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
  glDisable(GL_BLEND);
  fFineOffsetX := 4 * Round(Clamp((ModuleManager.ModCamera.ActiveCamera.Position.X) * 5 - 128, 0, Park.pTerrain.SizeX - 256) / 4);
  fFineOffsetY := 4 * Round(Clamp((ModuleManager.ModCamera.ActiveCamera.Position.Z) * 5 - 128, 0, Park.pTerrain.SizeY - 256) / 4);
  fHeightMap.Textures[0].Bind(1);
  fTexture.Bind(0);
  fShader.Bind;
  fShader.UniformF('offset', fFineOffsetX / 5, fFineOffsetY / 5);
//   fShader.UniformF('lightdir', sin(RenderStep), 0.5 + 0.5 * sin(RenderStep), cos(RenderStep));
//   RenderStep := RenderStep + 0.005;
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
  fShader.UniformI('LOD', 2);
  fShader.UniformF('VOffset', fFineOffsetX / 5, fFineOffsetY / 5);
  fFineVBO.Bind;
  fFineVBO.Render;
  fFineVBO.Unbind;
  fShader.Unbind;
  fTexture.UnBind;
  glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
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
begin
  if Event = 'TTerrain.Resize' then
    begin
    fShader.UniformF('TerrainSize', Park.pTerrain.SizeX, Park.pTerrain.SizeY);
    if fHeightMap <> nil then
      fHeightMap.Free;
    fHeightMap := TFBO.Create(Park.pTerrain.SizeX, Park.pTerrain.SizeY, true);
    fHeightMap.AddTexture(GL_RGBA32F, GL_NEAREST, GL_NEAREST);
    fHeightMap.Textures[0].SetClamp(GL_CLAMP, GL_CLAMP);
    fHeightMap.Unbind;
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
    StartUpdate;
    for i := 0 to Park.pTerrain.SizeX do
      for j := 0 to Park.pTerrain.SizeY do
        UpdateVertex(i, j);
    EndUpdate;
    end;
end;

constructor TRTerrain.Create;
var
  i, j: Integer;
begin
  fHeightMap := nil;
  fTexture := TTexture.Create;
  fTexture.FromFile('terrain/defaultcollection.ocg');
  fShader := TShader.Create('rendereropengl/glsl/terrain/terrain.vs', 'rendereropengl/glsl/terrain/terrain.fs');
  fShader.UniformI('TerrainTexture', 0);
  fShader.UniformI('HeightMap', 1);
  fShader.UniformF('maxBumpDistance', 30);
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
  fRawVBO := TVBO.Create(16 * 16 * 4, GL_V3F, GL_QUADS);
  for i := 0 to 15 do
    for j := 0 to 15 do
      begin
      fRawVBO.Vertices[4 * (16 * i + j) + 0] := Vector(0.2 * i, 0, 0.2 * j);
      fRawVBO.Vertices[4 * (16 * i + j) + 1] := Vector(0.2 * i + 0.2, 0, 0.2 * j);
      fRawVBO.Vertices[4 * (16 * i + j) + 2] := Vector(0.2 * i + 0.2, 0, 0.2 * j + 0.2);
      fRawVBO.Vertices[4 * (16 * i + j) + 3] := Vector(0.2 * i, 0, 0.2 * j + 0.2);
      end;
  fRawVBO.Unbind;
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
  fRawVBO.Free;
  fShader.Free;
  fTexture.Free;
  if fHeightMap <> nil then
    fHeightMap.Free;
end;

end.