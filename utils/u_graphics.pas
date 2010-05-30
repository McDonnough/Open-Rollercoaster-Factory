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
function TexFromDBCG(Stream: TByteStream): TTexImage;
function DBCGFromTex(TexImg: TTexImage): TByteStream;

implementation

uses
  m_varlist, u_vectors, u_math, math, u_huffman;

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

function TexFromDBCG(Stream: TByteStream): TTexImage;
var
  i, j: Integer;
  Last: Array[0..3] of Byte;
begin
  Result.BPP := Stream.Data[0];
  Result.Width := Word((@Stream.Data[1])^);
  Result.Height := Word((@Stream.Data[3])^);
  SetLength(Result.Data, Result.Width * Result.Height * Result.BPP div 8);
  for i := 0 to 3 do
    Last[i] := 0;
  for j := 0 to Result.Height - 1 do
    for i := 0 to Result.Width - 1 do
      begin
      Last[0] := Byte(Last[0] + Stream.Data[5 + ((Result.Width * j + i) * Result.BPP div 8)]);
      Last[1] := Byte(Last[1] + Stream.Data[6 + ((Result.Width * j + i) * Result.BPP div 8)]);
      Last[2] := Byte(Last[2] + Stream.Data[7 + ((Result.Width * j + i) * Result.BPP div 8)]);
      if Result.BPP = 32 then
        Last[3] := Byte(Last[3] + Stream.Data[8 + ((Result.Width * j + i) * Result.BPP div 8)]);
      Result.Data[0 + ((Result.Width * j + i) * Result.BPP div 8)] := Last[0];
      Result.Data[1 + ((Result.Width * j + i) * Result.BPP div 8)] := Last[1];
      Result.Data[2 + ((Result.Width * j + i) * Result.BPP div 8)] := Last[2];
      if Result.BPP = 32 then
        Result.Data[3 + ((Result.Width * j + i) * Result.BPP div 8)] := Last[3];
      end;
end;

function DBCGFromTex(TexImg: TTexImage): TByteStream;
var
  i, j: Integer;
begin
  SetLength(Result.Data, 5 + TexImg.BPP div 8 * TexImg.Height * TexImg.Width);
  Result.Data[0] := TexImg.BPP;
  Word((@Result.Data[1])^) := TexImg.Width;
  Word((@Result.Data[3])^) := TexImg.Height;
  for j := 0 to TexImg.Height - 1 do
    for i := 0 to TexImg.Width - 1 do
      if i + j = 0 then
        begin
        Result.Data[5 + ((TexImg.Width * j + i) * TexImg.BPP div 8)] := TexImg.Data[0 + ((TexImg.Width * j + i) * TexImg.BPP div 8)];
        Result.Data[6 + ((TexImg.Width * j + i) * TexImg.BPP div 8)] := TexImg.Data[1 + ((TexImg.Width * j + i) * TexImg.BPP div 8)];
        Result.Data[7 + ((TexImg.Width * j + i) * TexImg.BPP div 8)] := TexImg.Data[2 + ((TexImg.Width * j + i) * TexImg.BPP div 8)];
        if TexImg.BPP = 32 then
          Result.Data[8 + ((TexImg.Width * j + i) * TexImg.BPP div 8)] := TexImg.Data[3 + ((TexImg.Width * j + i) * TexImg.BPP div 8)];
        end
      else
        begin
        Result.Data[5 + ((TexImg.Width * j + i) * TexImg.BPP div 8)] := Byte(TexImg.Data[0 + ((TexImg.Width * j + i) * TexImg.BPP div 8)] - TexImg.Data[0 + ((TexImg.Width * j + (i - 1)) * TexImg.BPP div 8)]);
        Result.Data[6 + ((TexImg.Width * j + i) * TexImg.BPP div 8)] := Byte(TexImg.Data[1 + ((TexImg.Width * j + i) * TexImg.BPP div 8)] - TexImg.Data[1 + ((TexImg.Width * j + (i - 1)) * TexImg.BPP div 8)]);
        Result.Data[7 + ((TexImg.Width * j + i) * TexImg.BPP div 8)] := Byte(TexImg.Data[2 + ((TexImg.Width * j + i) * TexImg.BPP div 8)] - TexImg.Data[2 + ((TexImg.Width * j + (i - 1)) * TexImg.BPP div 8)]);
        if TexImg.BPP = 32 then
          Result.Data[8 + ((TexImg.Width * j + i) * TexImg.BPP div 8)] := Byte(TexImg.Data[3 + ((TexImg.Width * j + i) * TexImg.BPP div 8)] - TexImg.Data[3 + ((TexImg.Width * j + (i - 1)) * TexImg.BPP div 8)]);
        end;
end;

end.