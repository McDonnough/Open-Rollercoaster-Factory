unit m_renderer_class;

interface

uses
  Classes, SysUtils, m_module, g_park, u_vectors;

type
  TRenderCallback = procedure of object;

  TModuleRendererClass = class(TBasicModule)
    protected
      RenderEffects: Array of TRenderCallback;
      fMouseDistance: Single;
      fSelectionRay, fSelectionStart: TVector3D;
    public
      property SelectionRay: TVector3D read fSelectionRay;
      property SelectionStart: TVector3D read fSelectionStart;
      property MouseDistance: Single read fMouseDistance;

      (**
        * Renders the whole scene
        *)
      procedure RenderScene; virtual abstract;
    end;

implementation

end.