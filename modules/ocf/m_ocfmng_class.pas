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
        *@param Event to be called when the file has finished loading
        *@param Data that is passed to the "result" parameter of the callback handler
        *)
      procedure RequestOCFFile(FileName, Event: String; AdditionalData: Pointer); virtual abstract;

      (**
        * Call events for loaded files
        *)
      procedure CheckLoaded; virtual abstract;

      (**
        * Get the number of files that have to be loaded
        *)
      function FileCount: Integer; virtual abstract;

      (**
        * Get the number of files that have already been loaded
        *)
      function LoadedFiles: Integer; virtual abstract;

      (**
        * Reload a (changed) OCF file
        *)
      procedure ReloadOCFFile(FileName, Event: String; AdditionalData: Pointer); virtual abstract;

      (**
        * Report if a file is already loaded
        *)
      function FileAlreadyLoaded(FileName: String): Boolean; virtual abstract;
    end;

implementation

end.