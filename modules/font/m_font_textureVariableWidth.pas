unit m_font_textureVariableWidth;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_font_class, m_texmng_class, m_shdmng_class, DGLOpenGL, u_graphics, u_math;

type
  TLetterPosition = record
    firstPixel, lastPixel, width: byte;
  end;
  TModuleFontTextureVariableWidth = class(TModuleFontClass)
    private
      refCellWidth, refCellHeight: integer;
    protected
      TempTex: TTexImage;
      fTexture: TTexture;
      fLetterPositions: array[0..255] of TLetterPosition;
      procedure GetLetterWidths;
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
  m_varlist, u_files;

procedure TModuleFontTextureVariableWidth.GetLetterWidths;
var
  i: Byte;
  j, k: Word;
  currentX, currentY: Word;
  currentAlpha: Byte;
  searchingFirstPixel: boolean;
  tmpX1, tmpX2: byte;
begin
  refCellWidth := round(fTexture.Width / 16);
  refCellHeight := round(fTexture.Height / 16);
  for i := 0 to 255 do
    begin
  	currentX := (i mod 16);
  	currentY := round((i - currentX) / 16) * refCellHeight;
  	currentX := currentX * refCellWidth;
  	searchingFirstPixel := true;
  	for j := 0 to refCellWidth - 1 do
  	  begin
  	  for k := 0 to refCellHeight - 1 do
  	    begin
  	    currentAlpha := (fTexture.Pixels[currentX + j, currentY + k] AND $FF000000) SHR 24;
  	    if currentAlpha >= 1 then
  	      begin
  	      if searchingFirstPixel then
  	        begin
  	        tmpX1 := j;
  	        tmpX2 := j;
  	        searchingFirstPixel := false;
  	        end
  	      else
  	        begin
  	        tmpX2 := j;
  	        end;
  	      end;
  	    end;
  	  end;
  	if searchingFirstPixel then
  	  begin
  	  tmpX1 := 0;
  	  tmpX2 := refCellWidth;
  	  end;
  	fLetterPositions[i].firstPixel := tmpX1;
  	fLetterPositions[i].width := tmpX2 - tmpX1;
  	fLetterPositions[i].lastPixel := tmpX2;
    end;
end;

procedure TModuleFontTextureVariableWidth.Write(Text: String; Size, Left, Top: GLFLoat; R, G, B, A: GLFloat; Flags: Byte);
var
  px, py: Integer;
  X, Y: GLFloat;
  i: integer;
  widthFac: single;
begin
  Text := ConvertText(Text);
  X := Left;
  Y := Top;
  widthFac := Size / refCellHeight;
  fTexture.Bind();
  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  glEnable(GL_ALPHA_TEST);
  glAlphaFunc(GL_GREATER, 0.0);
  glBegin(GL_QUADS);
  glColor4f(R, G, B, A);
  X := Left;
    for i := 1 to Length(Text) do
      case Text[i] of
        #9: X := X + 4 * 0.8 * Size;
        #10: begin X := Left; Y := Y + Size; end;
        #0: break;
        #32: begin X := X + Size / 3; end;
      else
        py := Ord(Text[i]) div 16;
        px := Ord(Text[i]) - 16 * py;
        glTexCoord2f (px / 16 + fLetterPositions[Ord(Text[i])].firstPixel / (refCellHeight * 16),       py / 16);
        glVertex2f(Round(X),        Round(Y));
        glTexCoord2f((px + 1) / 16 - (refCellWidth - fLetterPositions[Ord(Text[i])].lastPixel) / (refCellHeight * 16),  py / 16);
        glVertex2f(Round(X + fLetterPositions[Ord(Text[i])].width * widthFac), Round(Y));
        glTexCoord2f((px + 1) / 16 - (refCellWidth - fLetterPositions[Ord(Text[i])].lastPixel) / (refCellHeight * 16), (py + 1) / 16);
        glVertex2f(Round(X + fLetterPositions[Ord(Text[i])].width * widthFac), Round(Y + Size));
        glTexCoord2f (px / 16 + fLetterPositions[Ord(Text[i])].firstPixel / (refCellHeight * 16),      (py + 1) / 16);
        glVertex2f(Round(X),        Round(Y + Size));
        X := X + round(fLetterPositions[Ord(Text[i])].width * widthFac) + fLetterSpacing;
        end;
  glEnd;
  fTexture.Unbind;
end;

function TModuleFontTextureVariableWidth.CalculateTextWidth(text: String; Size: Integer): Integer;
var
  i: integer;
  width, widthFac: single;
begin
  width := 0;
  widthFac := Size / refCellHeight;
  for i := 1 to Length(Text) do
    case Text[i] of
      #9: width := width + 4 * 0.8 * Size;
      #0: break;
      #32: begin width := width + Size / 3; end;
    else
      width := width + round(fLetterPositions[Ord(Text[i])].width * widthFac) + fLetterSpacing;
      end;
  result := round(width);
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
  if GetConfVal('used') = '' then
    begin
    SetConfVal('used', '1');
    SetConfVal('fonttex', 'fonttexture/default.tga');
    end;
end;

constructor TModuleFontTextureVariableWidth.Create;
begin
  fModName := 'FontTextureVariableWidth';
  fModType := 'Font';

  CheckModConf;

  temptex := TexFromTGA(ByteStreamFromFile(GetFirstExistingFileName(GetConfVal('fonttex'))));
  fTexture := TTexture.Create;
  fTexture.CreateNew(TempTex.Width, TempTex.Height, GL_RGBA);
  fTexture.SetClamp(GL_CLAMP, GL_CLAMP);
  fTexture.SetFilter(GL_LINEAR_MIPMAP_LINEAR, GL_LINEAR_MIPMAP_LINEAR);
  gluBuild2DMipmaps(GL_TEXTURE_2D, TempTex.BPP div 8, Temptex.Width, Temptex.Height, GL_RGBA, GL_UNSIGNED_BYTE, @TempTex.Data[0]);

  GetLetterWidths;

  fLetterSpacing := 3;
end;

destructor TModuleFontTextureVariableWidth.Free;
begin
  fTexture.Free;
end;

end.
