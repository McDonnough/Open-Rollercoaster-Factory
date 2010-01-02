unit m_ocfmng_class;

interface

uses
  Classes, SysUtils, m_module, l_ocf;

type
  TModuleOCFManagerClass = class(TBasicModule)
    public
      (**
        * Return an OCF file object
        *@param File name to load
        *@param Reset if you do not want the references to be automatically loaded
        *)
      function LoadOCFFile(FileName: String; AutoLoadRef: Boolean = True): TOCFFile; virtual abstract;
    end;

implementation

end.