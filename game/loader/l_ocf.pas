unit l_ocf;

interface

uses
  Classes, SysUtils;

type
  AByte = array of Byte;

  TOCFDataStream = class
    protected
      fData: AByte;
      function getPointer: PByte;
      function getLength: DWord;
      procedure updateLength(Len: DWord);
    private
      property DataByteArray: AByte read fData;
    public
      property Data: PByte read getPointer;
      property DataLength: DWord read getLength write updateLength;
      procedure Copy(S: TOCFDataStream);
      procedure Append(S: TOCFDataStream);
      procedure Prepend(S: TOCFDataStream);
      procedure CopyFromByteArray(A: PByte; Len: Integer);
      destructor Free;
      end;

  TOCFSection = class
    protected
      fData: TOCFDataStream;
    public
      property Data: TOCFDataStream read fData;
      SectionType: String;
      constructor Create;
      destructor Free;
    end;

  AOCFSection = array of TOCFSection;

  TOCFFile = class
    protected
      fSections: AOCFSection;
      fReferences: TStringList;
    public
      property Sections: AOCFSection read fSections;
      property References: TStringList read fReferences write fReferences;
      FileName: String;
      constructor Create;
      destructor Free;
      procedure SaveToFile;
      procedure ReadFromFile;
    end;

const
  ST_TERRAIN = 1;
  ST_MESH    = 2;
  ST_LIGHT   = 3;
  ST_OBJREF  = 4;

implementation

uses
  m_varlist;

function TOCFDataStream.getPointer: PByte;
begin
  Result := nil;
  if getLength <> 0 then
    exit(@fData[0]);
end;

function TOCFDataStream.getLength: DWord;
begin
  Result := Length(fData);
end;

procedure TOCFDataStream.updateLength(Len: DWord);
begin
  SetLength(fData, Len);
end;

procedure TOCFDataStream.Copy(S: TOCFDataStream);
var
  PD, PS: PByte;
  i: Integer;
begin
  if S = nil then
    exit;
  PS := S.Data;
  PD := Data;
  DataLength :=  S.DataLength;
  for i := 0 to DataLength - 1 do
    begin
    PD^ := PS^;
    inc(PD);
    inc(PS);
    end;
end;

procedure TOCFDataStream.Append(S: TOCFDataStream);
var
  PD, PS: PByte;
  i: integer;
begin
  if S = nil then
    exit;
  DataLength :=  DataLength + S.DataLength;
  PD := Pointer(PtrUInt(Data) + DataLength);
  PS := S.Data;
  for i := 0 to S.DataLength - 1 do
    begin
    PD^ := PS^;
    inc(PD);
    inc(PS);
    end;
end;

procedure TOCFDataStream.Prepend(S: TOCFDataStream);
var
  PD, PS: PByte;
  i: integer;
begin
  if S = nil then
    exit;
  DataLength :=  DataLength + S.DataLength;
  for i := DataLength - S.DataLength - 1 downto 0 do
    fData[i + S.DataLength] := fData[i];
  PD := Pointer(PtrUInt(Data));
  PS := S.Data;
  for i := 0 to S.DataLength - 1 do
    begin
    PD^ := PS^;
    inc(PD);
    inc(PS);
    end;
end;

procedure TOCFDataStream.CopyFromByteArray(A: PByte; Len: Integer);
var
  i: Integer;
begin
  DataLength := Len;
  for i := 0 to Len - 1 do
    begin
    fData[i] := A^;
    Inc(A);
    end;
end;

destructor TOCFDataStream.Free;
begin
  DataLength :=  0;
end;


constructor TOCFSection.Create;
begin
  fData := TOCFDataStream.Create;
end;

destructor TOCFSection.Free;
begin
  fData.Free;
end;


constructor TOCFFile.Create;
begin
  fReferences := TStringList.Create;
end;

destructor TOCFFile.Free;
begin
  fReferences.Free;
end;

procedure TOCFFile.SaveToFile;
var
  FullPath: String;
  tWord: Word;
  tDWord: DWord;
  tQWord: QWord;
  tByte: Byte;
  tString: String;
  i: Integer;
begin
  FullPath := ModuleManager.ModPathes.PersonalDataPath + FileName;
  ForceDirectories(ExtractFileDir(FullPath));
  with TFileStream.Create(FullPath, fmCreate or fmOpenWrite) do
    begin
    write('ORCF', 4);
    tWord := References.count;
    write(tWord, 2);
    for i := 0 to tWord - 1 do
      begin
      write('REF', 3);
      tWord := length(References.Strings[i]);
      write(tWord, 2);
      tString := References.Strings[i];
      write(tString[1], tWord);
      end;
    tWord := length(Sections);
    write(tWord, 2);
    for i := 0 to tWord - 1 do
      begin
      write('SEC', 3);
      tWord := length(Sections[i].SectionType);
      tString := Sections[i].SectionType;
      write(tWord, 2);
      write(tString[1], tWord);
      tDWord := Sections[i].Data.DataLength;
      write(tDWord, 4);
      write(Sections[i].Data.DataByteArray, tDWord);
      end;
    Free;
    end;
end;

procedure TOCFFile.ReadFromFile;
var
  FullPath: String;
  tWord: Word;
  tDWord: DWord;
  tQWord: QWord;
  tByte: Byte;
  tString: String;
  tAByte: AByte;
  i: Integer;
begin
  if FileExists(ModuleManager.ModPathes.PersonalDataPath + FileName) then
    FullPath := ModuleManager.ModPathes.PersonalDataPath + FileName
  else if FileExists(ModuleManager.ModPathes.DataPath + FileName) then
    FullPath := ModuleManager.ModPathes.DataPath + FileName
  else
    begin
    ModuleManager.ModLog.AddWarning('File ' + FileName + ' not found', 'l_ocf.pas', 236);
    exit;
    end;
  with TFileStream.Create(FullPath, fmOpenRead) do
    begin
    setLength(tString, 4);
    Read(tString[1], 4);
    if tString <> 'ORCF' then
      ModuleManager.ModLog.AddWarning('File ' + FileName + ' does not seem to be valid', 'l_ocf.pas', 244)
    else
      begin
      Read(tWord, 2);
      for i := 1 to tWord do
        begin
        setLength(tString, 3);
        Read(tString[1], 3);
        if tString <> 'REF' then
          begin
          ModuleManager.ModLog.AddWarning('File ' + FileName + ' contains errors', 'l_ocf.pas', 254);
          exit;
          end;
        Read(tWord, 2);
        setLength(tString, tWord);
        Read(tString[1], tWord);
        References.Add(tString);
        end;
      Read(tWord, 2);
      setLength(Sections, tWord);
      for i := 0 to tWord - 1 do
        begin
        setLength(tString, 3);
        Read(tString[1], 3);
        if tString <> 'SEC' then
          begin
          ModuleManager.ModLog.AddWarning('File ' + FileName + ' contains errors', 'l_ocf.pas', 254);
          exit;
          end;
        Read(tWord, 2);
        setLength(tString, tWord);
        Read(tString, tWord);
        Sections[i].SectionType := tString;
        Read(tDWord, 4);
        setLength(tAByte, tDWord);
        Read(tAByte[0], tDWord);
        Sections[i].Data.CopyFromByteArray(@tAByte[0], tDWord);
        end;
      end;
    Free;
    end;
end;

end.