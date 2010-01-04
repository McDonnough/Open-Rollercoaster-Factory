unit m_renderer_class;

interface

uses
  Classes, SysUtils, m_module, g_park;

type
  TModuleRendererClass = class(TBasicModule)
    public
      (**
        * Renders the whole scene
        *)
      procedure RenderScene(Park: TPark); virtual abstract;
    end;

implementation

end.