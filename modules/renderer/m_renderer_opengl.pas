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
begin
  // Just a test
  glMatrixMode(GL_PROJECTION);
  ModuleManager.ModGLMng.SetUp3DMatrix;
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
  glDisable(GL_TEXTURE_2D);
  glBegin(GL_QUADS);
    glColor4f(1, 1, 1, 1);
    glVertex3f(0, 0, -5);
    glVertex3f(1, 0, -5);
    glVertex3f(1, 1, -5);
    glVertex3f(0, 1, -5);
  glEnd;
  glEnable(GL_TEXTURE_2D);
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