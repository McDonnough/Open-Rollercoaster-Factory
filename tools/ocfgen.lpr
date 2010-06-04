program ocfgen;

uses
  SysUtils, Classes, g_loader_ocf, u_files, u_xml;

var
  OCF: TOCFFile;
  i: Integer;
  b: TOCFBinarySection;
  Outfile: String;
begin
  OCF := TOCFFile.Create('');
  i := 1;
  while paramstr(i) <> '' do
    begin
    if paramstr(i) = '-o' then
      begin
      inc(i);
      outfile := paramstr(i);
      end
    else if paramstr(i) = '-b' then
      begin
      inc(i);
      b := TOCFBinarySection.Create;
      with ByteStreamFromFile(paramstr(i)) do
        b.Replace(@Data[0], length(Data));
      OCF.AddBinarySection(b);
      end
    else if paramstr(i) = '-x' then
      begin
      inc(i);
      OCF.XML.Document := LoadXMLFile(paramstr(i));
      end;
    inc(i);
    end;
  OCF.SaveTo(Outfile);
  OCF.Free;
end.