unit m_camera_class;

interface

uses
  Classes, SysUtils, m_module, u_vectors, g_camera;

type
  TModuleCameraClass = class(TBasicModule)
    public
      ActiveCamera: TCamera;

      (**
        * Advance the camera, depending on the user's actions
        *)
      procedure AdvanceActiveCamera; virtual abstract;
    end;

implementation

end.