unit m_renderer_opengl;

interface

uses
  Classes, SysUtils, m_renderer_class, DGLOpenGL, g_park;

type
  TModuleRendererOpenGL = class(TModuleRendererClass)
    public
      procedure RenderScene(Park: TPark);
      procedure CheckModConf;
      constructor Create;
    end;

implementation

uses
  m_varlist;

procedure TModuleRendererOpenGL.RenderScene(Park: TPark);
  procedure ApplyActiveCamera;
  begin
    glRotatef(ModuleManager.ModCamera.ActiveCamera.Rotation.Z, 0, 0, 1);
    glRotatef(ModuleManager.ModCamera.ActiveCamera.Rotation.X, 1, 0, 0);
    glRotatef(ModuleManager.ModCamera.ActiveCamera.Rotation.Y, 0, 1, 0);
    glTranslatef(-ModuleManager.ModCamera.ActiveCamera.Position.X, -ModuleManager.ModCamera.ActiveCamera.Position.Y, -ModuleManager.ModCamera.ActiveCamera.Position.Z);
  end;

  procedure RenderTerrain;
  var
    i, j: Integer;
  begin
    glDisable(GL_TEXTURE_2D);
    glBegin(GL_QUADS);
    glColor4f(1, 1, 1, 1);
    for i := 0 to Park.pTerrain.SizeY - 1 do
      for j := 0 to Park.pTerrain.SizeX - 1 do
        begin
        glVertex3f(i, Park.pTerrain.HeightMap[i, j], j);
        glVertex3f(i + 1, Park.pTerrain.HeightMap[i + 1, j], j);
        glVertex3f(i + 1, Park.pTerrain.HeightMap[i + 1, j + 1], j + 1);
        glVertex3f(i, Park.pTerrain.HeightMap[i, j + 1], j + 1);
        end;
    glEnd;
    glEnable(GL_TEXTURE_2D);
  end;
begin
  // Just a test
  glMatrixMode(GL_PROJECTION);
  ModuleManager.ModGLMng.SetUp3DMatrix;
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  ApplyActiveCamera;

  RenderTerrain;
end;

procedure TModuleRendererOpenGL.CheckModConf;
begin
end;

constructor TModuleRendererOpenGL.Create;
begin
  fModName := 'RendererGL';
  fModType := 'Renderer';
end;

end.