unit m_texmng_default;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_texmng_class, DGLOpenGL;

type
  TTexRef = record
    InputFormat, ExternalFormat: GLEnum;
    Width, Height: Integer;
    Data: array of Byte;
    Tex: GLUInt;
    TexName: String;
    end;

  ATexRef = array of TTexRef;

  TModuleTextureManagerDefault = class(TModuleTextureManagerClass)
    protected
      fTexRefs: ATexRef;
      fCurrentTextures: array[0..31] of Integer;
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
      function ReadPixel(Texture: Integer; X, Y: Integer): DWord;
      procedure SetPixel(Texture: Integer; X, Y: Integer; Color: DWord);
      function GetRealTexID(Tex: Integer): GLUInt;
      destructor Free;
    end;

implementation

uses
  m_varlist, u_files, u_graphics;

constructor TModuleTextureManagerDefault.Create;
var
  i: integer;
begin
  fModName := 'TextureManagerDefault';
  fModType := 'TextureManager';

  glEnable(GL_TEXTURE_2D);
  for i := 0 to high(fCurrentTextures) do
    fCurrentTextures[i] := -1;
  ActivateTexUnit(0);
end;

procedure TModuleTextureManagerDefault.CheckModConf;
begin

end;

function TModuleTextureManagerDefault.LoadTexture(Filename: String; VertexTexture: Boolean; var X, Y: Integer): Integer;
var
  Texture: TTexRef;
  TexImage: TTexImage;
  i: Integer;
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
    TexImage := TexFromTGA(ByteStreamFromFile(filename))
  else if lowercase(extractFileExt(Filename)) = '.ocg' then
    TexImage := TexFromOCG(ByteStreamFromFile(filename))
  else
    exit(-1);
  try
    if TexImage.bpp = 24 then
      begin
      Texture.InputFormat := GL_RGB;
      Texture.ExternalFormat := GL_RGB;
      end
    else
      begin
      Texture.InputFormat := GL_RGBA;
      Texture.ExternalFormat := GL_RGBA;
      end;
    Texture.Width := TexImage.width;
    Texture.Height := TexImage.height;
    setLength(Texture.Data, length(TexImage.Data));
    for i := 0 to high(Texture.Data) do
      Texture.Data[i] := TexImage.Data[i];
  except
    ModuleManager.ModLog.AddWarning('File ' + filename + ' not loadable', 'm_texmng_default.pas', 122);
  end;
  if VertexTexture then
    FileName := 'vertex:' + FileName;
  for i := 0 to high(fTexRefs) do
    if (fTexRefs[i].TexName = FileName) and (fTexRefs[i].Tex <> GLUInt(-1)) then
      begin
      X := fTexRefs[i].Width;
      Y := fTexRefs[i].Height;
      exit(i);
      end;
  X := Texture.Width;
  Y := Texture.Height;
  if VertexTexture then
    Texture.ExternalFormat := GL_RGBA32F_ARB;
  Result := EmptyTexture(Texture.Width, Texture.Height, Texture.ExternalFormat);
  fTexRefs[Result].TexName := Texture.TexName;
  fTexRefs[Result].Width := Texture.Width;
  fTexRefs[Result].Height := Texture.Height;
  fTexRefs[Result].InputFormat := Texture.InputFormat;
  fTexRefs[Result].ExternalFormat := Texture.ExternalFormat;
  FillTexture(Result, @Texture.Data[0], Texture.InputFormat);
end;

function TModuleTextureManagerDefault.EmptyTexture(X, Y: Integer; Format: GLEnum): Integer;
var
  i: Integer;
begin
  SetLength(fTexRefs, length(fTexRefs) + 1);
  Result := high(fTexRefs);
  fTexRefs[Result].TexName := 'Custom:' + IntToStr(Result);
  fTexRefs[Result].ExternalFormat := Format;
  fTexRefs[Result].InputFormat := GL_BGRA;
  fTexRefs[Result].Width := X;
  fTexRefs[Result].Height := Y;
  SetLength(fTexRefs[Result].Data, 4 * X * Y);
  for i := 0 to high(fTexRefs[Result].Data) do
    fTexRefs[Result].Data[i] := 255;
  glGenTextures(1, @fTexRefs[result].Tex);
  BindTexture(Result);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexImage2D(GL_TEXTURE_2D, 0, Format, X, Y, 0, GL_BGRA, GL_UNSIGNED_BYTE, nil);
end;

procedure TModuleTextureManagerDefault.ActivateTexUnit(U: Integer);
begin
  if (fCurrentTexUnit = U) or (U < 0) or (U > high(fCurrentTextures)) then
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
var
  i, j: Integer;
begin
  BindTexture(Texture);
  fTexRefs[Texture].InputFormat := InputFormat;
  if (Data <> @fTexRefs[Texture].Data[0]) and (Data <> nil) then
    begin
    j := 4;
    if (InputFormat = GL_RGB) or (InputFormat = GL_BGR) then
      j := 3;
    setLength(fTexRefs[Texture].Data, j * fTexRefs[Texture].Width * fTexRefs[Texture].Height);
    for i := 0 to high(fTexRefs[Texture].Data) do
      fTexRefs[Texture].Data[i] := Byte(Pointer(PtrUInt(Data) + i)^);
    end;
  if (Texture >= 0) and (Texture <= high(fTexRefs)) then
    glTexImage2D(GL_TEXTURE_2D, 0, fTexRefs[Texture].ExternalFormat, fTexRefs[Texture].Width, fTexRefs[Texture].Height, 0, InputFormat, GL_UNSIGNED_BYTE, Data);
end;

procedure TModuleTextureManagerDefault.DeleteTexture(Texture: Integer);
begin
  if (Texture >= 0) and (Texture <= high(fTexRefs)) then
    begin
    if fTexRefs[Texture].Tex = GLUInt(-1) then
      exit;
    BindTexture(-1);
    glDeleteTextures(1, @fTexRefs[Texture].Tex);
    fTexRefs[Texture].Tex := GLUInt(-1);
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

function TModuleTextureManagerDefault.ReadPixel(Texture: Integer; X, Y: Integer): DWord;
var
  FormatLength: Integer;
begin
  FormatLength := 4;
  if (fTexRefs[Texture].InputFormat = GL_RGB) or (fTexRefs[Texture].InputFormat = GL_BGR) then
    FormatLength := 3;
  Result := DWord(Pointer(PtrUInt(@fTexRefs[Texture].Data[FormatLength * (fTexRefs[Texture].Width * Y + X)]))^);
  if FormatLength = 3 then
    Result := Result and $00FFFFFF;
end;

procedure TModuleTextureManagerDefault.SetPixel(Texture: Integer; X, Y: Integer; Color: DWord);
begin
  DWord(Pointer(PtrUInt(@fTexRefs[Texture].Data[4 * (fTexRefs[Texture].Width * Y + X)]))^) := Color;
  FillTexture(Texture, @fTexRefs[Texture].Data[0], GL_BGRA);
end;

function TModuleTextureManagerDefault.GetRealTexID(Tex: Integer): GLUInt;
begin
  Result := fTexRefs[Tex].Tex;
end;

destructor TModuleTextureManagerDefault.Free;
var
  i: integer;
begin
  for i := 0 to high(fTexRefs) do
    DeleteTexture(i);
end;

end.

