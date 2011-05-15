unit m_renderer_class;

interface

uses
  Classes, SysUtils, m_module, g_park, u_vectors, m_texmng_class, u_graphics,
  u_files;

type
  TRenderCallback = procedure of object;

  TModuleRendererClass = class(TBasicModule)
    protected
      RenderEffects: Array of TRenderCallback;
      fMouseDistance: Single;
      fSelectionRay, fSelectionStart: TVector3D;
    public
      CaptureNextFrame: Boolean;
      
      property SelectionRay: TVector3D read fSelectionRay;
      property SelectionStart: TVector3D read fSelectionStart;
      property MouseDistance: Single read fMouseDistance;

      (**
        * Loads textures etc
        *)
      procedure PostInit; virtual abstract;

      (**
        * Frees textures etc
        *)
      procedure Unload; virtual abstract;

      (**
        * Renders the whole scene
        *)
      procedure RenderScene; virtual abstract;

      (**
        * Returns TGA image of the rendering
        *)
      function Capture: TByteStream; virtual abstract;
    end;

implementation

end.