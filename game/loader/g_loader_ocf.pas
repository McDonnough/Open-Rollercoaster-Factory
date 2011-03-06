unit g_loader_ocf;

interface

uses
  SysUtils, Classes, u_dom, u_xml, u_files, u_graphics;

type
  TOCFBinarySection = class
    public
      Stream: TByteStream;
      procedure Replace(P: Pointer; L: Integer);
      procedure Append(P: Pointer; L: Integer);
      procedure Prepend(P: Pointer; L: Integer);
    end;

  TOCFXMLSection = class
    protected
      fDocument: TDOMDocument;
    public
      property Document: TDOMDocument read fDocument write fDocument;
      constructor Create(S: String);
      destructor Free;
    end;

  TOCFResource = record
    id, section: Integer;
    version, format: String;
    end;

  TOCFFile = class
    protected
      fXMLSection: TOCFXMLSection;
      fBinarySections: Array of TOCFBinarySection;
      fFName: String;
      fPreview: TTexImage;
      fOCFType, fDescription, fOCFName: String;
      function GetBinarySection(I: Integer): TOCFBinarySection;
      function GetResource(I: Integer): TOCFResource;
      function GetDescription: String;
      function GetName: String;
      function GetOCFType: String;
      function GetPreview: TTexImage;
    public
      Flags: QWord;
      property Filename: String read fFName;
      property XML: TOCFXMLSection read fXMLSection;
      property Bin[i: Integer]: TOCFBinarySection read GetBinarySection;
      property Resources[i: Integer]: TOCFResource read GetResource;
      property Description: String read getDescription;
      property Name: String read getName;
      property OCFType: String read getOCFType;
      property Preview: TTexImage read getPreview;
      procedure AddBinarySection(A: TOCFBinarySection);
      procedure SaveTo(FName: String);
      constructor Create(FName: String);
      destructor Free;
    end;

implementation

uses
  m_varlist, u_huffman;

type
  EOCFWrongInternalFormat = class(Exception);
  EOCFStreamingError = class(Exception);

procedure TOCFBinarySection.Replace(P: Pointer; L: Integer);
var
  i: PtrUInt;
begin
  SetLength(Stream.Data, L);
  for i := 0 to l - 1 do
    Stream.Data[i] := Byte((P + I)^);
end;

procedure TOCFBinarySection.Append(P: Pointer; L: Integer);
var
  i: PtrUInt;
  O: Integer;
begin
  O := Length(Stream.Data);
  SetLength(Stream.Data, L + O);
  for i := 0 to l - 1 do
    Stream.Data[i + o] := Byte((P + I)^);
end;

procedure TOCFBinarySection.Prepend(P: Pointer; L: Integer);
var
  i: PtrUInt;
  O: Integer;
begin
  O := Length(Stream.Data);
  SetLength(Stream.Data, L + O);
  for i := O downto L + 1 do
    Stream.Data[i] := Stream.Data[i - 1];
  for i := 0 to l - 1 do
    Stream.Data[i] := Byte((P + I)^);
end;


constructor TOCFXMLSection.Create(S: String);
begin
  if S = '' then
    S := '<?xml version="1.0" encoding="UTF-8"?><ocf resource:version="1.0"></ocf>';
  fDocument := DOMFromXML(S);
end;

destructor TOCFXMLSection.Free;
begin
  fDocument.Free;
end;

function TOCFFile.GetPreview: TTexImage;
var
  ResourceCount: Integer;
begin
  if fPreview.BPP <> 0 then
    exit(fPreview);
  if GetOCFType = 'terraincollection' then
    begin
    ResourceCount := high(XML.Document.GetElementsByTagName('resource'));
    Result := TexFromStream(fBinarySections[Resources[ResourceCount].section].Stream, '.' + Resources[ResourceCount].Format);
    end;
  fPreview := Result;
end;

function TOCFFile.GetDescription: String;
begin
  if fDescription <> '' then
    exit(fDescription);
  Result := '';
  try
    if GetOCFType = 'savedgame' then
      Result := TDOMElement(fXMLSection.Document.GetElementsByTagName('description')[0]).FirstChild.NodeValue;
  except
    ModuleManager.ModLog.AddError('Error loading description of an OCF file: Internal error');
  end;
  Result := Result + #10 + ModuleManager.ModLanguage.Translate('By') + ' ' + TDOMElement(fXMLSection.Document.FirstChild).GetAttribute('author');
  fDescription := Result;
end;

function TOCFFile.GetName: String;
begin
  if fOCFName <> '' then
    exit(fOCFName);
  Result := 'No name';
  if GetOCFType = 'terraincollection' then
    Result := TDOMElement(fXMLSection.Document.GetElementsByTagName('texturecollection')[0]).GetAttribute('name')
  else if GetOCFType = 'savedgame' then
    Result := TDOMElement(fXMLSection.Document.GetElementsByTagName('park')[0]).GetAttribute('name');
  fOCFName := Result;
end;

function TOCFFile.GetOCFType: String;
begin
  if fOCFType <> '' then
    exit(fOCFType);
  Result := TDOMElement(fXMLSection.Document.FirstChild).GetAttribute('type');
  if Result = '' then
    Result := 'undefined';
  fOCFType := Result;
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
      tmpDW := $DEA7450D;
      write(tmpDW, 4);
      write(Flags, 8);
      tmpDW := length(s);
      write(tmpDW, 4);
      tmpDW := length(fBinarySections);
      write(tmpDW, 4);
      for i := 0 to high(fBinarySections) do
        begin
        fBinarySections[i].Stream := HuffmanEncode(fBinarySections[i].Stream);
        tmpDW := length(fBinarySections[i].Stream.Data);
        write(tmpDW, 4);
        end;
      write(S[1], length(S));
      for i := 0 to high(fBinarySections) do
        write(fBinarySections[i].Stream.Data[0], length(fBinarySections[i].Stream.Data));
      end;
  except
    if ModuleManager <> nil then // Independent mode
      ModuleManager.ModLog.AddError('Error saving OCF file ' + FFName + ': Internal error');
  end;
end;

function TOCFFile.GetResource(I: Integer): TOCFResource;
var
  a: TDOMNodeList;
  j: Integer;
begin
  a := XML.Document.GetElementsByTagName('resource');
  for j := 0 to high(a) do
    if TDOMElement(a[j]).GetAttribute('resource:id') = IntToStr(i) then
      begin
      Result.id := j;
      Result.Version := TDOMElement(a[j]).GetAttribute('resource:version');
      Result.Format := TDOMElement(a[j]).GetAttribute('resource:format');
      Result.Section := StrToInt(TDOMElement(a[j]).GetAttribute('resource:section'));
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
  fOCFName := '';
  fOCFType := '';
  fDescription := '';
  fPreview.BPP := 0;
  fFName := '';
  if FName <> '' then
    fFName := GetFirstExistingFilename(FName);
  if fFName <> '' then
    writeln('Loading OCF file ' + fFName);
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
            setLength(fBinarySections[i].Stream.Data, BinarySectionLength[i]);
            Read(fBinarySections[i].Stream.Data[0], BinarySectionLength[i]);
            fBinarySections[i].Stream := HuffmanDecode(fBinarySections[i].Stream);
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
