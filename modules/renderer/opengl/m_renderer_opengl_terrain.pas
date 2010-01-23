unit m_renderer_opengl_terrain;

interface

uses
  SysUtils, Classes, DGLOpenGL, m_renderer_opengl_classes, u_vectors, m_shdmng_class;

type
  TRTerrain = class
    protected
      fVBO: TVBO;
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
  Park.pTerrain.Texture.Bind;
  glColor4f(1, 1, 1, 1);
  fVBO.Render;
  fVBO.Unbind;
end;

constructor TRTerrain.Create;
var
  i, j, k: Integer;
begin
  fVBO := TVBO.Create(Park.pTerrain.SizeX * Park.pTerrain.SizeY * 4, GL_T2F_N3F_V3F, GL_QUADS);
  j := 0;
  k := 0;
  for i := 0 to Park.pTerrain.SizeX * Park.pTerrain.SizeY - 1 do
    begin
    fVBO.TexCoords[4 * i] := Vector(0, 0);
    fVBO.Vertices[4 * i] := Vector(j, Park.pTerrain.HeightMap[j, k], k);
    fVBO.Normals[4 * i] := Vector(0, 1, 0);

    fVBO.TexCoords[4 * i + 1] := Vector(1 / 4, 0);
    fVBO.Vertices[4 * i + 1] := Vector(j + 1, Park.pTerrain.HeightMap[j + 1, k], k);
    fVBO.Normals[4 * i + 1] := Vector(0, 1, 0);

    fVBO.TexCoords[4 * i + 2] := Vector(1 / 4, 1 / 4);
    fVBO.Vertices[4 * i + 2] := Vector(j + 1, Park.pTerrain.HeightMap[j + 1, k + 1], k + 1);
    fVBO.Normals[4 * i + 2] := Vector(0, 1, 0);

    fVBO.TexCoords[4 * i + 3] := Vector(0, 1 / 4);
    fVBO.Vertices[4 * i + 3] := Vector(j, Park.pTerrain.HeightMap[j, k + 1], k + 1);
    fVBO.Normals[4 * i + 3] := Vector(0, 1, 0);

    inc(j);
    if j = Park.pTerrain.SizeX then
      begin
      j := 0;
      inc(k);
      end;
    end;
end;

destructor TRTerrain.Free;
begin
  fVBO.Free;
end;

end.