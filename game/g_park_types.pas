unit g_park_types;

interface

uses
  Classes, SysUtils, l_ocf;

type
  TParkChild = class
    public
      procedure WriteOCFSection(var Section: TOCFSection); virtual abstract;
      procedure ReadFromOCFSection(Section: TOCFSection); virtual abstract;
    end;

implementation

end.