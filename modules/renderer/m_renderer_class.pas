unit m_renderer_class;

interface

uses
  Classes, SysUtils, m_module, g_park;

type
  TRenderCallback = procedure of object;

  TModuleRendererClass = class(TBasicModule)
    protected
      RenderEffects: Array of TRenderCallback;
      fMouseDistance: Single;
    public
      property MouseDistance: Single read fMouseDistance;

      (**
        * Renders the whole scene
        *)
      procedure RenderScene; virtual abstract;
    end;

implementation

end.