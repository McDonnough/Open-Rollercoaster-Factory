unit m_shdmng_default;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DGLOpenGL, m_shdmng_class;

type
  TShdRef = record
    Name: String;
    ID: GLHandle;
    end;

  AShdRef = array of TShdRef;

  TModuleShaderManagerDefault = class(TModuleShaderManagerClass)
    protected
      fShdRef: AShdRef;
      fCurrentShader: Integer;
    public
      constructor Create;
      destructor Free;
      procedure CheckModConf;
      function LoadShader(VSFile, FSFile: String): Integer;
      procedure BindShader(Shader: Integer);
      procedure DeleteShader(Shader: Integer);
      procedure Uniformf(VName: String; v0: GLfloat);
      procedure Uniformf(VName: String; v0, v1: GLfloat);
      procedure Uniformf(VName: String; v0, v1, v2: GLfloat);
      procedure Uniformf(VName: String; v0, v1, v2, v3: GLfloat);
      procedure Uniformi(VName: String; v0: GLint);
      procedure Uniformi(VName: String; v0, v1: GLint);
      procedure Uniformi(VName: String; v0, v1, v2: GLint);
      procedure Uniformi(VName: String; v0, v1, v2, v3: GLint);
    end;

implementation

uses
  m_varlist;

constructor TModuleShaderManagerDefault.Create;
begin
  fModName := 'ShaderManagerDefault';
  fModType := 'ShaderManager';

  fCurrentShader := -1;
end;

destructor TModuleShaderManagerDefault.Free;
var
  i: integer;
begin
  for i := 0 to high(fShdRef) do
    DeleteShader(i);
end;

procedure TModuleShaderManagerDefault.CheckModConf;
begin
end;

function TModuleShaderManagerDefault.LoadShader(VSFile, FSFile: String): Integer;
  function glSlang_GetInfoLog(glObject: GLHandle): String;
  var
    blen,slen: GLInt;
    InfoLog: PGLCharARB;
  begin
    glGetObjectParameterivARB(glObject, GL_OBJECT_INFO_LOG_LENGTH_ARB , @blen);
    if blen > 1 then
      begin
      GetMem(InfoLog, blen*SizeOf(GLCharARB));
      glGetInfoLogARB(glObject, blen, slen, InfoLog);
      Result := PChar(InfoLog);
      dispose(InfoLog);
      end;
  end;
var
  FSObject, VSObject: GLHandle;
  str: String;
  s: Integer;
  i: integer;
begin
  if (not FileExists(VSFile)) or (not FileExists(VSFile)) then
    begin
    ModuleManager.ModLog.AddWarning('Shader files ' + VSFile + ', ' + FSFile + ' do not exist', 'm_shdmng_default', 87);
    exit(-1);
    end;

  for i := 0 to high(fShdRef) do
    if fShdRef[i].Name = VSFile + ':' + FSFile then
      exit(i);

  SetLength(fShdRef, length(fShdRef) + 1);
  Result := high(fShdRef);

  fShdRef[Result].ID := glCreateProgram();

  VSObject := glCreateShader(GL_VERTEX_SHADER);
  FSObject := glCreateShader(GL_FRAGMENT_SHADER);

  with TFileStream.create(VSFile, fmOpenRead) do
    begin
    setlength(str, size);
    read(str[1], size);
    s := size;
    glShaderSource(VSObject, 1, @str, @s);
    free;
    end;

  with TFileStream.create(FSFile, fmOpenRead) do
    begin
    setlength(str, size);
    read(str[1], size);
    s := size;
    glShaderSource(FSObject, 1, @str, @s);
    free;
    end;

  glCompileShader(VSObject);
  glCompileShader(FSObject);
  glAttachShader(fShdRef[Result].ID, VSObject);
  glAttachShader(fShdRef[Result].ID, FSObject);

  glDeleteShader(VSObject);
  glDeleteShader(FSObject);

  glLinkProgram(fShdRef[Result].ID);
  if glSlang_getInfoLog(fShdRef[Result].ID) <> '' then
    ModuleManager.ModLog.AddWarning('Shader Info (' + VSFile + ', ' + FSFile + '):' + #10 + glSlang_getInfoLog(fShdRef[Result].ID), 'm_shdmng_default.pas', 97);

  fShdRef[Result].Name := VSFile + ':' + FSFile;
end;

procedure TModuleShaderManagerDefault.BindShader(Shader: Integer);
begin
  if fCurrentShader = Shader then
    exit;
  if (Shader >= 0) and (Shader <= high(fShdRef)) then
    glUseProgram(fShdRef[Shader].ID)
  else
    glUseProgram(0);
  fCurrentShader := Shader;
end;

procedure TModuleShaderManagerDefault.DeleteShader(Shader: Integer);
begin
  if (Shader >= 0) and (Shader <= high(fShdRef)) then
    begin
    BindShader(-1);
    glDeleteProgram(fShdRef[Shader].ID);
    fShdRef[Shader].Name := '';
    end;
end;

procedure TModuleShaderManagerDefault.Uniformf(VName: String; v0: GLfloat);
begin
  if (fCurrentShader >= 0) and (fCurrentShader <= high(fShdRef)) then
    glUniform1f(glGetUniformLocationARB(fShdRef[fCurrentShader].ID, PChar(VName)), V0);
end;

procedure TModuleShaderManagerDefault.Uniformf(VName: String; v0, v1: GLfloat);
begin
  if (fCurrentShader >= 0) and (fCurrentShader <= high(fShdRef)) then
    glUniform2f(glGetUniformLocationARB(fShdRef[fCurrentShader].ID, PChar(VName)), V0, v1);
end;

procedure TModuleShaderManagerDefault.Uniformf(VName: String; v0, v1, v2: GLfloat);
begin
  if (fCurrentShader >= 0) and (fCurrentShader <= high(fShdRef)) then
    glUniform3f(glGetUniformLocationARB(fShdRef[fCurrentShader].ID, PChar(VName)), V0, v1, v2);
end;

procedure TModuleShaderManagerDefault.Uniformf(VName: String; v0, v1, v2, v3: GLfloat);
begin
  if (fCurrentShader >= 0) and (fCurrentShader <= high(fShdRef)) then
    glUniform4f(glGetUniformLocationARB(fShdRef[fCurrentShader].ID, PChar(VName)), V0, v1, v2, v3);
end;

procedure TModuleShaderManagerDefault.Uniformi(VName: String; v0: GLint);
begin
  if (fCurrentShader >= 0) and (fCurrentShader <= high(fShdRef)) then
    glUniform1i(glGetUniformLocationARB(fShdRef[fCurrentShader].ID, PChar(VName)), V0);
end;

procedure TModuleShaderManagerDefault.Uniformi(VName: String; v0, v1: GLint);
begin
  if (fCurrentShader >= 0) and (fCurrentShader <= high(fShdRef)) then
    glUniform2i(glGetUniformLocationARB(fShdRef[fCurrentShader].ID, PChar(VName)), V0, v1);
end;

procedure TModuleShaderManagerDefault.Uniformi(VName: String; v0, v1, v2: GLint);
begin
  if (fCurrentShader >= 0) and (fCurrentShader <= high(fShdRef)) then
    glUniform3i(glGetUniformLocationARB(fShdRef[fCurrentShader].ID, PChar(VName)), V0, v1, v2);
end;

procedure TModuleShaderManagerDefault.Uniformi(VName: String; v0, v1, v2, v3: GLint);
begin
  if (fCurrentShader >= 0) and (fCurrentShader <= high(fShdRef)) then
    glUniform4i(glGetUniformLocationARB(fShdRef[fCurrentShader].ID, PChar(VName)), V0, v1, v2, v3);
end;

end.

