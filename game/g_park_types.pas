unit g_park_types;

interface

uses
  Classes, SysUtils, l_ocf;

type
  TParkChild = class
    protected
      fLoaded: Boolean;
    public
      procedure WriteOCFSection(var Section: TOCFSection); virtual abstract;
      procedure ReadFromOCFSection(Section: TOCFSection); virtual abstract;
      procedure LoadDefaults; virtual abstract;
      constructor Create;
    end;

implementation

constructor TParkChild.Create;
begin
  fLoaded := false;
end;

end.