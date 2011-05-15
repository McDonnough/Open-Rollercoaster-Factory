unit u_files;

interface

uses
  SysUtils, Classes;

type
  TByteStream = record
    OrigFileName: String;
    Data: Array of Byte;
    end;

function GetFirstExistingFilename(FileName: String; ShowErrors: Boolean = True): String;
function SystemIndependentFileName(FileName: String): String;
function ByteStreamFromFile(FileName: String): TByteStream;
procedure ByteStreamToFile(FileName: String; Stream: TByteStream);

implementation

uses
  m_varlist, u_functions;

function SystemIndependentFileName(FileName: String): String;
begin
  Result := FileName;
  if GetFirstExistingFilename(SubString(FileName, length(ModuleManager.ModPathes.PersonalDataPath) + 1, length(FileName) - length(ModuleManager.ModPathes.PersonalDataPath)), false) = FileName then
    exit(SubString(FileName, length(ModuleManager.ModPathes.PersonalDataPath) + 1, length(FileName) - length(ModuleManager.ModPathes.PersonalDataPath)))
  else if GetFirstExistingFilename(SubString(FileName, length(ModuleManager.ModPathes.DataPath) + 1, length(FileName) - length(ModuleManager.ModPathes.DataPath)), false) = FileName then
    exit(SubString(FileName, length(ModuleManager.ModPathes.DataPath) + 1, length(FileName) - length(ModuleManager.ModPathes.DataPath)));
end;

function GetFirstExistingFilename(FileName: String; ShowErrors: Boolean = True): String;
begin
  if FileName = '' then
    exit('');
  if ModuleManager = nil then // Independent mode
    exit(FileName);
  Result := '';
  FileName := ModuleManager.ModPathes.Convert(ModuleManager.ModPathes.ConvertToUnix(FileName));
  if FileExists(FileName) then
    Exit(FileName)
  else if FileExists(ModuleManager.ModPathes.PersonalDataPath + FileName) then
    Exit(ModuleManager.ModPathes.PersonalDataPath + FileName)
  else if FileExists(ModuleManager.ModPathes.DataPath + FileName) then
    Exit(ModuleManager.ModPathes.DataPath + FileName);
  if ShowErrors then
    ModuleManager.ModLog.AddError('File ''' + FileName + ''' does not exist');
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
    if ModuleManager <> nil then // Independent mode
      ModuleManager.ModLog.AddError('Error loading file ' + FileName)
    else
      writeln('Error loading file ' + FileName);
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
    if ModuleManager <> nil then // Independent mode
      ModuleManager.ModLog.AddError('Error saving file ' + FileName)
    else
      writeln('Error saving file ' + FileName);
  end;
end;


end.
