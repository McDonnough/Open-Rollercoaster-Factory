unit m_shdmng_class;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_module, DGLOpenGL, u_vectors;

type
  TModuleShaderManagerClass = class(TBasicModule)
    public
      (** Load new shader
        *@param vertex shader file name
        *@param fragment shader file name
        *@return shader ID *)
      function LoadShader(var ProgramHandle: GLUInt; VSFile, FSFile: String; GSFile: String = ''; VerticesOut: Integer = 0; InputType: GLEnum = GL_TRIANGLES; OutputType: GLEnum = GL_TRIANGLE_STRIP): Integer; virtual abstract;

      (** Delete shader
        *@param Shader ID *)
      procedure DeleteShader(Shader: Integer); virtual abstract;

      (** Set custom variable that may affect shaders
        *@param Name of variable
        *@param Value of variable *)
      procedure SetVar(Name: String; Value: Integer); virtual abstract;
    end;

  TShader = class
    protected
      fID: Integer;
      fProgramHandle: GLUInt;
    public
      // Some number that helps identifying the shader
      Tag: Integer;
      
      (** Bind shader *)
      procedure Bind; inline;

      (** Unbind shader *)
      procedure Unbind; inline;

      (** Get uniform location **)
      function GetUniformLocation(VName: String): GLUInt;

      (** Set integer uniform variable
        *@param variable name
        *@param value *)
      procedure UniformI(VName: String; V1: GLInt);
      procedure UniformI(VName: String; V1, V2: GLInt);
      procedure UniformI(VName: String; V1, V2, V3: GLInt);
      procedure UniformI(VName: String; V1, V2, V3, V4: GLInt);
      procedure UniformI(VName: GLUInt; V1: GLInt); inline;
      procedure UniformI(VName: GLUInt; V1, V2: GLInt); inline;
      procedure UniformI(VName: GLUInt; V1, V2, V3: GLInt); inline;
      procedure UniformI(VName: GLUInt; V1, V2, V3, V4: GLInt); inline;

      (** Set float uniform variable
        *@param variable name
        *@param value *)
      procedure UniformF(VName: String; V1: GLFloat);
      procedure UniformF(VName: String; V1, V2: GLFloat);
      procedure UniformF(VName: String; V1, V2, V3: GLFloat);
      procedure UniformF(VName: String; V1, V2, V3, V4: GLFloat);
      procedure UniformF(VName: GLUInt; V1: GLFloat); inline;
      procedure UniformF(VName: GLUInt; V1, V2: GLFloat); inline;
      procedure UniformF(VName: GLUInt; V1, V2, V3: GLFloat); inline;
      procedure UniformF(VName: GLUInt; V1, V2, V3, V4: GLFloat); inline;

      procedure UniformF(VName: String; V: TVector2D);
      procedure UniformF(VName: String; V: TVector3D);
      procedure UniformF(VName: String; V: TVector4D);
      procedure UniformF(VName: GLUInt; V: TVector2D); inline;
      procedure UniformF(VName: GLUInt; V: TVector3D); inline;
      procedure UniformF(VName: GLUInt; V: TVector4D); inline;

      (** Set a matrix uniform variable
        *@param variable name
        *@param Location of the first element of the matrix *)
      procedure UniformMatrix3D(VName: String; V: Pointer);
      procedure UniformMatrix4D(VName: String; V: Pointer);
      procedure UniformMatrix3D(VName: GLUInt; V: Pointer); inline;
      procedure UniformMatrix4D(VName: GLUInt; V: Pointer); inline;

      (** Load a shader from files *)
      constructor Create(VSFile, FSFile: String; GSFile: String = ''; VerticesOut: Integer = 0; InputType: GLEnum = GL_TRIANGLES; OutputType: GLEnum = GL_TRIANGLE_STRIP);

      (** Destroy shader *)
      destructor Free;
    end;

implementation

uses
  m_varlist, u_files;

var
  fCurrentShader: TShader = nil;

procedure TShader.Bind;
begin
  glUseProgram(fProgramHandle);
end;

procedure TShader.Unbind;
begin
  glUseProgram(0);
end;

procedure TShader.UniformI(VName: String; V1: GLInt);
begin
  UniformI(GetUniformLocation(VName), V1);
end;

procedure TShader.UniformI(VName: String; V1, V2: GLInt);
begin
  UniformI(GetUniformLocation(VName), V1, V2);
end;

procedure TShader.UniformI(VName: String; V1, V2, V3: GLInt);
begin
  UniformI(GetUniformLocation(VName), V1, V2, V3);
end;

procedure TShader.UniformI(VName: String; V1, V2, V3, V4: GLInt);
begin
  UniformI(GetUniformLocation(VName), V1, V2, V3, V4);
end;

procedure TShader.UniformF(VName: String; V1: GLFloat);
begin
  UniformF(GetUniformLocation(VName), V1);
end;

procedure TShader.UniformF(VName: String; V1, V2: GLFloat);
begin
  UniformF(GetUniformLocation(VName), V1, V2);
end;

procedure TShader.UniformF(VName: String; V1, V2, V3: GLFloat);
begin
  UniformF(GetUniformLocation(VName), V1, V2, V3);
end;

procedure TShader.UniformF(VName: String; V1, V2, V3, V4: GLFloat);
begin
  UniformF(GetUniformLocation(VName), V1, V2, V3, V4);
end;

procedure TShader.UniformMatrix3D(VName: String; V: Pointer);
begin
  UniformMatrix3D(GetUniformLocation(VName), V);
end;

procedure TShader.UniformMatrix4D(VName: String; V: Pointer);
begin
  UniformMatrix4D(GetUniformLocation(VName), V);
end;

procedure TShader.UniformF(VName: String; V: TVector2D); inline;
begin
  UniformF(VName, V.X, V.Y);
end;

procedure TShader.UniformF(VName: String; V: TVector3D); inline;
begin
  UniformF(VName, V.X, V.Y, V.Z);
end;

procedure TShader.UniformF(VName: String; V: TVector4D); inline;
begin
  UniformF(VName, V.X, V.Y, V.Z, V.W);
end;

procedure TShader.UniformI(VName: GLUInt; V1: GLInt); inline;
begin
  glUniform1i(VName, V1);
end;

procedure TShader.UniformI(VName: GLUInt; V1, V2: GLInt); inline;
begin
  glUniform2i(VName, V1, V2);
end;

procedure TShader.UniformI(VName: GLUInt; V1, V2, V3: GLInt); inline;
begin
  glUniform3i(VName, V1, V2, V3);
end;

procedure TShader.UniformI(VName: GLUInt; V1, V2, V3, V4: GLInt); inline;
begin
  glUniform4i(VName, V1, V2, V3, V4);
end;

procedure TShader.UniformF(VName: GLUInt; V1: GLFloat); inline;
begin
  glUniform1f(VName, V1);
end;

procedure TShader.UniformF(VName: GLUInt; V1, V2: GLFloat); inline;
begin
  glUniform2f(VName, V1, V2);
end;

procedure TShader.UniformF(VName: GLUInt; V1, V2, V3: GLFloat); inline;
begin
  glUniform3f(VName, V1, V2, V3);
end;

procedure TShader.UniformF(VName: GLUInt; V1, V2, V3, V4: GLFloat); inline;
begin
  glUniform4f(VName, V1, V2, V3, V4);
end;

procedure TShader.UniformF(VName: GLUInt; V: TVector2D); inline;
begin
  glUniform2f(VName, V.X, V.Y);
end;

procedure TShader.UniformF(VName: GLUInt; V: TVector3D); inline;
begin
  glUniform3f(VName, V.X, V.Y, V.Z);
end;

procedure TShader.UniformF(VName: GLUInt; V: TVector4D); inline;
begin
  glUniform4f(VName, V.X, V.Y, V.Z, V.W);
end;

procedure TShader.UniformMatrix3D(VName: GLUInt; V: Pointer); inline;
begin
  glUniformMatrix3fv(VName, 1, False, V);
end;

procedure TShader.UniformMatrix4D(VName: GLUInt; V: Pointer); inline;
begin
  glUniformMatrix4fv(VName, 1, False, V);
end;

function TShader.GetUniformLocation(VName: String): GLUInt;
begin
  Result := glGetUniformLocation(fProgramHandle, PChar(VName));
end;

constructor TShader.Create(VSFile, FSFile: String; GSFile: String = ''; VerticesOut: Integer = 0; InputType: GLEnum = GL_TRIANGLES; OutputType: GLEnum = GL_TRIANGLE_STRIP);
begin
  Tag := 0;
  VSFile := GetFirstExistingFilename(VSFile);
  FSFile := GetFirstExistingFilename(FSFile);
  if GSFile <> '' then
    GSFile := GetFirstExistingFilename(GSFile);
  fID := ModuleManager.ModShdMng.LoadShader(fProgramHandle, ModuleManager.ModPathes.Convert(VSFile), ModuleManager.ModPathes.Convert(FSFile), ModuleManager.ModPathes.Convert(GSFile), VerticesOut, InputType, OutputType);
  Bind;
end;

destructor TShader.Free;
begin
  ModuleManager.ModShdMng.DeleteShader(fID);
end;

end.

