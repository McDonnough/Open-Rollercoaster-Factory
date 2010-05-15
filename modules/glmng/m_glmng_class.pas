unit m_glmng_class;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_module;

type
  TModuleGLMngClass = class(TBasicModule)
    public
      (**
        * Create glortho matrix
        *)
      procedure SetUp2DMatrix; virtual abstract;

      (**
        * Create gluPerspective matrix
        *)
      procedure SetUp3DMatrix; virtual abstract;

      (**
        * Create identity matrix
        *)
      procedure SetUpIdentityMatrix; virtual abstract;

      (**
        * Clear buffers
        *)
      procedure SetUpScreen; virtual abstract;
    end;

implementation

end.

