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
  DistPixel: DWord;
  Distance: Single;
  ResX, ResY: Integer;
begin
  ModuleManager.ModGLContext.GetResolution(ResX, ResY);
  // Just a test
  glMatrixMode(GL_PROJECTION);
  ModuleManager.ModGLMng.SetUp3DMatrix;
  glMatrixMode(GL_MODELVIEW);

  glDepthMask(true);
  glEnable(GL_DEPTH_TEST);
  glDepthMask(true);

  glEnable(GL_BLEND);

  Render();
  glReadPixels(ModuleManager.ModInputHandler.MouseX, ResY - ModuleManager.ModInputHandler.MouseY, 1, 1, GL_DEPTH_COMPONENT, GL_UNSIGNED_INT, @DistPixel);
  Distance := (DistPixel / High(DWord)) ** 2 * 10000;
  glClear(GL_DEPTH_BUFFER_BIT or GL_COLOR_BUFFER_BIT);
  writeln(FloatToStr(Distance));
  glColorMask(true, false, false, true);
  Render(-0.05, Distance);
  glColorMask(false, true, true, true);
  Render(0.05, Distance);
  glColorMask(true, true, true, true);
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