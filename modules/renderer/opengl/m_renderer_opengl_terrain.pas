unit m_renderer_opengl_terrain;

interface

uses
  SysUtils, Classes, DGLOpenGL, m_renderer_opengl_classes, u_vectors;

type
  TRTerrain = class
    protected
      VBO: TVBO;
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
  glDisable(GL_TEXTURE_2D);
//   glBegin(GL_QUADS);
  glColor4f(1, 1, 1, 1);
{  for i := 0 to Park.pTerrain.SizeY - 1 do
    for j := 0 to Park.pTerrain.SizeX - 1 do
      begin
      glVertex3f(i, Park.pTerrain.HeightMap[i, j], j);
      glVertex3f(i + 1, Park.pTerrain.HeightMap[i + 1, j], j);
      glVertex3f(i + 1, Park.pTerrain.HeightMap[i + 1, j + 1], j + 1);
      glVertex3f(i, Park.pTerrain.HeightMap[i, j + 1], j + 1);
      end;
  glEnd;}
  VBO.Bind;
  VBO.Render;
  VBO.Unbind;
  glEnable(GL_TEXTURE_2D);
end;

constructor TRTerrain.Create;
var
  i, j, k: Integer;
begin
  VBO := TVBO.Create(128 * 128 * 4, GL_T2F_N3F_V3F, GL_QUADS);
  j := 0;
  k := 0;
  for i := 0 to 128 * 128 - 1 do
    begin
    VBO.TexCoords[4 * i] := Vector(0, 0);
    VBO.Vertices[4 * i] := Vector(j, 0, k);
    VBO.Normals[4 * i] := Vector(0, 1, 0);

    VBO.TexCoords[4 * i + 1] := Vector(0, 0);
    VBO.Vertices[4 * i + 1] := Vector(j + 1, 0, k);
    VBO.Normals[4 * i + 1] := Vector(0, 1, 0);

    VBO.TexCoords[4 * i + 2] := Vector(0, 0);
    VBO.Vertices[4 * i + 2] := Vector(j + 1, 0, k + 1);
    VBO.Normals[4 * i + 2] := Vector(0, 1, 0);

    VBO.TexCoords[4 * i + 3] := Vector(0, 0);
    VBO.Vertices[4 * i + 3] := Vector(j, 0, k + 1);
    VBO.Normals[4 * i + 3] := Vector(0, 1, 0);

    inc(j);
    if j = 128 then
      begin
      j := 0;
      inc(k);
      end;
    end;
  writeln(VBO.Vertices[128*128*4-1].Z);
end;

destructor TRTerrain.Free;
begin
  VBO.Free;
end;

end.