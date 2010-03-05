unit m_renderer_class;

interface

uses
  Classes, SysUtils, m_module, g_park;

type
  TRenderCallback = procedure of object;

  TModuleRendererClass = class(TBasicModule)
    protected
      RenderEffects: Array of TRenderCallback;
    public
      procedure RegisterRenderEffect(Effect: TRenderCallback);
      procedure ClearRenderEffects;

      (**
        * Renders the whole scene
        *)
      procedure RenderScene; virtual abstract;
    end;

implementation

procedure TModuleRendererClass.RegisterRenderEffect(Effect: TRenderCallback);
begin
  SetLength(RenderEffects, length(RenderEffects) + 1);
  RenderEffects[high(RenderEffects)] := Effect;
end;

procedure TModuleRendererClass.ClearRenderEffects;
begin
  SetLength(RenderEffects, 0);
end;

end.