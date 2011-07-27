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
      fVars: TDictionary;
    public
      property Vars: TDictionary read fVars;
      constructor Create;
      destructor Free;
      procedure CheckModConf;
      function LoadShader(var ProgramHandle: GLUInt; VSFile, FSFile: String; GSFile: String = ''; VerticesOut: Integer = 0; InputType: GLEnum = GL_TRIANGLES; OutputType: GLEnum = GL_TRIANGLE_STRIP): Integer;
      procedure DeleteShader(Shader: Integer);
      procedure SetVar(Name: String; Value: Integer);
    end;

implementation

uses
  m_varlist;

constructor TModuleShaderManagerDynamic.Create;
begin
  fModName := 'ShaderManagerDynamic';
  fModType := 'ShaderManager';

  fCurrentShader := -1;

  fVars := TDictionary.Create;
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
  fVars.Free;
end;

procedure TModuleShaderManagerDynamic.SetVar(Name: String; Value: Integer);
begin
  fVars[Name] := IntToStr(Value);
end;

procedure TModuleShaderManagerDynamic.CheckModConf;
begin
end;

function TModuleShaderManagerDynamic.LoadShader(var ProgramHandle: GLUInt; VSFile, FSFile: String; GSFile: String = ''; VerticesOut: Integer = 0; InputType: GLEnum = GL_TRIANGLES; OutputType: GLEnum = GL_TRIANGLE_STRIP): Integer;
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
  fShdRef[Result].Uniforms := TDictionary.Create;

  VSObject := glCreateShader(GL_VERTEX_SHADER);
  FSObject := glCreateShader(GL_FRAGMENT_SHADER);

  Shaders := TShaderConstellation.Create(VSFile, FSFile);
    fShdRef[Result].Uniforms.Assign(Shaders.VertexShader.Uniforms);
    fShdRef[Result].Uniforms.Assign(Shaders.FragmentShader.Uniforms);

    Str := Shaders.VertexShader.ToString; S := Length(Str);
//     writeln(Str);
    glShaderSource(VSObject, 1, @Str, @S);
    Str := Shaders.FragmentShader.ToString; S := Length(Str);
    glShaderSource(FSObject, 1, @Str, @S);
//     writeln(Str);
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

  ProgramHandle := fShdRef[Result].ID;
end;

procedure TModuleShaderManagerDynamic.DeleteShader(Shader: Integer);
begin
  if (Shader >= 0) and (Shader <= high(fShdRef)) then
    begin
    if fShdRef[Shader].Name = '' then
      exit;
    glUseProgram(0);
    glDeleteProgram(fShdRef[Shader].ID);
    fShdRef[Shader].Name := '';
    end;
end;

end.

