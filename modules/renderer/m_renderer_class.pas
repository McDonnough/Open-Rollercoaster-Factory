unit m_renderer_class;

interface

uses
  Classes, SysUtils, m_module, g_park, u_vectors, m_texmng_class;

type
  TRenderCallback = procedure of object;

  TModuleRendererClass = class(TBasicModule)
    protected
      RenderEffects: Array of TRenderCallback;
      fMouseDistance: Single;
      fSelectionRay, fSelectionStart: TVector3D;
      fDistTexture: TTexture;
    public
      property SelectionRay: TVector3D read fSelectionRay;
      property SelectionStart: TVector3D read fSelectionStart;
      property MouseDistance: Single read fMouseDistance;
      property DistTexture: TTexture read fDistTexture;

      (**
        * Renders the whole scene
        *)
      procedure RenderScene; virtual abstract;
    end;

implementation

end.