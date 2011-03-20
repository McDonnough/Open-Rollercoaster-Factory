unit u_huffman;

interface

uses
  SysUtils, Classes, u_files, math, u_math, u_binutils;

function HuffmanEncode(Stream: TByteStream): TByteStream;
function HuffmanDecode(Stream: TByteStream): TByteStream;

implementation

type
  THuffmanCode = record
    Length, Value: Byte;
    Code: DWord;
    end;

  THuffmanNode = class
    public
      B: Byte;
      Occurences: Integer;
      Parent: THuffmanNode;
      Children: Array[0..1] of THuffmanNode;
      procedure MakeToplevel(Child1, Child2: THuffmanNode);
      function GetCode: THuffmanCode;
      constructor Create;
      destructor Free;
    end;

var
  TopLevelNodes: Array of THuffmanNode;

procedure THuffmanNode.MakeToplevel(Child1, Child2: THuffmanNode);
var
  i: Integer;
begin
  Child1.Parent := Self;
  Child2.Parent := Self;
  Children[0] := Child1;
  Children[1] := Child2;
  Occurences := Child1.Occurences + Child2.Occurences;
  for i := 0 to high(TopLevelNodes) do
    if TopLevelNodes[i] = Child1 then
      TopLevelNodes[i] := Self
    else if TopLevelNodes[i] = Child2 then
      TopLevelNodes[i] := TopLevelNodes[high(TopLevelNodes)];
  SetLength(TopLevelNodes, length(TopLevelNodes) - 1);
end;

function THuffmanNode.GetCode: THuffmanCode;
begin
  if Parent <> nil then
    begin
    Result := Parent.GetCode;
    Result.Value := B;
    if Parent.Children[1] = Self then
      Result.Code := SetBit(Result.Length, Result.Code);
    Inc(Result.Length);
    end
  else
    begin
    Result.Code := 0;
    Result.Length := 0;
    Result.Value := 0;
    end;
end;

constructor THuffmanNode.Create;
begin
  Children[0] := nil;
  Children[1] := nil;
  Parent := nil;
  B := 0;
  Occurences := 1;
end;

destructor THuffmanNode.Free;
begin
  if Children[0] <> nil then
    Children[0].Free;
  if Children[1] <> nil then
    Children[1].Free;
end;

function HuffmanEncode(Stream: TByteStream): TByteStream;
var
  i: Integer;
  ByteTrees: Array[0..255] of Word;
  BottomLevelTrees: Array[0..255] of THuffmanNode;
  MinV, SMinV: Integer;
  MinID, SMinID: Byte;
  TreeCount: Word;
  StreamPos: Pointer;
  Codes: Array[0..255] of THuffmanCode;
  BitsTotal, CurrElement: DWord;
  EncodedData: Array of DWord;
  BitOffset: Byte;
  D, D1, D2: DWord;
begin
  SetLength(TopLevelNodes, 0);
  BitsTotal := 0;
  BitOffset := 0;
  CurrElement := 0;
  TreeCount := 0;
  for i := 0 to 255 do
    begin
    ByteTrees[i] := 256;
    BottomLevelTrees[i] := nil;
    end;
  for i := 0 to high(Stream.Data) do
    begin
    if ByteTrees[Stream.Data[i]] = 256 then
      begin
      inc(TreeCount);
      SetLength(TopLevelNodes, length(TopLevelNodes) + 1);
      TopLevelNodes[high(TopLevelNodes)] := THuffmanNode.Create;
      ByteTrees[Stream.Data[i]] := High(TopLevelNodes);
      TopLevelNodes[high(TopLevelNodes)].B := Stream.Data[i];
      BottomLevelTrees[Stream.Data[i]] := TopLevelNodes[high(TopLevelNodes)];
      end
    else
      Inc(TopLevelNodes[ByteTrees[Stream.Data[i]]].Occurences);
    end;
  while length(TopLevelNodes) > 1 do
    begin
    MinV := TopLevelNodes[0].Occurences;
    MinID := 0;
    for i := 1 to high(TopLevelNodes) do
      if TopLevelNodes[i].Occurences < MinV then
        begin
        MinV := TopLevelNodes[i].Occurences;
        MinID := i;
        end;
    SMinV := -1;
    SMinID := 0;
    for i := 0 to high(TopLevelNodes) do
      if i <> MinID then
        if (SMinV = -1) or (TopLevelNodes[i].Occurences - MinV < SMinV) then
          begin
          SMinV := TopLevelNodes[i].Occurences - MinV;
          SMinID := i;
          end;
    with THuffmanNode.Create do
      MakeToplevel(TopLevelNodes[Min(SMinID, MinID)], TopLevelNodes[Max(SMinID, MinID)]);
    end;
  SetLength(Result.Data, 10 + 6 * TreeCount);
  Streampos := @Result.Data[0];
  DWord(Streampos^) := 0; Inc(StreamPos, 4);
  DWord(Streampos^) := DWord(Length(Stream.Data)); Inc(StreamPos, 4);
  Word(Streampos^) := TreeCount; Inc(StreamPos, 2);
  for i := 0 to 255 do
    if BottomLevelTrees[i] <> nil then
      begin
      Codes[i].Value := i;
      Codes[i].Length := 8;
      Codes[i].Code := i;
      Codes[i] := BottomLevelTrees[i].GetCode;
      Byte(StreamPos^) := Codes[i].Value; Inc(Streampos);
      Byte(StreamPos^) := Codes[i].Length; Inc(Streampos);
      DWord(StreamPos^) := Codes[i].Code; Inc(Streampos, 4);
      end;
  TopLevelNodes[0].Free;
  SetLength(TopLevelNodes, 0);

  SetLength(EncodedData, length(Stream.Data) div 4 + 1);
  for i := 0 to high(Stream.Data) do
    begin
    MoveDWord(BitOffset, Codes[Stream.Data[i]].Code, EncodedData[CurrElement], EncodedData[CurrElement + 1]);
    BitOffset := BitOffset + Codes[Stream.Data[i]].Length;
    BitsTotal := BitsTotal + Codes[Stream.Data[i]].Length;
    if BitOffset >= 32 then
      begin
      dec(BitOffset, 32);
      inc(CurrElement);
      end;
    end;
  SetLength(EncodedData, BitsTotal div 32 + 1);
  SetLength(Result.Data, length(Result.Data) + 4 * Length(EncodedData));
  DWord((@Result.Data[0])^) := BitsTotal;
  StreamPos := @Result.Data[Length(Result.Data) - 4 * Length(EncodedData)];
  for i := 0 to high(EncodedData) do
    begin
    DWord(StreamPos^) := EncodedData[i];
    Inc(StreamPos, 4);
    end;
end;

function HuffmanDecode(Stream: TByteStream): TByteStream;
var
  i: Integer;
  BitCount: DWord;
  Codes: Array[0..$FFFF] of Array of THuffmanCode;
  CurrCode, CurrDestByte: DWord;
  BitOffset, CurrBit: DWord;
  StreamPos: Pointer;
  LastByte: Integer;
  CurrByte: DWord;
  CodeCount: Integer;
  TmpCode: THuffmanCode;
  CodeGroup: Word;
  CodeSubgroup: Word;
  MinLength: Integer;

  function Decode(Code: DWord; Length: Byte): Integer; inline;
  begin
    Result := -1;
    CodeGroup := (Code shr 16);
    CodeSubgroup := Code and $FFFF;
    if Codes[CodeGroup, CodeSubgroup].Length = Length then
      Result := Codes[CodeGroup, CodeSubgroup].Value;
  end;
begin
  StreamPos := @Stream.Data[0];
  BitCount := DWord(StreamPos^); Inc(StreamPos, 4);
  SetLength(Result.Data, DWord(StreamPos^)); Inc(StreamPos, 4);
  CodeCount := Word(StreamPos^); Inc(StreamPos, 2);
  MinLength := 1024;
  for i := 0 to CodeCount - 1 do
    begin
    TmpCode.Value := Byte(StreamPos^); Inc(StreamPos);
    TmpCode.Length := Byte(StreamPos^); Inc(StreamPos);
    TmpCode.Code := DWord(StreamPos^); Inc(StreamPos, 4);
    MinLength := Min(MinLength, TmpCode.Length);
    CodeGroup := (TmpCode.Code shr 16);
    CodeSubgroup := TmpCode.Code and $FFFF;
    SetLength(Codes[CodeGroup], Max(Length(Codes[CodeGroup]), CodeSubGroup + 1));
    Codes[CodeGroup, CodeSubGroup] := TmpCode;
    end;
  BitOffset := 0;
  CurrBit := 0;
  CurrCode := 0;
  CurrByte := DWord(StreamPos^); inc(StreamPos, 4);
  CurrDestByte := 0;
  while BitCount > CurrBit do
    begin
    if CurrByte and (1 shl (CurrBit and 31)) <> 0 then
      CurrCode := CurrCode or (1 shl BitOffset);
    LastByte := -1;
    inc(BitOffset);
    if BitOffset >= MinLength then
      begin
      LastByte := Decode(CurrCode, BitOffset);
      if LastByte <> -1 then
        begin
        Result.Data[CurrDestByte] := LastByte;
        inc(CurrDestByte);
        CurrCode := 0;
        BitOffset := 0;
        end;
      end;
    inc(CurrBit);
    if CurrBit and 31 = 0 then
      begin
      CurrByte := DWord(StreamPos^);
      inc(StreamPos, 4);
      end;
    end;
end;

end.