unit m_renderer_opengl;

interface

uses
  Classes, SysUtils, m_renderer_class, DGLOpenGL, g_park, u_math, u_vectors,
  m_renderer_opengl_camera, m_renderer_opengl_terrain;

type
  TModuleRendererOpenGL = class(TModuleRendererClass)
    protected
      RCamera: TRCamera;
      RTerrain: TRTerrain;
    public
      procedure PostInit;
      procedure Unload;
      procedure RenderScene;
      procedure CheckModConf;
      constructor Create;
    end;

implementation

uses
  m_varlist;

procedure TModuleRendererOpenGL.PostInit;
begin
  RCamera := TRCamera.Create;
  RTerrain := TRTerrain.Create;
end;

procedure TModuleRendererOpenGL.Unload;
begin
  RTerrain.Free;
  RCamera.Free;
end;

procedure TModuleRendererOpenGL.RenderScene;
begin
  // Just a test
  glMatrixMode(GL_PROJECTION);
  ModuleManager.ModGLMng.SetUp3DMatrix;
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;

  RCamera.ApplyRotation(Vector(1, 1, 1));
  RCamera.ApplyTransformation(Vector(1, 1, 1));

  glDepthMask(true);
  glEnable(GL_DEPTH_TEST);

  glEnable(GL_BLEND);
  RTerrain.Render;
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