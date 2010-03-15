unit u_xml;

interface

uses
  SysUtils, Classes, u_dom;

function LoadXMLFile(FName: String): TDOMDocument;

implementation

function LoadXMLFile(FName: String): TDOMDocument;
var
  Source: String;


  function IsWhitespace(C: Char): Boolean;
  begin
    Result := C in [' ', #10, #13, #9];
  end;
begin
  with TFileStream.Create(FName, fmOpenRead) do
    begin
    SetLength(Source, Size);
    Read(Source[1], Size);
    Free;
    end;
end;

end.