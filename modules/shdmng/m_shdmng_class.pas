unit m_shdmng_class;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_module, DGLOpenGL;

type
  TModuleShaderManagerClass = class(TBasicModule)
    public
      (**
        * Load new shader
        *@param vertex shader file name
        *@param fragment shader file name
        *@return shader ID
        *)
      function LoadShader(VSFile, FSFile: String; GSFile: String = ''; VerticesOut: Integer = 0): Integer; virtual abstract;

      (**
        * Bind shader
        *@param Shader ID or -1 for no shader
        *)
      procedure BindShader(Shader: Integer); virtual abstract;

      (**
        * Delete shader
        *@param Shader ID
        *)
      procedure DeleteShader(Shader: Integer); virtual abstract;


      (**
        * Send uniform values to shader
        *@param Name of variable
        *@param The values to send
        *)
      procedure Uniformf(VName: String; v0: GLfloat); virtual abstract;
      procedure Uniformf(VName: String; v0, v1: GLfloat); virtual abstract;
      procedure Uniformf(VName: String; v0, v1, v2: GLfloat); virtual abstract;
      procedure Uniformf(VName: String; v0, v1, v2, v3: GLfloat); virtual abstract;
      procedure Uniformi(VName: String; v0: GLint); virtual abstract;
      procedure Uniformi(VName: String; v0, v1: GLint); virtual abstract;
      procedure Uniformi(VName: String; v0, v1, v2: GLint); virtual abstract;
      procedure Uniformi(VName: String; v0, v1, v2, v3: GLint); virtual abstract;
      procedure UniformMatrix3D(VName: String; V: Pointer); virtual abstract;
      procedure UniformMatrix4D(VName: String; V: Pointer); virtual abstract;
    end;

  TShader = class
    protected
      fID: Integer;
    public
      (**
        * Bind shader
        *)
      procedure Bind;

      (**
        * Unbind shader
        *)
      procedure Unbind;

      (**
        * Set integer uniform variable
        *@param variable name
        *@param value
        *)
      procedure UniformI(VName: String; V1: GLInt);
      procedure UniformI(VName: String; V1, V2: GLInt);
      procedure UniformI(VName: String; V1, V2, V3: GLInt);
      procedure UniformI(VName: String; V1, V2, V3, V4: GLInt);

      (**
        * Set float uniform variable
        *@param variable name
        *@param value
        *)
      procedure UniformF(VName: String; V1: GLFloat);
      procedure UniformF(VName: String; V1, V2: GLFloat);
      procedure UniformF(VName: String; V1, V2, V3: GLFloat);
      procedure UniformF(VName: String; V1, V2, V3, V4: GLFloat);

      (**
        * Set a matrix uniform variable
        *@param variable name
        *@param Location of the first element of the matrix
        *)
      procedure UniformMatrix3D(VName: String; V: Pointer);
      procedure UniformMatrix4D(VName: String; V: Pointer);

      (**
        * Load a shader from files
        *)
      constructor Create(VSFile, FSFile: String; GSFile: String = ''; VerticesOut: Integer = 0);

      (**
        * Destroy shader
        *)
      destructor Free;
    end;

implementation

uses
  m_varlist, u_files;

procedure TShader.Bind;
begin
  ModuleManager.ModShdMng.BindShader(fID);
end;

procedure TShader.Unbind;
begin
  ModuleManager.ModShdMng.BindShader(-1);
end;

procedure TShader.UniformI(VName: String; V1: GLInt);
begin
  Bind;
  ModuleManager.ModShdMng.Uniformi(VName, V1);
end;

procedure TShader.UniformI(VName: String; V1, V2: GLInt);
begin
  Bind;
  ModuleManager.ModShdMng.Uniformi(VName, V1, V2);
end;

procedure TShader.UniformI(VName: String; V1, V2, V3: GLInt);
begin
  Bind;
  ModuleManager.ModShdMng.Uniformi(VName, V1, V2, V3);
end;

procedure TShader.UniformI(VName: String; V1, V2, V3, V4: GLInt);
begin
  Bind;
  ModuleManager.ModShdMng.Uniformi(VName, V1, V2, V3, V4);
end;

procedure TShader.UniformF(VName: String; V1: GLFloat);
begin
  Bind;
  ModuleManager.ModShdMng.Uniformf(VName, V1);
end;

procedure TShader.UniformF(VName: String; V1, V2: GLFloat);
begin
  Bind;
  ModuleManager.ModShdMng.Uniformf(VName, V1, V2);
end;

procedure TShader.UniformF(VName: String; V1, V2, V3: GLFloat);
begin
  Bind;
  ModuleManager.ModShdMng.Uniformf(VName, V1, V2, V3);
end;

procedure TShader.UniformF(VName: String; V1, V2, V3, V4: GLFloat);
begin
  Bind;
  ModuleManager.ModShdMng.Uniformf(VName, V1, V2, V3, V4);
end;

procedure TShader.UniformMatrix3D(VName: String; V: Pointer);
begin
  Bind;
  ModuleManager.ModShdMng.UniformMatrix3D(VName, V);
end;

procedure TShader.UniformMatrix4D(VName: String; V: Pointer);
begin
  Bind;
  ModuleManager.ModShdMng.UniformMatrix4D(VName, V);
end;

constructor TShader.Create(VSFile, FSFile: String; GSFile: String = ''; VerticesOut: Integer = 0);
begin
  VSFile := GetFirstExistingFilename(VSFile);
  FSFile := GetFirstExistingFilename(FSFile);
  if GSFile <> '' then
    GSFile := GetFirstExistingFilename(GSFile);
  fID := ModuleManager.ModShdMng.LoadShader(ModuleManager.ModPathes.Convert(VSFile), ModuleManager.ModPathes.Convert(FSFile), ModuleManager.ModPathes.Convert(GSFile), VerticesOut)
end;

destructor TShader.Free;
begin
  ModuleManager.ModShdMng.DeleteShader(fID);
end;

end.

