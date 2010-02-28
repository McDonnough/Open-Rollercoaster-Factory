unit m_renderer_opengl;

interface

uses
  Classes, SysUtils, m_renderer_class, DGLOpenGL, g_park, u_math, u_vectors,
  m_renderer_opengl_camera, m_renderer_opengl_terrain, math;

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
  procedure Render(EyeMode: Single = 0; EyeFocus: Single = 10);
  begin
    glClear(GL_DEPTH_BUFFER_BIT);
    glLoadIdentity;
    glRotatef(RadToDeg(arctan(EyeMode / EyeFocus)), 0, 1, 0);
    glTranslatef(EyeMode, 0, 0);
    RCamera.ApplyRotation(Vector(1, 1, 1));
    RCamera.ApplyTransformation(Vector(1, 1, 1));

    RTerrain.Render;
  end;

var
  DistPixel: TVector4D;
  ResX, ResY: Integer;
begin
  // Just a test
  glMatrixMode(GL_PROJECTION);
  ModuleManager.ModGLMng.SetUp3DMatrix;
  glMatrixMode(GL_MODELVIEW);

  glDepthMask(true);
  glEnable(GL_DEPTH_TEST);

  glEnable(GL_BLEND);

  ModuleManager.ModGLContext.GetResolution(ResX, ResY);
  Render();
  glReadPixels(ModuleManager.ModInputHandler.MouseX, ResY - ModuleManager.ModInputHandler.MouseY, 1, 1, GL_RGBA, GL_FLOAT, @DistPixel);
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
  Render();
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