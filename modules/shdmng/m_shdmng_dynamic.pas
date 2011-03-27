unit m_shdmng_dynamic;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DGLOpenGL, m_shdmng_class, m_shdmng_dynamic_parser, u_functions;

type
  TShdRef = record
    Name: String;
    ID: GLHandle;
    Uniforms: TDictionary;
    end;

  AShdRef = array of TShdRef;

  TModuleShaderManagerDynamic = class(TModuleShaderManagerClass)
    protected
      fShdRef: AShdRef;
      fCurrentShader: Integer;
    public
      constructor Create;
      destructor Free;
      procedure CheckModConf;
      function LoadShader(VSFile, FSFile: String; GSFile: String = ''; VerticesOut: Integer = 0; InputType: GLEnum = GL_TRIANGLES; OutputType: GLEnum = GL_TRIANGLE_STRIP): Integer;
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
      procedure UniformMatrix3D(VName: String; V: Pointer);
      procedure UniformMatrix4D(VName: String; V: Pointer);
    end;

implementation

uses
  m_varlist;

constructor TModuleShaderManagerDynamic.Create;
begin
  fModName := 'ShaderManagerDynamic';
  fModType := 'ShaderManager';

  fCurrentShader := -1;
end;

destructor TModuleShaderManagerDynamic.Free;
var
  i: integer;
begin
  for i := 0 to high(fShdRef) do
    begin
    fShdRef[i].Uniforms.Free;
    DeleteShader(i);
    end;
end;

procedure TModuleShaderManagerDynamic.CheckModConf;
begin
end;

function TModuleShaderManagerDynamic.LoadShader(VSFile, FSFile: String; GSFile: String = ''; VerticesOut: Integer = 0; InputType: GLEnum = GL_TRIANGLES; OutputType: GLEnum = GL_TRIANGLE_STRIP): Integer;
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
  Shaders: TShaderConstellation;
  str: String;
  s: Integer;
  i: integer;
begin
  if GSFile <> '' then
    ModuleManager.ModLog.AddError('Geometry shaders not supported for ' + VSFile + ', ' + FSFile);
  writeln('Loading Shader ' + VSFile + ', ' + FSFile);
  if (not FileExists(VSFile)) or (not FileExists(FSFile)) then
    begin
    ModuleManager.ModLog.AddWarning('Shader files ' + VSFile + ', ' + FSFile + ' do not exist');
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

//   with TFileStream.create(VSFile, fmOpenRead) do
//     begin
//     setlength(str, size);
//     read(str[1], size);
//     s := size;
//     glShaderSource(VSObject, 1, @str, @s);
//     free;
//     end;
// 
//   with TFileStream.create(FSFile, fmOpenRead) do
//     begin
//     setlength(str, size);
//     read(str[1], size);
//     s := size;
//     glShaderSource(FSObject, 1, @str, @s);
//     free;
//     end;

  Shaders := TShaderConstellation.Create(VSFile, FSFile);
  Str := Shaders.VertexShader.ToString; S := Length(Str);
//   writeln(Str);
  glShaderSource(VSObject, 1, @Str, @S);
  Str := Shaders.FragmentShader.ToString; S := Length(Str);
  glShaderSource(FSObject, 1, @Str, @S);
//   writeln(Str);
  Shaders.Free;

  glCompileShader(VSObject);
  glCompileShader(FSObject);

  glAttachShader(fShdRef[Result].ID, VSObject);
  glAttachShader(fShdRef[Result].ID, FSObject);

  glLinkProgram(fShdRef[Result].ID);
  if glSlang_getInfoLog(fShdRef[Result].ID) <> '' then
    ModuleManager.ModLog.AddWarning('Shader Info (' + VSFile + ', ' + FSFile + '):' + #10 + glSlang_getInfoLog(fShdRef[Result].ID));

  fShdRef[Result].Name := VSFile + ':' + FSFile;

  glDeleteShader(VSObject);
  glDeleteShader(FSObject);
end;

procedure TModuleShaderManagerDynamic.BindShader(Shader: Integer);
begin
  if fCurrentShader = Shader then
    exit;
  if (Shader >= 0) and (Shader <= high(fShdRef)) then
    glUseProgram(fShdRef[Shader].ID)
  else
    glUseProgram(0);
  fCurrentShader := Shader;
end;

procedure TModuleShaderManagerDynamic.DeleteShader(Shader: Integer);
begin
  if (Shader >= 0) and (Shader <= high(fShdRef)) then
    begin
    if fShdRef[Shader].Name = '' then
      exit;
    BindShader(-1);
    glDeleteProgram(fShdRef[Shader].ID);
    fShdRef[Shader].Name := '';
    end;
end;

procedure TModuleShaderManagerDynamic.Uniformf(VName: String; v0: GLfloat); inline;
begin
  if (fCurrentShader >= 0) and (fCurrentShader <= high(fShdRef)) then
    glUniform1f(glGetUniformLocation(fShdRef[fCurrentShader].ID, PChar(VName)), V0);
end;

procedure TModuleShaderManagerDynamic.Uniformf(VName: String; v0, v1: GLfloat); inline;
begin
  if (fCurrentShader >= 0) and (fCurrentShader <= high(fShdRef)) then
    glUniform2f(glGetUniformLocation(fShdRef[fCurrentShader].ID, PChar(VName)), V0, v1);
end;

procedure TModuleShaderManagerDynamic.Uniformf(VName: String; v0, v1, v2: GLfloat); inline;
begin
  if (fCurrentShader >= 0) and (fCurrentShader <= high(fShdRef)) then
    glUniform3f(glGetUniformLocation(fShdRef[fCurrentShader].ID, PChar(VName)), V0, v1, v2);
end;

procedure TModuleShaderManagerDynamic.Uniformf(VName: String; v0, v1, v2, v3: GLfloat); inline;
begin
  if (fCurrentShader >= 0) and (fCurrentShader <= high(fShdRef)) then
    glUniform4f(glGetUniformLocation(fShdRef[fCurrentShader].ID, PChar(VName)), V0, v1, v2, v3);
end;

procedure TModuleShaderManagerDynamic.Uniformi(VName: String; v0: GLint); inline;
begin
  if (fCurrentShader >= 0) and (fCurrentShader <= high(fShdRef)) then
    glUniform1i(glGetUniformLocation(fShdRef[fCurrentShader].ID, PChar(VName)), V0);
end;

procedure TModuleShaderManagerDynamic.Uniformi(VName: String; v0, v1: GLint); inline;
begin
  if (fCurrentShader >= 0) and (fCurrentShader <= high(fShdRef)) then
    glUniform2i(glGetUniformLocation(fShdRef[fCurrentShader].ID, PChar(VName)), V0, v1);
end;

procedure TModuleShaderManagerDynamic.Uniformi(VName: String; v0, v1, v2: GLint); inline;
begin
  if (fCurrentShader >= 0) and (fCurrentShader <= high(fShdRef)) then
    glUniform3i(glGetUniformLocation(fShdRef[fCurrentShader].ID, PChar(VName)), V0, v1, v2);
end;

procedure TModuleShaderManagerDynamic.Uniformi(VName: String; v0, v1, v2, v3: GLint); inline;
begin
  if (fCurrentShader >= 0) and (fCurrentShader <= high(fShdRef)) then
    glUniform4i(glGetUniformLocation(fShdRef[fCurrentShader].ID, PChar(VName)), V0, v1, v2, v3);
end;

procedure TModuleShaderManagerDynamic.UniformMatrix4D(VName: String; V: Pointer); inline;
begin
  if (fCurrentShader >= 0) and (fCurrentShader <= high(fShdRef)) then
    glUniformMatrix4fv(glGetUniformLocation(fShdRef[fCurrentShader].ID, PChar(VName)), 1, false, V);
end;

procedure TModuleShaderManagerDynamic.UniformMatrix3D(VName: String; V: Pointer); inline;
begin
  if (fCurrentShader >= 0) and (fCurrentShader <= high(fShdRef)) then
    glUniformMatrix3fv(glGetUniformLocation(fShdRef[fCurrentShader].ID, PChar(VName)), 1, false, V);
end;

end.

