unit m_renderer_opengl;

interface

uses
  Classes, SysUtils, m_renderer_class;

type
  TModuleRendererOpenGL = class(TModuleRendererClass)
    public
      procedure RenderScene;
      procedure CheckModConf;
      constructor Create;
    end;

implementation

procedure TModuleRendererOpenGL.RenderScene;
begin
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