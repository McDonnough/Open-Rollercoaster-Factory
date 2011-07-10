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
function RGBAToHSVA(Input: DWord): DWord;
function HSVAToRGBA(Input: DWord): DWord;

function RGBAtoYCgCoA(Input: DWord): DWord; inline;
function YCgCoAtoRGBA(Input: DWord): DWord; inline;

function TexFromStream(Stream: TByteStream; Format: String): TTexImage;
function StreamFromTex(TexImg: TTexImage; Format: String): TByteStream;

function TexFromTGA(Stream: TByteStream): TTexImage;
function TexFromDBCG(Stream: TByteStream): TTexImage;

function TGAFromTex(TexImg: TTexImage; Flags: Integer = 32): TByteStream;
function DBCGFromTex(TexImg: TTexImage): TByteStream;

implementation

uses
  m_varlist, u_vectors, u_math, math, u_huffman, u_binutils;

type
  EUnsupportedStream = class(Exception);
  EConversionError = class(Exception);

  TPixel = record
    case Integer of
      0: (R, G, B, A: Byte);
      1: (Y, Cg, Co, O: Byte);
      2: (Value: DWord);
    end;
  PPixel = ^TPixel;

  TDBCGBlock = record
    HasReference, HasBias, HasGradient: Boolean;
    ChanSize: TPixel;
    Reference: Byte;
    Bias: TPixel;
    Gradient: Array[0..1, 0..1] of TPixel;
    Pixels: Array[0..63] of TPixel;
    end;

function TexFromStream(Stream: TByteStream; Format: String): TTexImage;
begin
  Result.BPP := 0;
  Result.Width := 0;
  Result.Height := 0;
  if Format = '.tga' then
    Result := TexFromTGA(Stream)
  else if Format = '.dbcg' then
    Result := TexFromDBCG(Stream);
end;

function StreamFromTex(TexImg: TTexImage; Format: String): TByteStream;
begin
  SetLength(Result.Data, 0);
  if Format = '.tga' then
    Result := TGAFromTex(TexImg)
  else if Format = '.dbcg' then
    Result := DBCGFromTex(TexImg);
end;

function RGBAToHSLA(Input: DWord): DWord;
var
  Color, Color2: TVector3D;
  mMin, mMax: Single;
begin
  Color.X := (Input and $000000FF) / 255;
  Color.Y := ((Input and $0000FF00) shr 8) / 255;
  Color.Z := ((Input and $00FF0000) shr 16) / 255;

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
  Color.X := (Input and $000000FF) / 255;
  Color.Y := ((Input and $0000FF00) shr 8) / 255;
  Color.Z := ((Input and $00FF0000) shr 16) / 255;

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

function RGBAToHSVA(Input: DWord): DWord;
var
  Color, Color2: TVector3D;
  mMin, mMax: Single;
begin
  Color.X := (Input and $000000FF) / 255;
  Color.Y := ((Input and $0000FF00) shr 8) / 255;
  Color.Z := ((Input and $00FF0000) shr 16) / 255;

  mMax := Max(Max(Color.X, Color.Y), Color.Z);
  mMin := Min(Min(Color.X, Color.Y), Color.Z);

  if mMax = mMin then
    Color2.X := 0
  else if mMax = Color.X then
    Color2.X := 60 * (0 + (Color.Y - Color.Z) / (mMax - mMin))
  else if mMax = Color.Y then
    Color2.X := 60 * (2 + (Color.Z - Color.X) / (mMax - mMin))
  else if mMax = Color.Z then
    Color2.X := 60 * (4 + (Color.X - Color.Y) / (mMax - mMin));

  if Color2.X < 0 then
    Color2.X := Color2.X + 360;

  Color2.X := Color2.X / 360;

  if mMax = 0 then
    Color2.Y := 0
  else
    Color2.Y := (mMax - mMin) / mMax;

  Color2.Z := mMax;

  Result := (Input and $FF000000) or (Round(Color2.Z * 255) shl 16) or (Round(Color2.Y * 255) shl 8) or (Round(Color2.X * 255));
end;

function HSVAToRGBA(Input: DWord): DWord;
var
  Color, Color2: TVector3D;
  f, p, q, t: Single;
  Hi: Integer;
begin
  Color.X := (Input and $000000FF) / 255 * 360;
  Color.Y := ((Input and $0000FF00) shr 8) / 255;
  Color.Z := ((Input and $00FF0000) shr 16) / 255;

  Hi := Round(Int(Color.X / 60));
  f := (Color.X / 60) - Hi;

  P := Color.Z * (1 - Color.Y);
  Q := Color.Z * (1 - Color.Y * f);
  T := Color.Z * (1 - Color.Y * (1 - f));

  case Hi of
    0, 6: Color2 := Vector(Color.Z, t, p);
    1: Color2 := Vector(q, Color.Z, p);
    2: Color2 := Vector(p, Color.Z, t);
    3: Color2 := Vector(p, q, Color.Z);
    4: Color2 := Vector(t, p, Color.Z);
    5: Color2 := Vector(Color.Z, p, q);
    end;

  Result := (Input and $FF000000) or (Round(Color2.Z * 255) shl 16) or (Round(Color2.Y * 255) shl 8) or (Round(Color2.X * 255));
end;

function RGBAtoYCgCoA(Input: DWord): DWord; inline;
var
  R, G, B: Byte;
  Y, Cg, Co: Integer;
begin
  R := Input;
  G := Input shr 8;
  B := Input shr 16;
  Y := R + (G shl 1) + B;
  Y := (((Y and $FFC) + ((Y and $02) shl 1)) shr 2) and $FF;
  Cg := -R + (G shl 1) - B + 512;
  Cg := (((Cg and $FFC) + ((Cg and $02) shl 1)) shr 2) and $FF;
  Co := R - B + 255;
  Co := (((Co and $FFE) + ((Co and $01) shl 1)) shr 1) and $FF;
  Result := Y or (Cg shl 8) or (Co shl 16) or (Input and $FF000000);
end;

function YCgCoAtoRGBA(Input: DWord): DWord; inline;
var
  tmp, Y, Cg, Co, R, G, B: Integer;
begin
  Y := Input and $FF;
  Cg := ((Input shr 8) and $FF) - 128;
  Co := ((Input shr 16) and $FF) - 128;
  tmp := Y - Cg;
  R := (tmp + Co) and $FF;
  G := (Y + Cg) and $FF;
  B := (tmp - Co) and $FF;
  Result := R or (G shl 8) or (B shl 16) or (Input and $FF000000);
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
      if BPPPalette and 7 <> 0 then
        raise EUnsupportedStream.Create('Unsupported BPP value');
      OriginX := Word(TGA^); Inc(TGA, 2);
      OriginY := Word(TGA^); Inc(TGA, 2);
      Width := Word(TGA^); Inc(TGA, 2);
      Height := Word(TGA^); Inc(TGA, 2);
      BPP := Byte(TGA^); Inc(TGA);
      if BPPPalette and 7 <> 0 then
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
  I, J, K, L: Integer;
  Blocks: Array of Array of TDBCGBlock;
  S, P: PByte;
  Q: PPixel;
  O: Byte;
  BytePP: Integer;
begin
  Result.BPP := Stream.Data[0];
  BytePP := Result.BPP shr 3;
  Result.Width := Word((@Stream.Data[1])^);
  Result.Height := Word((@Stream.Data[3])^);
  SetLength(Result.Data, Result.Width * Result.Height * Result.BPP div 8);
  SetLength(Blocks, Result.Width shr 3, Result.Height shr 3);

  P := @Stream.Data[5];
  O := 0;

  for I := 0 to high(Blocks) do
    for J := 0 to high(Blocks[I]) do
      with Blocks[I, J] do
        begin
        HasReference := ExtractBits(P, O, 1) = 1;
        HasBias := ExtractBits(P, O, 1) = 1;
        HasGradient := ExtractBits(P, O, 1) = 1;
        ChanSize.Y := ExtractBits(P, O, 4);
        ChanSize.Cg := ExtractBits(P, O, 4);
        ChanSize.Co := ExtractBits(P, O, 4);
        if BytePP = 4 then
          ChanSize.A := ExtractBits(P, O, 4)
        else
          ChanSize.A := 0;
        if HasReference then
          Reference := ExtractBits(P, O, 4) + 1
        else
          Reference := 0;
        if HasBias then
          begin
          Bias.Y := ExtractBits(P, O, 8);
          Bias.Cg := ExtractBits(P, O, 8);
          Bias.Co := ExtractBits(P, O, 8);
          if BytePP = 4 then
            Bias.A := ExtractBits(P, O, 8)
          else
            Bias.A := 0;
          end
        else
          begin
          Bias.Y := 0;
          Bias.Cg := 0;
          Bias.Co := 0;
          Bias.A := 0;
          end;
        if HasGradient then
          for K := 0 to 1 do
            for L := 0 to 1 do
              begin
              Gradient[K, L].Y := ExtractBits(P, O, 8);
              Gradient[K, L].Cg := ExtractBits(P, O, 8);
              Gradient[K, L].Co := ExtractBits(P, O, 8);
              if BytePP = 4 then
                Gradient[K, L].A := ExtractBits(P, O, 8);
              end;
        Q := @Pixels[0];
        for K := 0 to 63 do
          begin
          Q^.Y := ExtractBits(P, O, ChanSize.Y) + Bias.Y;
          Q^.Cg := ExtractBits(P, O, ChanSize.Cg) + Bias.Cg;
          Q^.Co := ExtractBits(P, O, ChanSize.Co) + Bias.Co;
          Q^.A := ExtractBits(P, O, ChanSize.A) + Bias.A;
          Q^.Value := YCgCoAtoRGBA(Q^.Value);
          inc(Q);
          end;
        Q := @Pixels[0];
        for K := 0 to 7 do
          begin
          S := @Result.Data[BytePP * Result.Width * (8 * J + K) + BytePP * 8 * I];
          for L := 0 to 7 do
            begin
            S^ := Q^.R; inc(S);
            S^ := Q^.G; inc(S);
            S^ := Q^.B; inc(S);
            if BytePP = 4 then
              begin
              S^ := Q^.A;
              inc(S);
              end;
            inc(Q);
            end;
          end;
        end;
end;

function TGAFromTex(TexImg: TTexImage; Flags: Integer = 32): TByteStream;
var
  i, j: Integer;
  ByPP: Integer;
begin
  ByPP := TexImg.BPP div 8;
  SetLength(Result.Data, 18 + TexImg.Width * TexImg.Height * ByPP + 26);
  Result.Data[0] := 0;
  Result.Data[1] := 0;
  Result.Data[2] := 2;
  Word((@Result.Data[3])^) := 0;
  Word((@Result.Data[5])^) := 0;
  Result.Data[7] := TexImg.BPP;
  Word((@Result.Data[8])^) := 0;
  Word((@Result.Data[10])^) := 0;
  Word((@Result.Data[12])^) := TexImg.Width;
  Word((@Result.Data[14])^) := TexImg.Height;
  Result.Data[16] := TexImg.BPP;
  Result.Data[17] := Flags;
  for i := 0 to high(TexImg.Data) div 4 do
    begin
    Result.Data[18 + ByPP * i + 0] := TexImg.Data[ByPP * i + 2];
    Result.Data[18 + ByPP * i + 1] := TexImg.Data[ByPP * i + 1];
    Result.Data[18 + ByPP * i + 2] := TexImg.Data[ByPP * i + 0];
    if ByPP = 4 then
      Result.Data[18 + ByPP * i + 3] := TexImg.Data[ByPP * i + 3];
    end;
  DWord((@Result.Data[Length(Result.Data) - 26])^) := 0;
  DWord((@Result.Data[Length(Result.Data) - 22])^) := 0;
  Result.Data[Length(Result.Data) - 18] := Ord('T');
  Result.Data[Length(Result.Data) - 17] := Ord('R');
  Result.Data[Length(Result.Data) - 16] := Ord('U');
  Result.Data[Length(Result.Data) - 15] := Ord('E');
  Result.Data[Length(Result.Data) - 14] := Ord('V');
  Result.Data[Length(Result.Data) - 13] := Ord('I');
  Result.Data[Length(Result.Data) - 12] := Ord('S');
  Result.Data[Length(Result.Data) - 11] := Ord('I');
  Result.Data[Length(Result.Data) - 10] := Ord('O');
  Result.Data[Length(Result.Data) - 09] := Ord('N');
  Result.Data[Length(Result.Data) - 08] := Ord('-');
  Result.Data[Length(Result.Data) - 07] := Ord('X');
  Result.Data[Length(Result.Data) - 06] := Ord('F');
  Result.Data[Length(Result.Data) - 05] := Ord('I');
  Result.Data[Length(Result.Data) - 04] := Ord('L');
  Result.Data[Length(Result.Data) - 03] := Ord('E');
  Result.Data[Length(Result.Data) - 02] := Ord('.');
  Result.Data[Length(Result.Data) - 01] := 0;
end;

function DBCGFromTex(TexImg: TTexImage): TByteStream;
var
  BytePP, I, J, K, L: Integer;
  P: PByte;
  Q: PPixel;
  Blocks: Array of Array of TDBCGBlock;
  O: Byte;
  BytesWritten: Integer;
const
  BoolToInt: Array[Boolean] of Byte = (0, 1);
begin
  SetLength(Result.Data, 5 + (TexImg.BPP div 8 + 1) * TexImg.Height * TexImg.Width);

  P := @Result.Data[0];
  for I := 0 to high(Result.Data) do
    begin
    P^ := 0;
    inc(P);
    end;

  Result.Data[0] := TexImg.BPP;
  Word((@Result.Data[1])^) := TexImg.Width;
  Word((@Result.Data[3])^) := TexImg.Height;

  BytePP := TexImg.BPP shr 3;
  SetLength(Blocks, TexImg.Width shr 3, TexImg.Height shr 3);
  for I := 0 to high(Blocks) do
    for J := 0 to high(Blocks[i]) do
      begin
      with Blocks[I, J] do
        begin
        HasReference := False;
        HasBias := False;
        HasGradient := False;
        ChanSize.Y := 0;
        ChanSize.Cg := 0;
        ChanSize.Co := 0;
        ChanSize.A := 0;
        Bias.Y := 255;
        Bias.Cg := 255;
        Bias.Co := 255;
        Bias.A := 255;
        Gradient[0, 0] := ChanSize;
        Gradient[0, 1] := ChanSize;
        Gradient[1, 0] := ChanSize;
        Gradient[0, 1] := ChanSize;

        Q := @Pixels[0];
        for K := 0 to 7 do
          begin
          P := @TexImg.Data[BytePP * TexImg.Width * (8 * J + K) + BytePP * 8 * I];
          for L := 0 to 7 do
            begin
            Q^.R := P^; inc(P);
            Q^.G := P^; inc(P);
            Q^.B := P^; inc(P);
            if BytePP = 4 then
              begin
              Q^.A := P^;
              if P^ = 0 then
                Q^.Value := 0;
              inc(P);
              end
            else
              Q^.A := $FF;
            Inc(Q);
            end;
          end;
        Q := @Pixels[0];
        for K := 0 to 63 do
          begin
          Q^.Value := RGBAtoYCgCoA(Q^.Value);
          Bias.Y := Min(Bias.Y, Q^.Y);
          Bias.Cg := Min(Bias.Cg, Q^.Cg);
          Bias.Co := Min(Bias.Co, Q^.Co);
          Bias.A := Min(Bias.A, Q^.A);
          inc(Q);
          end;
        HasBias := Max(Max(Bias.Y, Bias.Cg), Max(Bias.Co, Bias.A)) > 0;
        Q := @Pixels[0];
        for K := 0 to 63 do
          begin
          Q^.Y := Q^.Y - Bias.Y;
          Q^.Cg := Q^.Cg - Bias.Cg;
          Q^.Co := Q^.Co - Bias.Co;
          Q^.A := Q^.A - Bias.A;
          if Q^.Y <> 0 then
            ChanSize.Y := Max(ChanSize.Y, Round(Int(Log2(Q^.Y))) + 1);
          if Q^.Cg <> 0 then
            ChanSize.Cg := Max(ChanSize.Cg, Round(Int(Log2(Q^.Cg))) + 1);
          if Q^.Co <> 0 then
            ChanSize.Co := Max(ChanSize.Co, Round(Int(Log2(Q^.Co))) + 1);
          if Q^.A <> 0 then
            ChanSize.A := Max(ChanSize.A, Round(Int(Log2(Q^.A))) + 1);
          inc(Q);
          end;
        end;
      end;

  O := 0;
  P := @Result.Data[5];
  BytesWritten := 5;

  for I := 0 to high(Blocks) do
    for J := 0 to high(Blocks[I]) do
      with Blocks[I, J] do
        begin
        AppendBits(P, O, BytesWritten, BoolToInt[HasReference], 1);
        AppendBits(P, O, BytesWritten, BoolToInt[HasBias], 1);
        AppendBits(P, O, BytesWritten, BoolToInt[HasGradient], 1);
        AppendBits(P, O, BytesWritten, ChanSize.Y, 4);
        AppendBits(P, O, BytesWritten, ChanSize.Cg, 4);
        AppendBits(P, O, BytesWritten, ChanSize.Co, 4);
        if BytePP = 4 then
          AppendBits(P, O, BytesWritten, ChanSize.A, 4);
        if HasReference then
          AppendBits(P, O, BytesWritten, Reference - 1, 4);
        if HasBias then
          begin
          AppendBits(P, O, BytesWritten, Bias.Y, 8);
          AppendBits(P, O, BytesWritten, Bias.Cg, 8);
          AppendBits(P, O, BytesWritten, Bias.Co, 8);
          if BytePP = 4 then
            AppendBits(P, O, BytesWritten, Bias.A, 8);
          end;
        if HasGradient then
          for K := 0 to 1 do
            for L := 0 to 1 do
              begin
              AppendBits(P, O, BytesWritten, Gradient[K, L].Y, 8);
              AppendBits(P, O, BytesWritten, Gradient[K, L].Cg, 8);
              AppendBits(P, O, BytesWritten, Gradient[K, L].Co, 8);
              if BytePP = 4 then
                AppendBits(P, O, BytesWritten, Gradient[K, L].A, 8);
              end;
        Q := @Pixels[0];
        for K := 0 to 63 do
          begin
          AppendBits(P, O, BytesWritten, Q^.Y, ChanSize.Y);
          AppendBits(P, O, BytesWritten, Q^.Cg, ChanSize.Cg);
          AppendBits(P, O, BytesWritten, Q^.Co, ChanSize.Co);
          if BytePP = 4 then
            AppendBits(P, O, BytesWritten, Q^.A, ChanSize.A);
          inc(Q);
          end;
        end;
  SetLength(Result.Data, BytesWritten);
end;

end.