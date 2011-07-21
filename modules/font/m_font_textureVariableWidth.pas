unit m_font_textureVariableWidth;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_font_class, m_texmng_class, m_shdmng_class, DGLOpenGL, u_graphics, u_math, g_loader_ocf;

type
  TLetterPosition = record
    FirstPixel, Width: byte;
    end;

  TFontTexture = record
    MinSize, MaxSize: Integer;
    Texture: TTexture;
    LetterPositions: Array[0..255] of TLetterPosition;
    end;

  TModuleFontTextureVariableWidth = class(TModuleFontClass)
    protected
      fTextures: Array of TFontTexture;
      procedure GetLetterWidth(Tex: Integer);
      function ConvertText(Input: String): String;
    public
      procedure Write(Text: String; Size, Left, Top: GLFLoat; R, G, B, A: GLFloat; Flags: Byte);
      function CalculateTextWidth(text: String; Size: Integer): Integer;
      procedure CheckModConf;
      constructor Create;
      destructor Free;
  end;

implementation

uses
  m_varlist, u_files, u_dom, u_functions, u_arrays;

procedure TModuleFontTextureVariableWidth.GetLetterWidth(Tex: Integer);
var
  i, j, k, l: Integer;
  doBreak: Boolean;
  CellWidth, CellHeight: Integer;
begin
  CellWidth := fTextures[Tex].Texture.Width div 16;
  CellHeight := fTextures[Tex].Texture.Height div 16;
  for i := 0 to 15 do
    for j := 0 to 15 do
      begin
      fTextures[Tex].LetterPositions[16 * j + i].FirstPixel := 0;
      fTextures[Tex].LetterPositions[16 * j + i].Width := CellWidth;
      doBreak := false;
      for k := 0 to CellWidth - 1 do
        begin
        for l := 0 to CellHeight - 1 do
          if fTextures[Tex].Texture.Pixels[CellWidth * i + k, CellHeight * j + l] and $FF000000 > $7F000000 then
            begin
            fTextures[Tex].LetterPositions[16 * j + i].FirstPixel := k;
            doBreak := true;
            break;
            end;
        if doBreak then
          break;
        end;

      doBreak := false;
      for k := CellWidth - 1 downto 0 do
        begin
        for l := 0 to CellHeight - 1 do
          if fTextures[Tex].Texture.Pixels[CellWidth * i + k, CellHeight * j + l] and $FF000000 > $7F000000 then
            begin
            fTextures[Tex].LetterPositions[16 * j + i].Width := k - fTextures[Tex].LetterPositions[16 * j + i].FirstPixel + 1;
            doBreak := true;
            break;
            end;
        if doBreak then
          break;
        end;
      end;
end;

procedure TModuleFontTextureVariableWidth.Write(Text: String; Size, Left, Top: GLFLoat; R, G, B, A: GLFloat; Flags: Byte);
var
  px, py: Integer;
  X, Y: Integer;
  i, BoundTexture: integer;
  LO: Integer;
begin
  if (Size = 0) or (Text = '') or (A = 0) then
    exit;
  Text := ConvertText(Text);
  X := Round(Left);
  Y := Round(Top);
  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  glEnable(GL_ALPHA_TEST);
  glAlphaFunc(GL_GREATER, 0.0);
  BoundTexture := 0;
  for i := 0 to high(fTextures) do
    if (Size >= fTextures[i].MinSize) and (Size < fTextures[i].MaxSize) then
      begin
      fTextures[i].Texture.Bind(0);
      BoundTexture := i;
      end;
  glBegin(GL_QUADS);
  glColor4f(R, G, B, A);
  for i := 1 to length(Text) do
    begin
    py := Ord(Text[i]) div 16;
    px := Ord(Text[i]) and 15;

    LO := Round(fTextures[BoundTexture].LetterPositions[Ord(Text[i])].FirstPixel * Size / (fTextures[BoundTexture].Texture.Width / 16));

    glTexCoord2f(px / 16, py / 16); glVertex2f(X - LO, Y);
    glTexCoord2f((px + 1) / 16, py / 16); glVertex2f(X + Size - LO, Y);
    glTexCoord2f((px + 1) / 16, (py + 1) / 16); glVertex2f(X + Size - LO, Y + Size);
    glTexCoord2f(px / 16, (py + 1) / 16); glVertex2f(X - LO, Y + Size);

    case Text[i] of
      #9: X := Round(X + 2.4 * Size);
      #10: begin X := Round(Left); Y := Round(Y + Size); end;
      #0: break;
      #32: X := Round(X + Size / 3);
      else X := Round(X + (fLetterSpacing * Size / 32) + fTextures[BoundTexture].LetterPositions[Ord(Text[i])].Width * Size / (fTextures[BoundTexture].Texture.Width / 16));
      end;
    end;
  glEnd;
  fTextures[BoundTexture].Texture.Unbind;
  glDisable(GL_BLEND);
  glDisable(GL_ALPHA_TEST);
end;

function TModuleFontTextureVariableWidth.CalculateTextWidth(text: String; Size: Integer): Integer;
var
  i, BoundTexture: integer;
  a: TRow;
begin
  Result := 0;
  BoundTexture := 0;
  for i := 0 to high(fTextures) do
    if (Size >= fTextures[i].MinSize) and (Size < fTextures[i].MaxSize) then
      begin
//       fTextures[i].Texture.Bind(0);
      BoundTexture := i;
      end;
  A := TRow.Create;
  for i := 1 to Length(Text) do
    case Text[i] of
      #9: Result := Round(Result + 2.4 * Size);
      #10: begin A.Insert(0, Result); Result := 0; end;
      #0: break;
      #32: Result := Round(Result + Size / 3);
      else Result := Round(Result + (fLetterSpacing * Size / 32) + fTextures[BoundTexture].LetterPositions[Ord(Text[i])].Width * Size / (fTextures[BoundTexture].Texture.Width / 16));
      end;
  A.Insert(0, Result);
  Result := A.Max;
  A.Free;
//   fTextures[BoundTexture].Texture.Unbind;
end;

function TModuleFontTextureVariableWidth.ConvertText(Input: String): String;
var
  i: integer;
begin
  Result := '';
  for i := 1 to length(Input) do
    if Input[i] = #195 then
      Result := Result + char(ord(Input[i + 1]) + 64)
    else if Input[i - 1] <> #195 then
      Result := Result + Input[i];
end;

procedure TModuleFontTextureVariableWidth.CheckModConf;
begin
  if GetConfVal('used') <> '1' then
    begin
    SetConfVal('used', '1');
    SetConfVal('fonttex', 'fontocf/default.ocf');
    end;
end;

constructor TModuleFontTextureVariableWidth.Create;
var
  i: Integer;
  fOCF: TOCFFile;
  e: TDOMElement;
  TempTex: TTexImage;
begin
  fModName := 'FontTextureVariableWidth';
  fModType := 'Font';

  CheckModConf;

  writeln('Loading font textures from ' + GetFirstExistingFileName(GetConfVal('fonttex')));
  fOCF := TOCFFile.Create(GetFirstExistingFileName(GetConfVal('fonttex')));
  e := TDOMElement(fOCF.XML.Document.GetElementsByTagName('fonttexture')[0].FirstChild);
  while e <> nil do
    begin
    if e.nodeName = 'texture' then
      with e do
        begin
        setLength(fTextures, length(fTextures) + 1);
        i := high(fTextures);
        fTextures[i].MinSize := StrToIntWD(GetAttribute('minsize'), 0);
        fTextures[i].MaxSize := StrToIntWD(GetAttribute('maxsize'), 1024);
        TempTex := TexFromStream(fOCF.Bin[fOCF.Resources[StrToIntWD(GetAttribute('resource:id'), 0)].Section].Stream, '.' + fOCF.Resources[StrToIntWD(GetAttribute('resource:id'), 0)].Format);
        fTextures[i].Texture := TTexture.Create;
        fTextures[i].Texture.FromTexImage(TempTex);
        GetLetterWidth(i);
        fTextures[i].Texture.Unbind;
        end;
    e := TDOMElement(e.nextSibling);
    end;

  fOCF.Free;

  fLetterSpacing := 3;
end;

destructor TModuleFontTextureVariableWidth.Free;
var
  i: Integer;
begin
  for i := 0 to high(fTextures) do
    fTextures[i].Texture.Free;
end;

end.