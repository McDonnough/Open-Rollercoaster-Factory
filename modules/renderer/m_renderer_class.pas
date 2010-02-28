unit m_renderer_class;

interface

uses
  Classes, SysUtils, m_module, g_park;

type
  TRenderCallback = procedure of object;

  TModuleRendererClass = class(TBasicModule)
    protected
      PostRenderEffects: Array of TRenderCallback;
    public
      procedure RegisterPostRenderEffect(Effect: TRenderCallback);
      procedure ClearPostRenderEffects;

      (**
        * Renders the whole scene
        *)
      procedure RenderScene; virtual abstract;
    end;

implementation

procedure TModuleRendererClass.RegisterPostRenderEffect(Effect: TRenderCallback);
begin
  SetLength(PostRenderEffects, length(PostRenderEffects) + 1);
  PostRenderEffects[high(PostRenderEffects)] := Effect;
end;

procedure TModuleRendererClass.ClearPostRenderEffects;
begin
  SetLength(PostRenderEffects, 0);
end;

end.