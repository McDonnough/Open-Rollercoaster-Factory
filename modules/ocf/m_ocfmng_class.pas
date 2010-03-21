unit m_ocfmng_class;

interface

uses
  Classes, SysUtils, m_module, u_dom;

type
  TModuleOCFManagerClass = class(TBasicModule)
    public
      (**
        * Return an OCF file object
        *@param File name to load
        *@param Reset if you do not want the references to be automatically loaded
        *)
      function LoadOCFFile(FileName: String): TDOMDocument; virtual abstract;
    end;

implementation

end.