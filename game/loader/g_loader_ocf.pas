unit g_loader_ocf;

interface

uses
  SysUtils, Classes, u_dom, u_xml;

type
  TOCFBinarySection = class
    public
      Data: Array of Byte;
      procedure Replace(P: Pointer; L: Integer);
      procedure Append(P: Pointer; L: Integer);
      procedure Prepend(P: Pointer; L: Integer);
    end;

  TOCFXMLSection = class
    protected
      fDocument: TDOMDocument;
    public
      property Document: TDOMDocument read fDocument;
      constructor Create(S: String);
      destructor Free;
    end;

  TOCFFile = class
    protected
      fXMLSection: TOCFXMLSection;
      fBinarySections: Array of TOCFBinarySection;
      fFName: String;
      function GetBinarySection(I: Integer): TOCFBinarySection;
    public
      Flags: QWord;
      property Filename: String read fFName;
      property XML: TOCFXMLSection read fXMLSection;
      property Bin[i: Integer]: TOCFBinarySection read GetBinarySection;
      procedure AddBinarySection(A: TOCFBinarySection);
      procedure SaveTo(FName: String);
      constructor Create(FName: String);
      destructor Free;
    end;

implementation

uses
  m_varlist, u_files;

type
  EOCFWrongInternalFormat = class(Exception);
  EOCFStreamingError = class(Exception);

procedure TOCFBinarySection.Replace(P: Pointer; L: Integer);
var
  i: PtrUInt;
begin
  SetLength(Data, L);
  for i := 0 to l - 1 do
    Data[i] := Byte((P + I)^);
end;

procedure TOCFBinarySection.Append(P: Pointer; L: Integer);
var
  i: PtrUInt;
  O: Integer;
begin
  O := Length(Data);
  SetLength(Data, L + O);
  for i := 0 to l - 1 do
    Data[i + o] := Byte((P + I)^);
end;

procedure TOCFBinarySection.Prepend(P: Pointer; L: Integer);
var
  i: PtrUInt;
  O: Integer;
begin
  O := Length(Data);
  SetLength(Data, L + O);
  for i := O downto L + 1 do
    Data[i] := Data[i - 1];
  for i := 0 to l - 1 do
    Data[i] := Byte((P + I)^);
end;


constructor TOCFXMLSection.Create(S: String);
begin
  if S = '' then
    S := '<?xml version="1.0" encoding="UTF-8"?><ocf version="1.0"></ocf>';
  fDocument := DOMFromXML(S);
end;

destructor TOCFXMLSection.Free;
begin
  fDocument.Free;
end;


function TOCFFile.GetBinarySection(I: Integer): TOCFBinarySection;
begin
  Result := nil;
  if (i >= 0) and (i <= high(fBinarySections)) then
    Result := fBinarySections[i];
end;

procedure TOCFFile.SaveTo(FName: String);
var
  tmpDW: DWord;
  S: String;
  i: Integer;
begin
  fFName := FName;
  try
    S := XMLFromDOM(fXMLSection.Document);
    with TFileStream.Create(FName, fmOpenWrite or fmCreate) do
      begin
      tmpDW := $DEA7450D; write(tmpDW, 4);
      write(Flags, 8);
      tmpDW := length(s); write(tmpDW, 4);
      tmpDW := length(fBinarySections); write(tmpDW, 4);
      for i := 0 to high(fBinarySections) do
        begin
        tmpDW := length(fBinarySections[i].Data);
        write(tmpDW, 4);
        end;
      write(S[1], length(S));
      for i := 0 to high(fBinarySections) do
        write(fBinarySections[i].Data[0], length(fBinarySections[i].Data));
      end;
  except
    ModuleManager.ModLog.AddError('Error saving OCF file ' + FFName + ': Internal error');
  end;
end;

procedure TOCFFile.AddBinarySection(A: TOCFBinarySection);
begin
  setLength(fBinarySections, length(fBinarySections) + 1);
  fBinarySections[high(fBinarySections)] := A;
end;

constructor TOCFFile.Create(FName: String);
var
  tmpDW, XMLSectLength, BinarySectionCount: DWord;
  BinarySectionLength: Array of DWord;
  S: String;
  i: Integer;
begin
  fFName := GetFirstExistingFilename(FName);
  try
    if FileExists(FFName) then
      begin
      with TFileStream.Create(fFName, fmOpenRead) do
        begin
        Read(tmpDW, 4);
        Read(Flags, 8);
        if tmpDW <> $DEA7450D then
          raise EOCFWrongInternalFormat.Create('Wrong internal format');
        Read(XMLSectLength, 4);
        Read(BinarySectionCount, 4);
        setLength(BinarySectionLength, BinarySectionCount);
        Read(BinarySectionLength[0], BinarySectionCount * 4);
        if XMLSectLength + Position > Size then
          raise EOCFStreamingError.Create('Streaming error');
        Setlength(S, XMLSectLength);
        Read(S[1], XMLSectLength);
        fXMLSection := TOCFXMLSection.Create(S);
        setLength(fBinarySections, BinarySectionCount);
        for i := 0 to BinarySectionCount - 1 do
          if Position + BinarySectionLength[i] > Size then
            raise EOCFStreamingError.Create('Streaming error')
          else
            begin
            fBinarySections[i] := TOCFBinarySection.Create;
            setLength(fBinarySections[i].Data, BinarySectionLength[i]);
            Read(fBinarySections[i].Data[0], BinarySectionLength[i]);
            end;
        Free;
        end;
      end
    else
      fXMLSection := TOCFXMLSection.Create('');
  except
    on EOCFWrongInternalFormat do ModuleManager.ModLog.AddError('Error loading OCF file ' + FFName + ': Wrong internal format');
    on EOCFStreamingError do ModuleManager.ModLog.AddError('Error loading OCF file ' + FFName + ': Streaming error');
  else
    ModuleManager.ModLog.AddError('Error loading OCF file ' + FFName + ': Internal error');
  end;
end;

destructor TOCFFile.Free;
var
  i: Integer;
begin
  fXMLSection.Free;
  for i := 0 to high(fBinarySections) do
    fBinarySections[i].Free;
end;

end.