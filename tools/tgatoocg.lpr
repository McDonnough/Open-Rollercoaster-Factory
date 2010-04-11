program tgatoocg;

uses
  SysUtils, Classes, u_graphics, u_files;

var
  infile, outfile: String;
  tolerance: integer = 20;
  i: integer;
begin
  i := 1;
  while paramstr(i) <> '' do
    begin
    if paramstr(i) = '-i' then
      begin
      inc(i);
      infile := paramstr(i);
      if outfile = '' then outfile := infile + '.ocg';
      end
    else if paramstr(i) = '-o' then
      begin
      inc(i);
      outfile := paramstr(i);
      end
    else if paramstr(i) = '--tolerance' then
      begin
      inc(i);
      try
        tolerance := StrToInt(paramstr(i));
      except
        writeln('Invalid tolerace value');
      end;
      end;
    inc(i);
    end;
  try
    ByteStreamToFile(outfile, OCGFromTex(TexFromTGA(ByteStreamFromFile(infile)), tolerance));
  except
    writeln('Error converting image');
  end;
end.