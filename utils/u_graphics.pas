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

function TexFromTGA(Stream: TByteStream): TTexImage;

implementation

uses
  m_varlist;

type
  EUnsupportedTGAStream = class(Exception);
  EConversionError = class(Exception);

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
        raise EUnsupportedTGAStream.Create('Invalid Palette type');
      ImgType := Byte(TGA^); inc(TGA);
      PaletteStart := Word(TGA^); Inc(TGA, 2);
      PaletteLength := Word(TGA^); Inc(TGA, 2);
      if PaletteLength > 8192 then
        raise EUnsupportedTGAStream.Create('Unsupported palette length');
      BPPPalette := Byte(TGA^); Inc(TGA);
      if BPPPalette mod 8 <> 0 then
        raise EUnsupportedTGAStream.Create('Unsupported BPP value');
      OriginX := Word(TGA^); Inc(TGA, 2);
      OriginY := Word(TGA^); Inc(TGA, 2);
      Width := Word(TGA^); Inc(TGA, 2);
      Height := Word(TGA^); Inc(TGA, 2);
      BPP := Byte(TGA^); Inc(TGA);
      if BPPPalette mod 8 <> 0 then
        raise EUnsupportedTGAStream.Create('Unsupported BPP value');
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
        raise EUnsupportedTGAStream.Create('Unsupported image type');
      end;
  except
    on EUnsupportedTGAStream do ModuleManager.ModLog.AddError('Error loading TGA Stream: Unsupported stream');
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

end.