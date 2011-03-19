unit m_font_texture;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_font_class, m_texmng_class, m_shdmng_class, DGLOpenGL;

type
  TModuleFontTexture = class(TModuleFontClass)
    protected
      fTexture: TTexture;
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
  m_varlist;

function TModuleFontTexture.CalculateTextWidth(text: String; Size: Integer): Integer;
begin
  Result := Length(Text) * Size;
end;

function TModuleFontTexture.ConvertText(Input: String): String;
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

procedure TModuleFontTexture.Write(Text: String; Size, Left, Top: GLFLoat; R, G, B, A: GLFloat; Flags: Byte);
var
  i: Integer;
  PX, PY, X, Y: GLFloat;
begin
  Text := ConvertText(Text);

  X := Left;
  Y := Top;

  fTexture.Bind(0);

  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

  glEnable(GL_ALPHA_TEST);
  glAlphaFunc(GL_GREATER, 0.0);

  glBegin(GL_QUADS);
    glColor4f(R, G, B, A);
    for i := 1 to Length(Text) do
      case Text[i] of
        #9: X := X + 4 * 0.8 * Size;
        #10: begin X := Left; Y := Y + Size; end;
        #0: break;
      else
        py := Ord(Text[i]) div 16;
        px := Ord(Text[i]) - 16 * py;
        glTexCoord2f (px / 16,       py / 16);      glVertex2f(Round(X),        Round(Y));
        glTexCoord2f((px + 1) / 16,  py / 16);      glVertex2f(Round(X + Size), Round(Y));
        glTexCoord2f((px + 1) / 16, (py + 1) / 16); glVertex2f(Round(X + Size), Round(Y + Size));
        glTexCoord2f (px / 16,      (py + 1) / 16); glVertex2f(Round(X),        Round(Y + Size));
        X := X + Size;
        end;
  glEnd;
  fTexture.Unbind;
end;

procedure TModuleFontTexture.CheckModConf;
begin
  if GetConfVal('used') = '' then
    begin
    SetConfVal('used', '1');
    SetConfVal('fonttex', 'fonttexture/default.tga');
    end;
end;

constructor TModuleFontTexture.Create;
begin
  fModName := 'FontTexture';
  fModType := 'Font';

  CheckModConf;

  fTexture := TTexture.Create;
  fTexture.FromFile(GetConfVal('fonttex'));
  fTexture.SetClamp(GL_CLAMP, GL_CLAMP);
end;

destructor TModuleFontTexture.Free;
begin
  fTexture.Free;
end;

end.

