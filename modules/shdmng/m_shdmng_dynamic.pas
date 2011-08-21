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
  FSObject, VSObject, GSObject: GLHandle;
  Shaders: TShaderConstellation;
  str: String;
  s: Integer;
  i: integer;
begin
  if VerticesOut > 0 then
    writeln('Loading Shader ' + VSFile + ', ' + FSFile, ', ', GSFile)
  else
    writeln('Loading Shader ' + VSFile + ', ' + FSFile);
  if (not FileExists(VSFile)) or (not FileExists(FSFile)) or ((not FileExists(GSFile)) and (VerticesOut > 0)) then
    begin
    ModuleManager.ModLog.AddWarning('Shader files ' + VSFile + ', ' + FSFile + ', ' + GSFile + ' do not exist');
    exit(-1);
    end;

  for i := 0 to high(fShdRef) do
    if fShdRef[i].Name = VSFile + ':' + FSFile + ':' + GSFile then
      exit(i);

  SetLength(fShdRef, length(fShdRef) + 1);
  Result := high(fShdRef);

  fShdRef[Result].ID := glCreateProgram();
  fShdRef[Result].Uniforms := TDictionary.Create;

  VSObject := glCreateShader(GL_VERTEX_SHADER);
  FSObject := glCreateShader(GL_FRAGMENT_SHADER);
  if VerticesOut > 0 then
    GSObject := glCreateShader(GL_GEOMETRY_SHADER_EXT);

  Shaders := TShaderConstellation.Create(VSFile, FSFile, GSFile);
    fShdRef[Result].Uniforms.Assign(Shaders.VertexShader.Uniforms);
    fShdRef[Result].Uniforms.Assign(Shaders.FragmentShader.Uniforms);
    if VerticesOut > 0 then
      fShdRef[Result].Uniforms.Assign(Shaders.GeometryShader.Uniforms);

    Str := Shaders.VertexShader.ToString; S := Length(Str);
    glShaderSource(VSObject, 1, @Str, @S);
    Str := Shaders.FragmentShader.ToString; S := Length(Str);
    glShaderSource(FSObject, 1, @Str, @S);
    if VerticesOut > 0 then
      begin
      Str := Shaders.GeometryShader.ToString; S := Length(Str);
      glShaderSource(GSObject, 1, @Str, @S);
      end;
  Shaders.Free;

  glCompileShader(VSObject);
  glCompileShader(FSObject);
  if VerticesOut > 0 then
    glCompileShader(GSObject);

  glAttachShader(fShdRef[Result].ID, VSObject);
  glAttachShader(fShdRef[Result].ID, FSObject);
  if VerticesOut > 0 then
    begin
    glAttachShader(fShdRef[Result].ID, GSObject);
    glProgramParameteriEXT(fShdRef[Result].ID, GL_GEOMETRY_VERTICES_OUT_EXT, VerticesOut);
    glProgramParameteriEXT(fShdRef[Result].ID, GL_GEOMETRY_INPUT_TYPE_EXT, InputType);
    glProgramParameteriEXT(fShdRef[Result].ID, GL_GEOMETRY_OUTPUT_TYPE_EXT, OutputType);
    end;
  glLinkProgram(fShdRef[Result].ID);
  if glSlang_getInfoLog(fShdRef[Result].ID) <> '' then
    ModuleManager.ModLog.AddWarning('Shader Info (' + VSFile + ', ' + FSFile + ', ' + GSFile + '):' + #10 + glSlang_getInfoLog(fShdRef[Result].ID));

  fShdRef[Result].Name := VSFile + ':' + FSFile;

  glDeleteShader(VSObject);
  glDeleteShader(FSObject);
  if VerticesOut > 0 then
    glDeleteShader(GSObject);

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

