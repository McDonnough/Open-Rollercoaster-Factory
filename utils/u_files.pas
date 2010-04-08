unit u_files;

interface

uses
  SysUtils, Classes;

type
  TByteStream = record
    OrigFileName: String;
    Data: Array of Byte;
    end;

function GetFirstExistingFilename(FileName: String): String;
function ByteStreamFromFile(FileName: String): TByteStream;
procedure ByteStreamToFile(FileName: String; Stream: TByteStream);

implementation

uses
  m_varlist;

function GetFirstExistingFilename(FileName: String): String;
begin
  Result := '';
  if FileExists(FileName) then
    Exit(FileName)
  else if FileExists(ModuleManager.ModPathes.PersonalDataPath + FileName) then
    Exit(ModuleManager.ModPathes.PersonalDataPath + FileName)
  else if FileExists(ModuleManager.ModPathes.DataPath + FileName) then
    Exit(ModuleManager.ModPathes.DataPath + FileName);
end;

function ByteStreamFromFile(FileName: String): TByteStream;
begin
  try
    with TFileStream.Create(GetFirstExistingFilename(FileName), fmOpenRead) do
      begin
      Result.OrigFileName := GetFirstExistingFilename(FileName);
      SetLength(Result.Data, Size);
      Read(Result.Data[0], Size);
      Free;
      end;
  except
    ModuleManager.ModLog.AddError('Error loading file ' + FileName);
  end;
end;

procedure ByteStreamToFile(FileName: String; Stream: TByteStream);
begin
  try
    with TFileStream.Create(FileName, fmOpenWrite or fmCreate) do
      begin
      write(Stream.Data[0], Length(Stream.Data));
      Free;
      end;
  except
    ModuleManager.ModLog.AddError('Error saving file ' + FileName);
  end;
end;


end.