unit u_graphics;

interface

uses
  SysUtils, Classes, u_files;

type
  TTexFormat = (tfRGB, tfRGBA);

  TTexImage = record
    BPP, Width, Height: Integer;
    Format: TTexFormat;
    Data: Array of Byte;
    end;

function RGBAToHSLA(Input: DWord): DWord;
function HSLAToRGBA(Input: DWord): DWord;


function TexFromTGA(Stream: TByteStream): TTexImage;
function TexFromOCG(Stream: TByteStream): TTexImage;
function OCGFromTex(TexImg: TTexImage; Tolerance: Integer = 20): TByteStream;

implementation

uses
  m_varlist, u_vectors, u_math, math;

type
  EUnsupportedStream = class(Exception);
  EConversionError = class(Exception);

function RGBAToHSLA(Input: DWord): DWord;
var
  Color, Color2: TVector3D;
  mMin, mMax: Single;
begin
  Color.x := (Input and $000000FF) / 255;
  Color.y := ((Input and $0000FF00) shr 8) / 255;
  Color.z := ((Input and $00FF0000) shr 16) / 255;

  mMin := Min(Color.X, Min(Color.Y, Color.Z));
  mMax := Max(Color.X, Max(Color.Y, Color.Z));

  Color2.Z := (mMax + mMin) / 2;
  if mMax = mMin then
    Color2 := Vector(0, 0, Color2.Z)
  else
    begin
    if Color2.Z < 0.5 then
      Color2.Y := (mMax - mMin) / (mMax + mMin)
    else
      Color2.Y := (mMax - mMin) / (2 - mMax - mMin);
    if Color.X = mMax then
      Color2.X := (Color.Y - Color.Z) / (mMax - mMin)
    else if Color.Y = mMax then
      Color2.X := 2.0 + (Color.Z - Color.X) / (mMax - mMin)
    else if Color.Z = mMax then
      Color2.X := 4.0 + (Color.X - Color.Y) / (mMax - mMin);
    Color2.X := Color2.X / 6;
    if Color2.X < 0 then
      Color2.X := Color2.X + 1;
    end;
  Result := (Input and $FF000000) or (Round(Color2.Z * 255) shl 16) or (Round(Color2.Y * 255) shl 8) or (Round(Color2.X * 255));
end;

function HSLAToRGBA(Input: DWord): DWord;
var
  Color, Color2: TVector3D;
  temp1, temp2, temp3, temp4: Single;
  i: Integer;
begin
  Color.x := (Input and $000000FF) / 255;
  Color.y := ((Input and $0000FF00) shr 8) / 255;
  Color.z := ((Input and $00FF0000) shr 16) / 255;

  if Color.Y = 0 then
    Color2 := Vector(Color.Z, Color.Z, Color.Z)
  else
    begin
    if Color.Z < 0.5 then
      temp2 := Color.Z * (1 + Color.Y)
    else
      temp2 := Color.Z + Color.Y - Color.Z * Color.Y;
    temp1 := 2 * Color.Z - temp2;
    for i := 0 to 2 do
      begin
      case i of
        0: temp3 := Color.X + 1 / 3;
        1: temp3 := Color.X;
        2: temp3 := Color.X - 1 / 3;
        end;
      if temp3 < 0 then
        temp3 := temp3 + 1.0;
      if temp3 > 1 then
        temp3 := temp3 - 1.0;
      if 6 * temp3 < 1 then
        temp4 := temp1 + (temp2 - temp1) * 6.0 * temp3
      else if 2 * temp3 < 1 then
        temp4 := temp2
      else if 3 * temp3 < 2 then
        temp4 := temp1 + (temp2 - temp1) * ((2.0 / 3.0) - temp3) * 6.0
      else
        temp4 := temp1;
      case i of
        0: Color2.Z := temp4;
        1: Color2.Y := temp4;
        2: Color2.X := temp4;
        end;
      end;
    end;
  Result := (Input and $FF000000) or (Round(Color2.Z * 255) shl 16) or (Round(Color2.Y * 255) shl 8) or (Round(Color2.X * 255));
end;

function TexFromTGA(Stream: TByteStream): TTexImage;
type
  TTGAFile = record
    ImgIDLen: Byte;
    PaletteType: Byte;
    ImgType: Byte;
    PaletteStart: Word;
    PaletteLength: Word;
    BPPPalette: Byte;
    OriginX, OriginY: Word;
    Width, Height: Word;
    BPP: Byte;
    Flags: Byte;
    ImgID: String;
    Palette: Array of Byte;
    Data: Array of Byte;
    end;
var
  TGA: Pointer;
  ResFile: TTGAFile;
  i, j, CP: Integer;
  Pixel: DWord;
  Iterations: Byte;

  procedure WritePixel;
  begin
    with ResFile do
      begin
      if CP >= Width * Height then
        exit;
      if PaletteType = 1 then
        begin
        case BPP of
          8: Pixel := Pixel and $000000FF;
          16: Pixel := Pixel and $0000FFFF;
          24: Pixel := Pixel and $00FFFFFF;
          end;
        Pixel := DWord((@Palette[Pixel])^);
        end;
      if Result.BPP = 24 then
        begin
        Pixel := Pixel and $00FFFFFF;
        Result.Data[3 * CP] := (Pixel and $FF0000) shr 16;
        Result.Data[3 * CP + 1] := (Pixel and $00FF00) shr 8;
        Result.Data[3 * CP + 2] := Pixel and $0000FF;
        end
      else
        begin
        Result.Data[4 * CP] := (Pixel and $00FF0000) shr 16;
        Result.Data[4 * CP + 1] := (Pixel and $0000FF00) shr 8;
        Result.Data[4 * CP + 2] := (Pixel and $000000FF);
        Result.Data[4 * CP + 3] := (Pixel and $FF000000) shr 24;
        end;
      end;
    inc(CP);
  end;

  procedure swap(var a: Byte; var b: Byte);
  var
    c: Byte;
  begin
    c := a;
    a := b;
    b := c;
  end;
begin
  TGA := @Stream.Data[0];
  CP := 0;
  try
    with ResFile do
      begin
      ImgIDLen := Byte(TGA^); Inc(TGA);
      PaletteType := Byte(TGA^); Inc(TGA);
      if PaletteType >= 2 then
        raise EUnsupportedStream.Create('Invalid Palette type');
      ImgType := Byte(TGA^); inc(TGA);
      PaletteStart := Word(TGA^); Inc(TGA, 2);
      PaletteLength := Word(TGA^); Inc(TGA, 2);
      if PaletteLength > 8192 then
        raise EUnsupportedStream.Create('Unsupported palette length');
      BPPPalette := Byte(TGA^); Inc(TGA);
      if BPPPalette mod 8 <> 0 then
        raise EUnsupportedStream.Create('Unsupported BPP value');
      OriginX := Word(TGA^); Inc(TGA, 2);
      OriginY := Word(TGA^); Inc(TGA, 2);
      Width := Word(TGA^); Inc(TGA, 2);
      Height := Word(TGA^); Inc(TGA, 2);
      BPP := Byte(TGA^); Inc(TGA);
      if BPPPalette mod 8 <> 0 then
        raise EUnsupportedStream.Create('Unsupported BPP value');
      Flags := Byte(TGA^); Inc(TGA);
      SetLength(ImgID, ImgIDLen);
      for i := 0 to ImgIDLen - 1 do
        begin
        ImgID[i + 1] := Char(Byte(TGA^));
        Inc(TGA);
        end;
      SetLength(Palette, (BPPPalette div 8) * PaletteLength);
      for i := 0 to high(Palette) do
        begin
        Palette[i] := Byte(TGA^);
        Inc(TGA);
        end;
      SetLength(Data, Length(Stream.Data) - (PtrUInt(TGA) - PtrUInt(@Stream.Data[0])));
      for i := 0 to high(Data) do
        begin
        Data[i] := Byte(TGA^);
        Inc(TGA);
        end;
      if PaletteType = 1 then
        Result.BPP := BPPPalette
      else
        Result.BPP := BPP;
      Result.Width := Width;
      Result.Height := Height;
      case Result.BPP of
        24: Result.Format := tfRGB;
        32: Result.Format := tfRGBA;
        end;
      SetLength(Result.Data, Result.BPP div 8 * Width * Height);
      if (ImgType = 1) or (ImgType = 2) then
        begin
        for i := 0 to Width * Height - 1 do
          begin
          Pixel := DWord((@Data[BPP div 8 * i])^);
          writePixel;
          end;
        end
      else if (ImgType = 9) or (ImgType = 10) then
        begin
        i := 0;
        Iterations := 1;
        while i <= high(Data) do
          begin
          Iterations := (Data[i] and $7F) + 1; inc(i);
          if Data[i - 1] < 128 then
            begin
            for j := 0 to Iterations - 1 do
              begin
              Pixel := DWord((@Data[i])^);
              writePixel;
              if CP >= Width * Height then
                abort;
              Inc(i, BPP div 8);
              end;
            end
          else
            begin
            Pixel := DWord((@Data[i])^);
            Inc(i, BPP div 8);
            for j := 0 to Iterations - 1 do
              begin
              writePixel;
              if CP >= Width * Height then
                abort;
              end;
            end;
          end;
        end
      else
        raise EUnsupportedStream.Create('Unsupported image type');
      end;
  except
    on EUnsupportedStream do ModuleManager.ModLog.AddError('Error loading TGA Stream: Unsupported stream');
  else
    writeln('Hint: Texture with too much data');
  end;
  with ResFile do
    begin
    if Flags and (1 shl 4) = 1 then
      for i := 0 to Width div 2 - 1 do
        for j := 0 to Height - 1 do
          begin
          Swap(Result.Data[Result.BPP div 8 * Width * j + Result.BPP div 8 * i    ], Result.Data[Result.BPP div 8 * Width * j + Result.BPP div 8 * (Width - i - 1)    ]);
          Swap(Result.Data[Result.BPP div 8 * Width * j + Result.BPP div 8 * i + 1], Result.Data[Result.BPP div 8 * Width * j + Result.BPP div 8 * (Width - i - 1) + 1]);
          Swap(Result.Data[Result.BPP div 8 * Width * j + Result.BPP div 8 * i + 2], Result.Data[Result.BPP div 8 * Width * j + Result.BPP div 8 * (Width - i - 1) + 2]);
          if Result.BPP = 32 then
            Swap(Result.Data[Result.BPP div 8 * Width * j + Result.BPP div 8 * i + 3], Result.Data[Result.BPP div 8 * Width * j + Result.BPP div 8 * (Width - i - 1) + 3]);
          end;
    if Flags and (1 shl 5) = 0 then
      begin
      for i := 0 to Width - 1 do
        for j := 0 to Height div 2 - 1 do
          begin
          Swap(Result.Data[Result.BPP div 8 * Width * j + Result.BPP div 8 * i    ], Result.Data[Result.BPP div 8 * Width * (Height - j - 1) + Result.BPP div 8 * i    ]);
          Swap(Result.Data[Result.BPP div 8 * Width * j + Result.BPP div 8 * i + 1], Result.Data[Result.BPP div 8 * Width * (Height - j - 1) + Result.BPP div 8 * i + 1]);
          Swap(Result.Data[Result.BPP div 8 * Width * j + Result.BPP div 8 * i + 2], Result.Data[Result.BPP div 8 * Width * (Height - j - 1) + Result.BPP div 8 * i + 2]);
          if Result.BPP = 32 then
            Swap(Result.Data[Result.BPP div 8 * Width * j + Result.BPP div 8 * i + 3], Result.Data[Result.BPP div 8 * Width * (Height - j - 1) + Result.BPP div 8 * i + 3]);
          end;
      end;
    end;
end;

function TexFromOCG(Stream: TByteStream): TTexImage;
var
  Maps: Array[1..4] of Array of Array of Byte;
  Bitmap: Array of Array of Byte;
  i, j, k: Integer;
  X, Y: Integer;
  DP: Integer;
  Bytes: DWord;
  tmp: Byte;
  Pixel: DWord;
  procedure FillMap(Map, X, Y, Pixel: Integer);
  begin
    Maps[Map, X, Y] := Pixel;
    BitMap[X, Y] := 1;
    if (X > 0) then if (BitMap[X - 1, Y] = 0) then
      FillMap(Map, X - 1, Y, Pixel);
    if (X < high(Maps[Map])) then if (BitMap[X + 1, Y] = 0) then
      FillMap(Map, X + 1, Y, Pixel);
    if (Y > 0) then if (BitMap[X, Y - 1] = 0) then
      FillMap(Map, X, Y - 1, Pixel);
    if (Y < high(Maps[Map, 0])) then if (BitMap[X, Y + 1] = 0) then
      FillMap(Map, X, Y + 1, Pixel);
  end;
begin
  try
    Result.BPP := 8 * Stream.Data[1];
    Result.Width := Word((@Stream.Data[2])^);
    Result.Height := Word((@Stream.Data[4])^);
    setLength(Result.Data, Stream.Data[1] * Result.Width * Result.Height);
    setLength(Bitmap, Result.Width);
    for i := 1 to 4 do
      setLength(Maps[i], Result.Width);
    for i := 0 to Result.Width - 1 do
      begin
      setLength(Bitmap[i], Result.Height);
      for j := 1 to 4 do
        setLength(Maps[j, i], Result.Height);
      end;
    x := 0;
    y := 0;
    DP := 6;
    for k := 1 to Stream.Data[1] do
      begin
      Bytes := DWord((@Stream.Data[DP])^);
      inc(DP, 4);
      for j := 0 to Result.Height - 1 do
        for i := 0 to (Result.Width div 8) - 1 do
          begin
          tmp := Stream.Data[DP];
          BitMap[8 * i, j] := tmp and 1;
          BitMap[8 * i + 1, j] := (tmp and (1 shl 1)) shr 1;
          BitMap[8 * i + 2, j] := (tmp and (1 shl 2)) shr 2;
          BitMap[8 * i + 3, j] := (tmp and (1 shl 3)) shr 3;
          BitMap[8 * i + 4, j] := (tmp and (1 shl 4)) shr 4;
          BitMap[8 * i + 5, j] := (tmp and (1 shl 5)) shr 5;
          BitMap[8 * i + 6, j] := (tmp and (1 shl 6)) shr 6;
          BitMap[8 * i + 7, j] := (tmp and (1 shl 7)) shr 7;
          inc(DP);
          end;
      for j := 0 to Result.Height - 1 do
        for i := 0 to Result.Width - 1 do
          if BitMap[i, j] <> 0 then
            begin
            Maps[k, i, j] := Stream.Data[DP];
            inc(DP);
            end;
      for j := 0 to Result.Height - 1 do
        for i := 0 to Result.Width - 1 do
          begin
          if BitMap[i, j] = 0 then
            begin
            tmp := Stream.Data[DP];
            FillMap(k, i, j, tmp);
            inc(DP);
            end;
          end;
      end;
    DP := 0;
    for j := 0 to Result.Height - 1 do
      for i := 0 to Result.Width - 1 do
        begin
        Pixel := Maps[1, i, j] or (Maps[2, i, j] shl 8) or (Maps[3, i, j] shl 16);
        if Result.BPP = 32 then
          Pixel := Pixel or (Maps[4, i, j] shl 24)
        else
          Pixel := Pixel or $FF000000;
        Pixel := HSLAToRGBA(Pixel);
        if Result.BPP = 24 then
          begin
          Pixel := Pixel and $00FFFFFF;
          Result.Data[3 * DP + 2] := Pixel and $0000FF;
          Result.Data[3 * DP + 1] := (Pixel and $00FF00) shr 8;
          Result.Data[3 * DP + 0] := (Pixel and $FF0000) shr 16;
          end
        else
          begin
          Result.Data[4 * DP + 2] := (Pixel and $000000FF);
          Result.Data[4 * DP + 1] := (Pixel and $0000FF00) shr 8;
          Result.Data[4 * DP + 0] := (Pixel and $00FF0000) shr 16;
          Result.Data[4 * DP + 3] := (Pixel and $FF000000) shr 24;
          end;
        inc(DP);
        end;
  except
    on EUnsupportedStream do ModuleManager.ModLog.AddError('Error loading OCG Stream: Unsupported stream');
  else
    ModuleManager.ModLog.AddError('Internal error');
  end;
end;

function OCGFromTex(TexImg: TTexImage; Tolerance: Integer = 20): TByteStream;
type
  AAByte = Array of Array of Byte;
  AByte = Array of Byte;

  procedure CompressMap(var Map: AAByte);
  var
    LaplaceMap: AAByte;
    ConvertedMap: Array of Array of Byte;
    DiffSum: Array of Array of Integer;
    i, j, k, l: Integer;
    NeighbourCount: Integer;
    ByteCount: DWord;
    DP: Integer;
    Bitmap: AAByte;
    Areas, Pixels: AByte;
    Value, Count: Integer;

    function MapPixel(x, y: Integer): Integer;
    begin
      Result := 0;
      if (x >= 0) and (y >= 0) and (x <= high(LaplaceMap)) and (y <= high(LaplaceMap[i])) then
        begin
        inc(NeighbourCount);
        Result := Map[X, Y];
        end;
    end;

    procedure InitArea;
    begin
      Count := 0;
      Value := 0;
    end;

    procedure MarkArea(X, Y: Integer);
    begin
      inc(Count);
      inc(Value, Map[X, Y]);
      ConvertedMap[X, Y] := 1;
      if (X > 0) then if (ConvertedMap[X - 1, Y] = 0) then
        MarkArea(X - 1, Y);
      if (X < high(Map)) then if (ConvertedMap[X + 1, Y] = 0) then
        MarkArea(X + 1, Y);
      if (Y > 0) then if (ConvertedMap[X, Y - 1] = 0) then
        MarkArea(X, Y - 1);
      if (Y < high(Map[0])) then if (ConvertedMap[X, Y + 1] = 0) then
        MarkArea(X, Y + 1);
    end;
  begin
    SetLength(LaplaceMap, length(Map));
    SetLength(ConvertedMap, length(Map));
    for i := 0 to high(LaplaceMap) do
      begin
      setLength(LaplaceMap[i], length(Map[i]));
      setLength(ConvertedMap[i], length(Map[i]));
      end;
    SetLength(DiffSum, Length(LaplaceMap) div 8);
    for i := 0 to high(DiffSum) do
      setLength(DiffSum[i], Length(LaplaceMap[i]) div 8);
    for j := 0 to high(LaplaceMap[0]) do
      for i := 0 to high(LaplaceMap) do
        begin
        NeighbourCount := 0;
        LaplaceMap[i, j] := abs(Integer(MapPixel(i - 1, j) + MapPixel(i - 1, j - 1) + MapPixel(i, j - 1) + MapPixel(i + 1, j - 1) + MapPixel(i + 1, j) + MapPixel(i + 1, j + 1) + MapPixel(i, j + 1) + MapPixel(i - 1, j + 1) - NeighbourCount * MapPixel(i, j)));
        end;
    for i := 0 to high(DiffSum) do
      for j := 0 to high(DiffSum[i]) div 8 do
        begin
        DiffSum[i, j] := 0;
        for k := 0 to 7 do
          for l := 0 to 7 do
            DiffSum[i, j] := DiffSum[i, j] + LaplaceMap[8 * i + k, 8 * j + l];
        end;
    for j := 0 to high(LaplaceMap[0]) do
      for i := 0 to high(LaplaceMap) do
        begin
        if (LaplaceMap[i, j] > Tolerance) or (((i / 8 = i div 8) or (j div 8 = j / 8))) then
          begin
          LaplaceMap[i, j] := 1;
          setLength(Pixels, length(Pixels) + 1);
          Pixels[high(Pixels)] := Map[I, J];
          end
        else
          begin
          LaplaceMap[i, j] := 0;
          end;
        ConvertedMap[i, j] := LaplaceMap[i, j];
        end;
    for j := 0 to high(LaplaceMap[0]) do
      for i := 0 to high(LaplaceMap) do
        begin
        if ConvertedMap[i, j] = 0 then
          begin
          setlength(Areas, length(Areas) + 1);
          InitArea;
          MarkArea(i, j);
          Areas[high(Areas)] := Value div Count;
          end;
        end;
    for j := 0 to high(LaplaceMap[0]) do
      for i := 0 to high(LaplaceMap) div 8 do
        LaplaceMap[i, j] := LaplaceMap[8 * i, j] or (LaplaceMap[8 * i + 1, j] shl 1) or (LaplaceMap[8 * i + 2, j] shl 2) or (LaplaceMap[8 * i + 3, j] shl 3)
                       or (LaplaceMap[8 * i + 4, j] shl 4) or (LaplaceMap[8 * i + 5, j] shl 5) or (LaplaceMap[8 * i + 6, j] shl 6) or (LaplaceMap[8 * i + 7, j] shl 7);
    setLength(LaplaceMap, length(LaplaceMap) div 8);
    ByteCount := Length(LaplaceMap) * Length(LaplaceMap[0]) + Length(Pixels) + Length(Areas);
    DP := Length(Result.Data);
    setLength(Result.Data, DP + 4 + ByteCount);
    DWord((@Result.Data[DP])^) := ByteCount; inc(DP, 4);
    for j := 0 to high(LaplaceMap[0]) do
      for i := 0 to high(LaplaceMap) do
        begin
        Result.Data[DP] := LaplaceMap[i, j];
        inc(DP);
        end;
    for i := 0 to high(Pixels) do
      begin
      Result.Data[DP] := Pixels[i];
      inc(DP);
      end;
    for i := 0 to high(Areas) do
      begin
      Result.Data[DP] := Areas[i];
      inc(DP);
      end;
  end;
var
  H, S, L, A: AAByte;
  i: Integer;
  x, y: Integer;
  Pixel: DWord;
begin
  SetLength(Result.Data, 6);
  x := 0;
  y := 0;
  with TexImg do
    begin
    Result.Data[0] := 255;
    Result.Data[1] := BPP div 8;;
    Word((@Result.Data[2])^) := Width;
    Word((@Result.Data[4])^) := Height;
    setLength(H, Width);
    setLength(S, Width);
    setLength(L, Width);
    if BPP = 32 then
      setLength(A, Width);
    for i := 0 to Width - 1 do
      begin
      setLength(H[i], Height);
      setLength(S[i], Height);
      setLength(L[i], Height);
      if BPP = 32 then
        setLength(A[i], Height);
      end;
    for i := 0 to high(Data) div BPP * 8 do
      begin
      Pixel := RGBAToHSLA(DWord((@Data[BPP div 8 * i])^));
      H[x, y] := Pixel and $FF;
      S[x, y] := (Pixel and $FF00) shr 8;
      L[x, y] := (Pixel and $FF0000) shr 16;
      if BPP = 32 then
        A[x, y] := (Pixel and $FF000000) shr 24;
      inc(x);
      if x = width then
        begin
        x := 0;
        inc(y);
        end;
      end;
    CompressMap(H);
    CompressMap(S);
    CompressMap(L);
    if BPP = 32 then
      CompressMap(A);
    end;
end;

end.