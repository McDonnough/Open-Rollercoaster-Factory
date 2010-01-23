unit m_texmng_default;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_texmng_class, DGLOpenGL;

type
  TTexRef = record
    Tex: GLUInt;
    TexName: String;
    X, Y: Integer;
    Format: GLEnum;
    end;

  ATexRef = array of TTexRef;

  TModuleTextureManagerDefault = class(TModuleTextureManagerClass)
    protected
      fTexRefs: ATexRef;
      fCurrentTextures: array[0..7] of Integer;
      fCurrentTexUnit: Integer;
    public
      constructor Create;
      procedure CheckModConf;
      function LoadTexture(Filename: String; VertexTexture: Boolean; var X, Y: Integer): Integer;
      function EmptyTexture(X, Y: Integer; Format: GLEnum): Integer;
      procedure ActivateTexUnit(U: Integer);
      procedure BindTexture(Texture: Integer);
      procedure FillTexture(Texture: Integer; Data: Pointer; InputFormat: GLEnum);
      procedure DeleteTexture(Texture: Integer);
      procedure SetFilter(Texture: Integer; Min, Mag: GLEnum);
      procedure SetClamp(Texture: Integer; X, Y: GLEnum);
      destructor Free;
    end;

implementation

uses
  m_varlist;

type
  TTexture = record
    InputFormat, ExternalFormat: GLEnum;
    Width, Height: Integer;
    Data: array of Byte;
    end;


constructor TModuleTextureManagerDefault.Create;
var
  i: integer;
begin
  fModName := 'TextureManagerDefault';
  fModType := 'TextureManager';

  glEnable(GL_TEXTURE_2D);
  for i := 0 to 7 do
    fCurrentTextures[fCurrentTexUnit] := -1;
  ActivateTexUnit(0);
end;

procedure TModuleTextureManagerDefault.CheckModConf;
begin

end;

function TModuleTextureManagerDefault.LoadTexture(Filename: String; VertexTexture: Boolean; var X, Y: Integer): Integer;
var
  Texture: TTexture;

  procedure LoadTga;
  type
    TTGAFile = record
      iType: byte;
      w, h: word;
      bpp: byte;
      end;
  var
    TGAFile: TTGAFile;

    function GetTGAFile: TTGAFile;
    var
      f: file;
      bytes: longword;
    begin
      assign(f, filename);
      reset(f, 1);

      seek(f, 2);
      blockread(f, result.iType, 1);

      seek(f, 12);
      blockread(f, result.w, 5);
      result.bpp := result.bpp div 8;

      Bytes := Result.W * Result.H * Result.bpp;
      setlength(Texture.Data, Bytes);
      seek(f, 18);
      blockread(f, Texture.Data[0], Bytes);

      close(f);
    end;
  begin
    try
      TGAFile := GetTGAFile;
      if TGAFile.bpp = 3 then
        begin
        Texture.InputFormat := GL_BGR;
        Texture.ExternalFormat := GL_RGB;
        end
      else
        begin
        Texture.InputFormat := GL_BGRA;
        Texture.ExternalFormat := GL_RGBA;
        end;
      Texture.Width := TGAFile.w;
      Texture.Height := TGAFile.h;
    except
      ModuleManager.ModLog.AddWarning('File ' + filename + ' not loadable', 'm_texmng_default.pas', 122);
    end;
  end;

var
  i: integer;
begin
  X := -1;
  Y := -1;
  if not FileExists(Filename) then
    begin
    ModuleManager.ModLog.AddWarning('Texture ' + filename + ' does not exist', 'm_texmng_default', 133);
    exit;
    end;
  if not FileExists(FileName) then
    exit(-2);
  if lowercase(extractFileExt(Filename)) = '.tga' then
    LoadTga
  else
    exit(-1);
  if VertexTexture then
    FileName := 'vertex:' + FileName;
  for i := 0 to high(fTexRefs) do
    if (fTexRefs[i].TexName = FileName) and (fTexRefs[i].Tex <> GLUInt(-1)) then
      begin
      X := fTexRefs[i].X;
      Y := fTexRefs[i].Y;
      exit(i);
      end;
  with Texture do
    begin
    X := Width;
    Y := Height;
    if not VertexTexture then
      Result := EmptyTexture(Width, Height, ExternalFormat)
    else
      Result := EmptyTexture(Width, Height, GL_RGBA32F_ARB);
    FillTexture(Result, @Data[0], InputFormat);
    fTexRefs[Result].TexName := FileName;
    end;
end;

function TModuleTextureManagerDefault.EmptyTexture(X, Y: Integer; Format: GLEnum): Integer;
begin
  SetLength(fTexRefs, length(fTexRefs) + 1);
  Result := high(fTexRefs);
  fTexRefs[Result].TexName := 'Custom:' + IntToStr(Result);
  fTexRefs[Result].Format := Format;
  fTexRefs[Result].X := X;
  fTexRefs[Result].Y := Y;
  glGenTextures(1, @fTexRefs[result].Tex);
  BindTexture(Result);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexImage2D(GL_TEXTURE_2D, 0, Format, X, Y, 0, GL_BGRA, GL_UNSIGNED_BYTE, nil);
end;

procedure TModuleTextureManagerDefault.ActivateTexUnit(U: Integer);
begin
  if fCurrentTexUnit = U then
    exit;
  fCurrentTexUnit := U;
  glActiveTexture(GL_TEXTURE0 + U);
end;

procedure TModuleTextureManagerDefault.BindTexture(Texture: Integer);
begin
  if fCurrentTextures[fCurrentTexUnit] = Texture then
    exit;
  if (Texture >= 0) and (Texture <= high(fTexRefs)) then
    glBindTexture(GL_TEXTURE_2D, fTexRefs[Texture].Tex)
  else
    glBindTexture(GL_TEXTURE_2D, 0);
  fCurrentTextures[fCurrentTexUnit] := Texture;
end;

procedure TModuleTextureManagerDefault.FillTexture(Texture: Integer; Data: Pointer; InputFormat: GLEnum);
begin
  BindTexture(Texture);
  if (Texture >= 0) and (Texture <= high(fTexRefs)) then
    with fTexRefs[Texture] do
      glTexImage2D(GL_TEXTURE_2D, 0, Format, X, Y, 0, InputFormat, GL_UNSIGNED_BYTE, Data);
end;

procedure TModuleTextureManagerDefault.DeleteTexture(Texture: Integer);
begin
  if (Texture >= 0) and (Texture <= high(fTexRefs)) then
    begin
    BindTexture(-1);
    glDeleteTextures(1, @fTexRefs[Texture].Tex);
    fTexRefs[Texture].Tex := -1;
    end;
end;

procedure TModuleTextureManagerDefault.SetFilter(Texture: Integer; Min, Mag: GLEnum);
begin
  BindTexture(Texture);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, Mag);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, Min);
end;

procedure TModuleTextureManagerDefault.SetClamp(Texture: Integer; X, Y: GLEnum);
begin
  BindTexture(Texture);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, X);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, Y);
end;

destructor TModuleTextureManagerDefault.Free;
var
  i: integer;
begin
  for i := 0 to high(fTexRefs) do
    DeleteTexture(i);
end;

end.

