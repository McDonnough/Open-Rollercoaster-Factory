unit m_scriptmng_bytecode_compiler;

interface

uses
  SysUtils, Classes, u_scripts, m_scriptmng_bytecode_classes;

type
  TBytecodeScriptHandle = class
    protected
      fFirstByte: Pointer;
      fByteCode: Array of Byte;
      fFunctionTable: TLocationTable;
      fUniformLocations: TLocationTable;
      fGlobalLocations: TLocationTable;
    public
      Code: TScriptCode;
      property FirstByte: Pointer read fFirstByte;
      property Functions: TLocationTable read fFunctionTable;
      property UniformLocations: TLocationTable read fUniformLocations;
      property GlobalLocations: TLocationTable read fGlobalLocations;
      procedure Compile;
      constructor Create;
      destructor Free;
    end;

implementation

procedure TBytecodeScriptHandle.Compile;
begin
end;

constructor TBytecodeScriptHandle.Create;
begin
  fFunctionTable := TLocationTable.Create;
  fUniformLocations := TLocationTable.Create;
  fGlobalLocations := TLocationTable.Create;
  fFirstByte := nil;
end;

destructor TBytecodeScriptHandle.Free;
begin
  fGlobalLocations.Free;
  fUniformLocations.Free;
  fFunctionTable.Free;
end;

end.