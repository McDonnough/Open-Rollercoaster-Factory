program texconf;

uses
  SysUtils, Classes, u_graphics, u_files;

var
  infile, outfile: String;
  tempTex: TTexImage;
  tmpStream: TByteStream;
  i: integer;
begin
  i := 1;
  while paramstr(i) <> '' do
    begin
    if paramstr(i) = '-i' then
      begin
      inc(i);
      infile := paramstr(i);
      end
    else if paramstr(i) = '-o' then
      begin
      inc(i);
      outfile := paramstr(i);
      end;
    inc(i);
    end;
  writeln('Loading stream');
  tmpStream := ByteStreamFromFile(infile);
  writeln('Creating texture object');
  if ExtractFileExt(Infile) = '.tga' then
    tempTex := TexFromTGA(tmpStream)
  else if ExtractFileExt(Infile) = '.dbcg' then
    tempTex := TexFromDBCG(tmpStream)
  else
    begin
    writeln('Invalid input format');
    halt(1);
    end;
  writeln('Converting texture');
  if ExtractFileExt(Outfile) = '.dbcg' then
    tmpStream := DBCGFromTex(tempTex)
  else if ExtractFileExt(Outfile) = '.tga' then
    tmpStream := TGAFromTex(tempTex)
  else
    begin
    writeln('Invalid output format');
    halt(1);
    end;
  writeln('Saving stream');
  ByteStreamToFile(Outfile, tmpStream);
end.