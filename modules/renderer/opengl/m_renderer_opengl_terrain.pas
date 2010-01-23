unit m_renderer_opengl_terrain;

interface

uses
  SysUtils, Classes, DGLOpenGL, m_renderer_opengl_classes, u_vectors, m_shdmng_class, m_texmng_class, u_math, math;

type
  TRTerrain = class
    protected
      fVBO: TVBO;
      fHeightMap: TTexture;
      fShader: TShader;
    public
      procedure Render;
      constructor Create;
      destructor Free;
    end;

implementation

uses
  g_park;

procedure TRTerrain.Render;
var
  i, j: Integer;
begin
  fHeightMap.Bind(1);
  Park.pTerrain.Texture.Bind(0);

  glColor4f(1, 1, 1, 1);
  fShader.Bind;
  fVBO.Render;
  fVBO.Unbind;
  fShader.Unbind;
end;

constructor TRTerrain.Create;
var
  i, j, k: Integer;
  hm: array of DWord;
begin
  fShader := TShader.Create('rendereropengl/glsl/terrain/terrain.vs', 'rendereropengl/glsl/terrain/terrain.fs');
  fShader.UniformI('TerrainTexture', 0);
  fShader.UniformI('HeightMap', 1);
  fShader.UniformF('TerrainSize', Park.pTerrain.SizeX, Park.pTerrain.SizeY);

  fHeightMap := TTexture.Create;
  fHeightMap.SetClamp(GL_CLAMP, GL_CLAMP);
  fHeightMap.CreateNew(Park.pTerrain.SizeX + 1, Park.pTerrain.SizeY + 1, GL_RGBA32F_ARB);

  fVBO := TVBO.Create(Park.pTerrain.SizeX * Park.pTerrain.SizeY * 4, GL_T2F_C4F_N3F_V3F, GL_QUADS);
  j := 0;
  k := 0;
  setlength(hm, (Park.pTerrain.SizeX + 1) * (Park.pTerrain.SizeY + 1));
  for i := 0 to Park.pTerrain.SizeX * Park.pTerrain.SizeY - 1 do
    begin
    fVBO.TexCoords[4 * i] := Vector(j / 16, k / 32);
    fVBO.Vertices[4 * i] := Vector(j, 0, k);
    fVBO.Normals[4 * i] := Vector(0, 1, 0);
    fVBO.Colors[4 * i] := Vector(0, 0, 0, 0);

    fVBO.TexCoords[4 * i + 1] := Vector((j + 1) / 16, k / 32);
    fVBO.Vertices[4 * i + 1] := Vector(j + 1, 0, k);
    fVBO.Normals[4 * i + 1] := Vector(0, 1, 0);
    fVBO.Colors[4 * i + 1] := Vector(0, 0, 0, 0);

    fVBO.TexCoords[4 * i + 2] := Vector((j + 1) / 16, (k + 1) / 32);
    fVBO.Vertices[4 * i + 2] := Vector(j + 1, 0, k + 1);
    fVBO.Normals[4 * i + 2] := Vector(0, 1, 0);
    fVBO.Colors[4 * i + 2] := Vector(0, 0, 0, 0);

    fVBO.TexCoords[4 * i + 3] := Vector(j / 16, (k + 1) / 32);
    fVBO.Vertices[4 * i + 3] := Vector(j, 0, k + 1);
    fVBO.Normals[4 * i + 3] := Vector(0, 1, 0);
    fVBO.Colors[4 * i + 3] := Vector(0, 0, 0, 0);

    inc(j);
    if j = Park.pTerrain.SizeX then
      begin
      j := 0;
      inc(k);
      end;
    end;

  j := 0;
  k := 0;
  hm[0] := 2048;
  for i := 1 to high(hm) do
    begin
    hm[i] := Round(256 * Park.pTerrain.HeightMap[j, k]);
    inc(j);
    if j = Park.pTerrain.SizeX then
      begin
      j := 0;
      inc(k);
      end;
    end;

  fHeightMap.Fill(@hm[0], GL_RGBA);
end;

destructor TRTerrain.Free;
begin
  fHeightMap.Free;
  fShader.Free;
  fVBO.Free;
end;

end.