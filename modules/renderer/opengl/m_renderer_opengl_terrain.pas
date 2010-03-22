unit m_renderer_opengl_terrain;

interface

uses
  SysUtils, Classes, DGLOpenGL, m_renderer_opengl_classes, u_vectors, m_shdmng_class, m_texmng_class, u_math, math;

type
  TRTerrain = class
    protected
      fVBOs: Array of Array of TVBO;
      fRawVBOs: Array of Array of TVBO;
      fFineVBO: TVBO;
      fShader: TShader;
      fTexture: TTexture;
    public
      procedure Render;
      procedure ApplyChanges(Event: String; Data, Result: Pointer);
      constructor Create;
      destructor Free;
    end;

implementation

uses
  g_park, u_events;

procedure TRTerrain.Render;
var
  i, j: integer;
begin
  fTexture.Bind(0);
  fShader.Bind;
  fShader.UniformF('offset', 0, 0);
  for i := 0 to high(fRawVBOs) do
    for j := 0 to high(fRawVBOs[i]) do
      fRawVBOs[i, j].Render;
  fShader.Unbind;
  fTexture.UnBind;
end;

procedure TRTerrain.ApplyChanges(Event: String; Data, Result: Pointer);
var
  i, j, k, l, m, n, o, p: Integer;
begin
  if Event = 'TTerrain.Resize' then
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
          fVBOs[i, j] := TVBO.Create(64 * 64 * 4, GL_V3F, GL_QUADS);
          for o := 0 to 63 do
            for p := 0 to 63 do
              begin
              fVBOs[i, j].Vertices[4 * (64 * o + p) + 0] := Vector(0.8 * 64 * i + 0.8 * o + 0.0, Park.pTerrain.HeightMap[0.8 * 64 * i + 0.8 * o + 0.0, 0.8 * 64 * j + 0.8 * p + 0.0], 0.8 * 64 * j + 0.8 * p + 0.0);
              fVBOs[i, j].Vertices[4 * (64 * o + p) + 1] := Vector(0.8 * 64 * i + 0.8 * o + 0.8, Park.pTerrain.HeightMap[0.8 * 64 * i + 0.8 * o + 0.8, 0.8 * 64 * j + 0.8 * p + 0.0], 0.8 * 64 * j + 0.8 * p + 0.0);
              fVBOs[i, j].Vertices[4 * (64 * o + p) + 2] := Vector(0.8 * 64 * i + 0.8 * o + 0.8, Park.pTerrain.HeightMap[0.8 * 64 * i + 0.8 * o + 0.8, 0.8 * 64 * j + 0.8 * p + 0.8], 0.8 * 64 * j + 0.8 * p + 0.8);
              fVBOs[i, j].Vertices[4 * (64 * o + p) + 3] := Vector(0.8 * 64 * i + 0.8 * o + 0.0, Park.pTerrain.HeightMap[0.8 * 64 * i + 0.8 * o + 0.0, 0.8 * 64 * j + 0.8 * p + 0.8], 0.8 * 64 * j + 0.8 * p + 0.8);
              end;
          fVBOs[i, j].UnBind;
          fRawVBOs[i, j] := TVBO.Create(16 * 16 * 4, GL_V3F, GL_QUADS);
          for o := 0 to 15 do
            for p := 0 to 15 do
              begin
              fRawVBOs[i, j].Vertices[4 * (16 * o + p) + 0] := Vector(0.8 * 64 * i + 3.2 * o + 0.0, Park.pTerrain.HeightMap[0.8 * 64 * i + 3.2 * o + 0.0, 0.8 * 64 * j + 3.2 * p + 0.0], 0.8 * 64 * j + 3.2 * p + 0.0);
              fRawVBOs[i, j].Vertices[4 * (16 * o + p) + 1] := Vector(0.8 * 64 * i + 3.2 * o + 3.2, Park.pTerrain.HeightMap[0.8 * 64 * i + 3.2 * o + 3.2, 0.8 * 64 * j + 3.2 * p + 0.0], 0.8 * 64 * j + 3.2 * p + 0.0);
              fRawVBOs[i, j].Vertices[4 * (16 * o + p) + 2] := Vector(0.8 * 64 * i + 3.2 * o + 3.2, Park.pTerrain.HeightMap[0.8 * 64 * i + 3.2 * o + 3.2, 0.8 * 64 * j + 3.2 * p + 3.2], 0.8 * 64 * j + 3.2 * p + 3.2);
              fRawVBOs[i, j].Vertices[4 * (16 * o + p) + 3] := Vector(0.8 * 64 * i + 3.2 * o + 0.0, Park.pTerrain.HeightMap[0.8 * 64 * i + 3.2 * o + 0.0, 0.8 * 64 * j + 3.2 * p + 3.2], 0.8 * 64 * j + 3.2 * p + 3.2);
              end;
          fRawVBOs[i, j].UnBind;
          end;
        end;
      end;
    end;
  if (Data <> nil) and (Event = 'TTerrain.Changed') then
    begin
    i := Word(Data^);
    j := Word((Data + 2)^);
    k := i div 512;
    l := j div 512;
    m := i - 512 * k;
    n := j - 512 * l;
    if (i div 16 = i / 16) and (j div 16 = j / 16) then
      begin
      fRawVBOs[k, l].Bind;
      fRawVBOs[k, l].Vertices[4 * (16 * m div 16 + n div 16) + 0] := Vector(i / 5, Park.pTerrain.HeightMap[i / 5, j / 5], j / 5);
      fRawVBOs[k, l].Unbind;
      end;
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
  fFineVBO := TVBO.Create(512 * 512 * 4, GL_V3F, GL_QUADS);
  for i := 0 to 511 do
    for j := 0 to 511 do
      begin
      fFineVBO.Vertices[4 * (512 * i + j) + 0] := Vector(0.2 * i, 0, 0.2 * j);
      fFineVBO.Vertices[4 * (512 * i + j) + 1] := Vector(0.2 * i + 0.2, 0, 0.2 * j);
      fFineVBO.Vertices[4 * (512 * i + j) + 2] := Vector(0.2 * i + 0.2, 0, 0.2 * j + 0.2);
      fFineVBO.Vertices[4 * (512 * i + j) + 3] := Vector(0.2 * i, 0, 0.2 * j + 0.2);
      end;
  EventManager.AddCallback('TTerrain.Resize', @ApplyChanges);
  EventManager.AddCallback('TTerrain.Changed', @ApplyChanges);
end;

destructor TRTerrain.Free;
var
  i, j: Integer;
begin
  EventManager.RemoveCallback(@ApplyChanges);
  fFineVBO.Free;
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