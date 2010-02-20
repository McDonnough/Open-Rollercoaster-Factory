unit m_renderer_opengl_terrain;

interface

uses
  SysUtils, Classes, DGLOpenGL, m_renderer_opengl_classes, u_vectors, m_shdmng_class, m_texmng_class, u_math, math;

type
  TRTerrain = class
    protected
      fVBO: TVBO;
      fShader: TShader;
    public
      procedure Render;
      procedure PreRenderMap;
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
  Park.pTerrain.Texture.Bind(0);

  glColor4f(1, 1, 1, 1);
  fShader.Bind;
  fVBO.Render;
  fVBO.Unbind;
  fShader.Unbind;
end;

procedure TRTerrain.PreRenderMap;
var
  i, j, k: Integer;
begin
  j := 0;
  k := 0;
  for i := 0 to Round(Park.pTerrain.SizeX / Park.pTerrain.Multiplicator) * Round(Park.pTerrain.SizeY / Park.pTerrain.Multiplicator) - 1 do
    begin
    fVBO.TexCoords[4 * i + 3] := Vector(Park.pTerrain.Multiplicator * j / 16, Park.pTerrain.Multiplicator * k / 32);
    fVBO.Vertices[4 * i + 3] := Vector(Park.pTerrain.Multiplicator * j, Park.pTerrain.HeightMap[Park.pTerrain.Multiplicator * j, Park.pTerrain.Multiplicator * k], Park.pTerrain.Multiplicator * k);
    fVBO.Normals[4 * i + 3] := Vector(0, 1, 0);
    fVBO.Colors[4 * i + 3] := Vector(0, 0, 0, 0);

    fVBO.TexCoords[4 * i + 2] := Vector(Park.pTerrain.Multiplicator * (j + 1) / 16, Park.pTerrain.Multiplicator * k / 32);
    fVBO.Vertices[4 * i + 2] := Vector(Park.pTerrain.Multiplicator * (j + 1), Park.pTerrain.HeightMap[Park.pTerrain.Multiplicator * (j + 1), Park.pTerrain.Multiplicator * k], Park.pTerrain.Multiplicator * k);
    fVBO.Normals[4 * i + 2] := Vector(0, 1, 0);
    fVBO.Colors[4 * i + 2] := Vector(0, 0, 0, 0);

    fVBO.TexCoords[4 * i + 1] := Vector(Park.pTerrain.Multiplicator * (j + 1) / 16, Park.pTerrain.Multiplicator * (k + 1) / 32);
    fVBO.Vertices[4 * i + 1] := Vector(Park.pTerrain.Multiplicator * (j + 1), Park.pTerrain.HeightMap[Park.pTerrain.Multiplicator * (j + 1), Park.pTerrain.Multiplicator * (k + 1)], Park.pTerrain.Multiplicator * (k + 1));
    fVBO.Normals[4 * i + 1] := Vector(0, 1, 0);
    fVBO.Colors[4 * i + 2] := Vector(0, 0, 0, 0);

    fVBO.TexCoords[4 * i] := Vector(Park.pTerrain.Multiplicator * j / 16, Park.pTerrain.Multiplicator * (k + 1) / 32);
    fVBO.Vertices[4 * i] := Vector(Park.pTerrain.Multiplicator * j, Park.pTerrain.HeightMap[Park.pTerrain.Multiplicator * j, Park.pTerrain.Multiplicator * (k + 1)], Park.pTerrain.Multiplicator * (k + 1));
    fVBO.Normals[4 * i] := Vector(0, 1, 0);
    fVBO.Colors[4 * i] := Vector(0, 0, 0, 0);

    inc(j);
    if j = Round(Park.pTerrain.SizeX / Park.pTerrain.Multiplicator) then
      begin
      j := 0;
      inc(k);
      end;
    end;
end;

constructor TRTerrain.Create;
begin
  fShader := TShader.Create('rendereropengl/glsl/terrain/terrain.vs', 'rendereropengl/glsl/terrain/terrain.fs');
  fShader.UniformI('TerrainTexture', 0);

  fVBO := TVBO.Create(Round(Park.pTerrain.SizeX / Park.pTerrain.Multiplicator) * Round(Park.pTerrain.SizeY / Park.pTerrain.Multiplicator) * 4, GL_T2F_C4F_N3F_V3F, GL_QUADS);

  PreRenderMap;
end;

destructor TRTerrain.Free;
begin
  fShader.Free;
  fVBO.Free;
end;

end.